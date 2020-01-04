#!perl -wT

use strict;
use warnings;
use Test::Most tests => 159;
use Storable;
use Capture::Tiny ':all';
use CGI::Info;
use CGI::Lingua;
use Test::NoWarnings;
use Directory::Scratch;
use autodie qw(:all);
use HTTP::Response;
use HTTP::Headers;
use Cwd;
use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('FCGI::Buffer');
}

CACHED: {
	delete $ENV{'REMOTE_ADDR'};
	delete $ENV{'HTTP_USER_AGENT'};

	SKIP: {
		eval {
			require CHI;

			CHI->import();
		};

		if($@) {
			diag('CHI required to test caching');
			skip('CHI not installed', 157);
		} else {
			diag("Using CHI $CHI::VERSION");
		}

		my $cache = CHI->new(driver => 'Memory', datastore => {});

		delete $ENV{'HTTP_ACCEPT_ENCODING'};
		delete $ENV{'HTTP_TE'};
		delete $ENV{'SERVER_PROTOCOL'};
		delete $ENV{'HTTP_RANGE'};

		sub test1 {
			my $b = new_ok('FCGI::Buffer');

			ok($b->is_cached() == 0);
			ok($b->can_cache() == 1);

			$b->init({ optimise_content => 1, generate_etag => 0, cache => $cache, cache_key => 'test1' });

			print "Content-type: text/html; charset=ISO-8859-1\n\n";
		}

		my ($stdout, $stderr) = capture { test1() };

		my ($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

		ok(length($body) == 0);
		ok($headers =~ /Content-type: text\/html; charset=ISO-8859-1/m);
		ok($stderr eq '');

		$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
		$ENV{'REQUEST_METHOD'} = 'GET';
		$ENV{'QUERY_STRING'} = 'FCGI::Buffer=testing';

		sub test2 {
			my $b = new_ok('FCGI::Buffer');

			ok($b->is_cached() == 0);
			ok($b->can_cache() == 1);

			$b->init({
				optimise_content => 1,
				generate_etag => 0,
				cache => $cache,
				cache_key => 'test2',
				info => new_ok('CGI::Info')
			});

			print "Content-type: text/html; charset=ISO-8859-1\n\n";
		}

		($stdout, $stderr) = capture { test2() };

		($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

		ok(length($body) == 0);
		ok($headers =~ /Content-type: text\/html; charset=ISO-8859-1/m);
		ok($stderr eq '');

		$ENV{'SERVER_PROTOCOL'} = 'HTTP/1.1';

		sub test3 {
			my $b = new_ok('FCGI::Buffer');

			$b->init({
				cache => $cache,
				cache_key => 'test3',
				info => new_ok('CGI::Info')
			});

			ok($b->is_cached() == 0);
			ok($b->can_cache() == 1);

			print "Content-type: text/html; charset=ISO-8859-1\n\n",
				"<HTML><HEAD></HEAD><BODY>Hello, World</BODY></HTML>\n";
		}

		($stdout, $stderr) = capture { test3() };
		is($stderr, '', 'nothing on STDERR');

		($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

		ok($headers =~ /Content-type: text\/html; charset=ISO-8859-1/mi);
		ok($headers !~ /^Content-Encoding: gzip/m);
		ok($headers =~ /^ETag:\s+(.+)/m);
		my $etag = $1;
		ok(defined($etag));
		$etag =~ s/\r//;

		$ENV{'HTTP_IF_NONE_MATCH'} = $etag;
		sub test3a {
			my $b = new_ok('FCGI::Buffer');

			$b->init({
				cache => $cache,
				cache_key => 'test3',
				info => new_ok('CGI::Info')
			});

			ok($b->can_cache() == 1);

			print "Content-type: text/html; charset=ISO-8859-1\n\n";

			print "<HTML><HEAD></HEAD><BODY>Hello, World</BODY></HTML>\n";

			ok($b->is_cached() == 1);
		}

		($stdout, $stderr) = capture { test3a() };
		ok($stderr eq '');

		($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

		ok($headers =~ /^Status: 304 Not Modified/mi);
		ok($headers =~ /Content-type: text\/html; charset=ISO-8859-1/mi);
		ok($headers !~ /^Content-Encoding: gzip/m);
		ok($headers =~ /^ETag:\s+(.+)/m);
		ok($1 eq $etag);

		# ---- gzip in the cache ------
		sub test4 {
			my $b = new_ok('FCGI::Buffer');

			$b->init({
				cache => $cache,
				cache_key => 'test4',
				info => new_ok('CGI::Info')
			});

			ok($b->is_cached() == 0);
			ok($b->can_cache() == 1);

			print "Content-type: text/html; charset=ISO-8859-1\n\n";

			print "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN>\n",
				"<HTML><HEAD><TITLE>Hello, world</TITLE></HEAD><BODY><P>The quick brown fox jumped over the lazy dog.</P></BODY></HTML>\n";
		}

		delete $ENV{'HTTP_IF_NONE_MATCH'};
		$ENV{'HTTP_ACCEPT_ENCODING'} = 'gzip';
		($stdout, $stderr) = capture { test4() };
		ok($stderr eq '');

		($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

		ok($headers =~ /Content-type: text\/html; charset=ISO-8859-1/mi);
		ok($headers =~ /^Content-Encoding: gzip/m);
		ok($headers =~ /^ETag:\s+(.+)/m);
		$etag = $1;
		ok(defined($etag));
		$etag =~ s/\r//;

		ok(Compress::Zlib::memGunzip($body) =~ /<HTML><HEAD><TITLE>Hello, world<\/TITLE><\/HEAD><BODY><P>The quick brown fox jumped over the lazy dog.<\/P><\/BODY><\/HTML>/m);

		$ENV{'HTTP_IF_NONE_MATCH'} = $etag;
		$ENV{'SCRIPT_FILENAME'} = Cwd::abs_path($0);
		sub test4a {
			my $b = new_ok('FCGI::Buffer');

			$b->init({
				cache => $cache,
				cache_key => 'test4',
				info => new_ok('CGI::Info'),
				logger => MyLogger->new()
			});

			ok($b->can_cache() == 1);

			print "Content-type: text/html; charset=ISO-8859-1\n\n";

			print "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN>\n",
				"<HTML><HEAD><TITLE>Hello, world</TITLE></HEAD><BODY><P>The quick brown fox jumped over the lazy dog.</P></BODY></HTML>\n";

			ok($b->is_cached() == 1);
		}

		($stdout, $stderr) = capture { test4a() };
		ok($stderr eq '');

		($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

		ok($headers =~ /^Status: 304 Not Modified/mi);
		ok($headers =~ /Content-type: text\/html; charset=ISO-8859-1/mi);
		ok($headers =~ /^ETag:\s+(.+)/m);
		ok($1 eq $etag);

		# Among other things, save_to will be to here
		my $tempdir = Directory::Scratch->new()->mkdir('cache.t');
		ok(-d $tempdir);
		ok(-w $tempdir);
		$ENV{'DOCUMENT_ROOT'} = $tempdir;

		delete $ENV{'LANGUAGE'};
		delete $ENV{'LC_ALL'};
		delete $ENV{'LC_MESSAGES'};
		delete $ENV{'LANG'};
		if($^O eq 'MSWin32') {
			$ENV{'IGNORE_WIN32_LOCALE'} = 1;
		}
		$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-gb,en;q=0.5';
		my $save_to = {
			directory => $tempdir,
			ttl => 3600,
			create_table => 1,
		};

		# Check if static links have been put in
		delete $ENV{'HTTP_IF_NONE_MATCH'};
		$ENV{'REQUEST_URI'} = '/cgi-bin/test4.cgi?arg1=a&arg2=b';
		$ENV{'SCRIPT_NAME'} = '/cgi-bin/test4.cgi';
		$ENV{'QUERY_STRING'} = 'arg1=a&arg2=b';
		delete $ENV{'HTTP_ACCEPT_ENCODING'};

		($stdout, $stderr) = capture { test4a() };
		ok($stderr eq '');

		($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

		ok($headers =~ /Content-type: text\/html; charset=ISO-8859-1/mi);

		sub test5 {
			my $b = new_ok('FCGI::Buffer');
			my $info = new_ok('CGI::Info');

			$b->init({
				cache => $cache,
				info => $info,
				lingua => new_ok('CGI::Lingua' => [
					supported => ['en'],
					dont_use_ip => 1,
					info => $info,
				]),
				save_to => $save_to
			});

			ok($b->can_cache() == 1);

			print "Content-type: text/html; charset=ISO-8859-1\n\n",
				"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN>\n",
				'<HTML><HEAD><TITLE>test5</TITLE></HEAD>',
				'<BODY><P>The quick brown fox jumped over the lazy dog.</P>',
				'<A HREF="/cgi-bin/test4.cgi?arg1=a&arg2=b">link</a>',
				"</BODY></HTML>\n";
		}

		($stdout, $stderr) = capture { test5() };

		diag($stderr) if($stderr ne '');
		ok($stderr eq '');

		($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
		ok(defined($headers));
		ok(defined($body));

		like($headers, qr/Content-type: text\/html; charset=ISO-8859-1/mi, 'HTML output');
		like($headers, qr/^ETag:\s+.+/m, 'ETag header is present');
		like($headers, qr/^Expires: /m, 'Expires header is present');

		like($body, qr/\/cgi-bin\/test4.cgi/m, 'Nothing to optimise on first pass');
		ok($headers =~ /^Content-Length:\s+(\d+)/m);
		my $length = $1;
		ok(defined($length));
		ok(length($body) eq $length);

		($stdout, $stderr) = capture { test5() };
		ok($stderr eq '');

		($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

		ok($headers =~ /Content-type: text\/html; charset=ISO-8859-1/mi);
		ok($headers =~ /^ETag:\s+.+/m);
		ok($headers =~ /^Expires: /m);

		if($^O eq 'MSWin32') {
			ok($body =~ /\\web\\English\\test4.cgi\\.+\.html"/m);
		} else {
			ok($body =~ /"\/web\/English\/test4.cgi\/.+\.html"/m);
		}

		$ENV{'SCRIPT_NAME'} = '/cgi-bin/test5.cgi';
		$ENV{'REQUEST_URI'} = '/cgi-bin/test5.cgi?fred=wilma';
		($stdout, $stderr) = capture { test5() };
		ok($stderr eq '');

		($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

		ok($headers =~ /Content-type: text\/html; charset=ISO-8859-1/mi);
		ok($headers =~ /^ETag:\s+.+/m);
		ok($headers =~ /^Expires: /m);

		if($^O eq 'MSWin32') {
			ok($body =~ /\\web\\English\\test4.cgi\\.+\.html"/m);
		} else {
			ok($body =~ /"\/web\/English\/test4.cgi\/.+\.html"/m);
		}

		ok(-f "$tempdir/web/English/test5.cgi/arg1=a_arg2=b.html");
		open(my $fin, '<', "$tempdir/web/English/test5.cgi/arg1=a_arg2=b.html");
		my $html_file;
		while(<$fin>) {
			$html_file .= $_;
		}
		close($fin);

		ok($html_file =~ /<A HREF="\/cgi-bin\/test4.cgi\?arg1=a&arg2=b">link<\/a>/mi);

		# no cache argument to init()
		sub test5a {
			my $b = new_ok('FCGI::Buffer');

			$b->init({
				info => new_ok('CGI::Info'),
				lingua => CGI::Lingua->new(
					supported => ['en'],
					dont_use_ip => 1,
				),
				save_to => $save_to
			});

			ok($b->can_cache() == 1);

			print "Content-type: text/html; charset=ISO-8859-1\n\n",
				"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN>\n",
				"<HTML><HEAD><TITLE>Hello, world</TITLE></HEAD>",
				"<BODY><P>The quick brown fox jumped over the lazy dog.</P>",
				'<A HREF="/cgi-bin/test4.cgi?arg1=a&arg2=b">link</a>',
				"</BODY></HTML>\n";
		}

		($stdout, $stderr) = capture { test5a() };
		ok($stderr eq '');

		($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

		ok($headers =~ /Content-type: text\/html; charset=ISO-8859-1/mi);
		ok($headers =~ /^ETag:\s+.+/m);
		ok($headers =~ /^Expires: /m);

		if($^O eq 'MSWin32') {
			ok($body =~ /\\web\\English\\test4.cgi\\.+\.html"/m);
		} else {
			ok($body =~ /"\/web\/English\/test4.cgi\/.+\.html"/m);
		}
		ok($body !~ /"\?arg1=a/m);

		ok($headers =~ /^Content-Length:\s+(\d+)/m);
		$length = $1;
		ok(defined($length));
		ok(length($body) eq $length);

		# Calling self
		$ENV{'SCRIPT_NAME'} = '/cgi-bin/test4.cgi';
		$ENV{'REQUEST_URI'} = '/cgi-bin/test4.cgi?arg3=c';
		sub test5b {
			my $b = new_ok('FCGI::Buffer');
			my $info = new_ok('CGI::Info');

			$b->init({
				info => $info,
				lingua => CGI::Lingua->new(
					supported => ['en'],
					dont_use_ip => 1,
					info => $info,
				),
				save_to => $save_to,
				logger => MyLogger->new()
			});

			ok($b->can_cache() == 1);

			print "Content-type: text/html; charset=ISO-8859-1\n\n";

			print "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN>\n",
				"<HTML><HEAD><TITLE>Hello, world</TITLE></HEAD>",
				"<BODY><P>The quick brown fox jumped over the lazy dog.</P>",
				'<A HREF="?arg1=a&arg2=b">link</a>',
				'<A HREF="?arg1=a&arg2=b">link</a>',
				"</BODY></HTML>\n";
		}

		($stdout, $stderr) = capture { test5b() };
		ok($stderr eq '');

		($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

		ok($headers =~ /Content-type: text\/html; charset=ISO-8859-1/mi);
		ok($headers =~ /^ETag:\s+.+/m);
		ok($headers =~ /^Expires: /m);
		ok($headers !~ /^Content-Encoding: gzip/m);

		if($^O eq 'MSWin32') {
			ok($body =~ /\\web\\English\\test4.cgi\\.+\.html"/m);
		} else {
			ok($body =~ /"\/web\/English\/test4.cgi\/.+\.html"/m);
		}
		ok($body !~ /"\?arg1=a/m);

		ok($headers =~ /^Content-Length:\s+(\d+)/m);
		$length = $1;
		ok(defined($length));
		ok(length($body) eq $length);

		# Check zipping returns save_to correctly
		$ENV{'HTTP_ACCEPT_ENCODING'} = 'gzip';
		($stdout, $stderr) = capture { test5b() };
		ok($stderr eq '');

		($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

		ok($headers =~ /Content-type: text\/html; charset=ISO-8859-1/mi);
		ok($headers =~ /^ETag:\s+.+/m);
		ok($headers =~ /^Expires: /m);
		like($headers, qr/^Content-Encoding:\sgzip\r?$/m, 'Contains content-encoding gzip header');

		ok($headers =~ /^Content-Length:\s+(\d+)/m);
		$length = $1;
		ok(defined($length));
		ok(length($body) eq $length);

		my $h = HTTP::Headers->new();
		foreach my $header(split(/\r?\n/, $headers)) {
			my ($key, $value) = split(/:\s?/, $header, 2);
			$h->header($key => $value);
		}
		my $r = HTTP::Response->new(200, 'OK', $h, $body);
		ok($h->content_encoding() eq 'gzip');

		$body = $r->decoded_content();
		if($^O eq 'MSWin32') {
			ok($body =~ /\\web\\English\\test4.cgi\\.+\.html"/m);
		} else {
			ok($body =~ /"\/web\/English\/test4.cgi\/.+\.html"/m);
		}
		ok($body !~ /"\?arg1=a/m);

		$ENV{'REQUEST_METHOD'} = 'HEAD';
		$ENV{'HTTP_ACCEPT_ENCODING'} = 'gzip';
		($stdout, $stderr) = capture { test5b() };
		ok($stderr eq '');

		($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

		ok($headers =~ /Content-type: text\/html; charset=ISO-8859-1/mi);
		ok($headers =~ /^ETag:\s+.+/m);
		ok($headers =~ /^Expires: /m);
		like($headers, qr/^Content-Encoding:\sgzip\r?$/m, 'Contains content-encoding gzip header');

		ok($body eq '');

		ok(-r "$tempdir/fcgi.buffer.sql");
		ok(-d "$tempdir/web/English/test4.cgi");
		ok(-d "$tempdir/web/English/test5.cgi");

		# ...............................
		$ENV{'SCRIPT_NAME'} = '/cgi-bin/test6.cgi';
		$ENV{'REQUEST_URI'} = '/cgi-bin/test6.cgi?foo=bar';
		$ENV{'REQUEST_METHOD'} = 'GET';
		delete $ENV{'HTTP_ACCEPT_ENCODING'};

		sub test6 {
			my $b = new_ok('FCGI::Buffer');
			my $info = new_ok('CGI::Info');

			$save_to->{'ttl'} = 0;
			$b->init({
				info => $info,
				cache => $cache,
				lingua => CGI::Lingua->new(
					supported => ['en'],
					dont_use_ip => 1,
					info => $info,
				),
				save_to => $save_to,
				logger => MyLogger->new(),
				optimise_content => 1,
			});

			ok($b->can_cache() == 1);

			print "Content-type: text/html; charset=ISO-8859-1\n\n";

			print "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN>\n",
				"<HTML><HEAD><TITLE>test6</TITLE></HEAD>",
				"<BODY>",
				'<A HREF="/cgi-bin/test6.cgi?arg2=b">link</a>',
				'<A HREF="http://github.com/nigelhorne/FCGI-Buffer">link2</a>',
				'<A HREF="/cgi-bin/test4.cgi?arg3=c">link3</a>',
				'<A HREF="/cgi-bin/test4.cgi?arg1=a&arg2=b">link4</a>',
				"</BODY></HTML>\n";
		}

		($stdout, $stderr) = capture { test6() };
		ok($stderr eq '');

		($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

		ok($body =~ /<a href="\?arg2=b">link<\/a>/mi);
		ok($body =~ /<a href=\"\/\/github.com\/nigelhorne/mi);
		ok($body =~ /<a href=\"\/cgi-bin\/test4.cgi\?arg3=c">/mi);
		if($^O eq 'MSWin32') {
			ok($body =~ /\\web\\English\\test4.cgi\\arg1=a_arg2=b\.html"/m);
		} else {
			ok($body =~ /"\/web\/English\/test4.cgi\/arg1=a_arg2=b\.html"/m);
		}

		ok(-f "$tempdir/web/English/test6.cgi/arg1=a_arg2=b.html");
		open($fin, '<', "$tempdir/web/English/test6.cgi/arg1=a_arg2=b.html");
		$html_file = undef;
		while(<$fin>) {
			$html_file .= $_;
		}
		close($fin);
		# ok($html_file =~ /<A HREF="\/cgi-bin\/test4.cgi\?arg1=a&arg2=b">link<\/a>/mi);

		ok($html_file =~ /<a href="\/cgi-bin\/test6.cgi\?arg2=b">link<\/a>/mi);
		ok($html_file =~ /<a href=\"\/\/github.com\/nigelhorne/mi);
		ok($html_file =~ /<a href=\"\/cgi-bin\/test4.cgi\?arg3=c">/mi);
		ok($html_file =~ /"\/cgi-bin\/test4.cgi\?arg1=a&arg2=b">/mi);


	}
}
