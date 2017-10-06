#!perl -wT

# Test if FCGI::Buffer adds Content-Length and Etag headers, also simple
# check that optimise_content does something.

# TODO: check optimise_content and gzips do the *right* thing
# TODO: check ETags are correct
# TODO: Write a test to check that 304 is sent when a cached object
#	is newer than the IF_MODIFIED_SINCE date

use strict;
use warnings;

use Test::Most tests => 271;
use IO::Uncompress::Brotli;
use DateTime;
use Capture::Tiny ':all';
use CGI::Info;
use Digest::MD5;
use Test::HTML::Lint;
# use Test::NoWarnings;	# HTML::Clean has them

BEGIN {
	use_ok('FCGI::Buffer');
}

OUTPUT: {
	delete $ENV{'HTTP_ACCEPT_ENCODING'};
	delete $ENV{'HTTP_TE'};
	delete $ENV{'SERVER_PROTOCOL'};
	delete $ENV{'HTTP_RANGE'};

	$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
	$ENV{'REQUEST_METHOD'} = 'GET';
	$ENV{'QUERY_STRING'} = 'FCGI::Buffer=testing';

	sub test1 {
		my $b = new_ok('FCGI::Buffer');

		ok($b->can_cache() == 1);
		ok($b->is_cached() == 0);

		print "Content-type: text/html; charset=ISO-8859-1\n\n",
			"<HTML><BODY>   Hello, world</BODY></HTML>\n";

		ok($b->is_cached() == 0);
	}

	my ($stdout, $stderr) = capture { test1() };

	ok($stderr eq '');
	ok($stdout !~ /^ETag: "/m);
	ok($stdout !~ /^Content-Encoding: gzip/m);

	my ($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	my $length = $1;
	ok(defined($length));

	ok($body eq "<HTML><BODY>   Hello, world</BODY></HTML>\n");
	ok(length($body) eq $length);

	sub test2 {
		my $b = new_ok('FCGI::Buffer');

		ok($b->can_cache() == 1);
		ok($b->is_cached() == 0);

		$b->init(optimise_content => 1);

		print "Content-type: text/html; charset=ISO-8859-1\n\n";
		print "<HTML>\n<BODY>\n\t    Hello, world\n  </BODY>\n</HTML>\n";
	}

	($stdout, $stderr) = capture { test2() };

	ok($stderr eq '');
	if($stderr ne '') {
		diag($stderr);
	}
	ok($stdout =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));
	# Extra spaces should have been removed
	ok($stdout =~ /<HTML><BODY>Hello, world<\/BODY><\/HTML>/mi);
	ok($stdout !~ /^Content-Encoding: gzip/m);
	ok($stdout !~ /^ETag: "/m);

	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
	ok(defined($headers));
	ok(defined($body));
	ok(length($body) eq $length);

	$ENV{'HTTP_ACCEPT_ENCODING'} = 'gzip, deflate, sdch, br';

	sub test3 {
		my $b = new_ok('FCGI::Buffer');

		ok($b->can_cache() == 1);
		ok($b->is_cached() == 0);

		print "Content-type: text/html; charset=ISO-8859-1\n\n";
		print "<HTML><HEAD>Test</HEAD><BODY><P>Hello, world></BODY></HTML>\n";
	}

	($stdout, $stderr) = capture { test3() };

	ok($stderr eq '');
	ok($stdout =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));
	# It's not gzipped, because it's so small the gzip version would be
	# bigger
	ok($stdout =~ /<HTML><HEAD>Test<\/HEAD><BODY><P>Hello, world><\/BODY><\/HTML>/m);
	ok($stdout !~ /^Content-Encoding: gzip/m);
	ok($stdout !~ /^ETag: "/m);

	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
	ok(length($body) eq $length);

	$ENV{'SERVER_PROTOCOL'} = 'HTTP/1.1';
	delete($ENV{'HTTP_ACCEPT_ENCODING'});
	$ENV{'HTTP_TE'} = 'br,gzip';

	sub test4 {
		my $b = new_ok('FCGI::Buffer');

		$b->init(optimise_content => 0);

		print "Content-type: text/html; charset=ISO-8859-1\n\n";
		# Put in a large body so that it gzips - small bodies won't
		print "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\n";
		print "<HTML><HEAD><TITLE>Hello, world</TITLE></HEAD><BODY><P>The quick brown fox jumped over the lazy dog.</P></BODY></HTML>\n";
	}

	($stdout, $stderr) = capture { test4() };

	if($stderr ne '') {
		diag($stderr);
	}
	ok($stderr eq '');
	ok($stdout =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));

	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
	ok($headers =~ /^Content-Encoding: br/m);
	ok($headers =~ /ETag: "[A-Za-z0-F0-f]{32}"/m);

	ok(defined($body));
	ok(length($body) eq $length);
	$body = unbro($body, 1024);
	ok(defined($body));
	ok($body =~ /<HTML><HEAD><TITLE>Hello, world<\/TITLE><\/HEAD><BODY><P>The quick brown fox jumped over the lazy dog.<\/P><\/BODY><\/HTML>\n$/);
	html_ok($body, 'HTML:Lint shows no errors');

	#..........................................
	delete $ENV{'SERVER_PROTOCOL'};
	delete $ENV{'HTTP_TE'};

	$ENV{'SERVER_NAME'} = 'www.example.com';

	sub test5 {
		my $b = new_ok('FCGI::Buffer');

		$b->init(optimise_content => 1, compress_content => 0);

		print "Content-type: text/html; charset=ISO-8859-1\n\n";
		print "<HTML><HEAD><TITLE>\ntest five</TITLE></HEAD><BODY><A HREF=\"http://www.example.com\">Click</A>\n<script>\nalert(foo);\n</script></BODY></HTML>\n";
	}

	($stdout, $stderr) = capture { test5() };

	ok($stderr eq '');
	ok($stdout =~ /href="\/"/m);
	ok($stdout !~ /<script>\s/m);

	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));

	ok($body !~ /www.example.com/m);
	ok(length($body) eq $length);
	html_ok($body, 'HTML:Lint shows no errors');

	#..........................................
	sub test6 {
		my $b = new_ok('FCGI::Buffer');

		$b->init(optimise_content => 1);

		print "Content-type: text/html; charset=ISO-8859-1\n\n";
		print "<HTML><BODY><A HREF= \"http://www.example.com/foo.htm\">Click</A></BODY></HTML>\n";
	}

	($stdout, $stderr) = capture { test6() };

	ok($stderr eq '');
	ok($stdout =~ /href="\/foo.htm"/m);
	ok($stdout =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));

	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
	ok($body !~ /www.example.com/m);
	ok(length($body) eq $length);

	#..........................................
	sub test7 {
		my $b = new_ok('FCGI::Buffer');

		$b->init(optimise_content => 1, lint_content => 1);

		print "Content-type: text/html; charset=ISO-8859-1\n\n",
			"<HTML><HEAD><TITLE>Test</TITLE></HEAD><BODY><A HREF= \n\"http://www.example.com/foo.htm\">Click</A></BODY></HTML>\n";
	}

	($stdout, $stderr) = capture { test7() };

	ok($stderr eq '');
	if($stderr ne '') {
		diag($stderr);
	}

	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));

	ok(length($body) eq $length);
	ok($body =~ /href="\/foo.htm"/mi);
	# Server is www.example.com (set in a previous test), so the href
	# should be optimised, therefore www.example.com shouldn't appear
	# anywhere at all
	ok($body !~ /www\.example\.com/m);

	#..........................................
	# Check for removal of consecutive white space between links
	delete $ENV{'HTTP_TE'};

	sub test8 {
		my $b = new_ok('FCGI::Buffer');

		$b->init(optimise_content => 1, lint_content => 1);

		print "Content-type: text/html; charset=ISO-8859-1\n\n";
		print "<HTML><HEAD><TITLE>test 8</TITLE></HEAD><BODY><A HREF= \n\"http://www.example.com/foo.htm\">Click </A> \n\t<a href=\"http://www.example.com/bar.htm\">Or here</a> </BODY></HTML>\n";
	}

	($stdout, $stderr) = capture { test8() };

	ok($stderr eq '');
	if($stderr ne '') {
		diag($stderr);
	}

	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));

	ok(length($body) eq $length);
	ok($body =~ /href="\/foo.htm"/mi);
	ok($body =~ /<a href="\/foo\.htm">Click<\/A> <a href="\/bar\.htm">Or here<\/a>/mi);

	# Server is www.example.com (set in a previous test), so the href
	# should be optimised, therefore www.example.com shouldn't appear
	# anywhere at all
	ok($body !~ /www\.example\.com/m);

	#..........................................
	sub test9 {
		my $b = new_ok('FCGI::Buffer');

		$b->init(optimise_content => 1);

		print "Content-type: text/html; charset=ISO-8859-1\n\n";
		print "<HTML><BODY><A HREF=\"http://www.example.com/foo.htm\">Click</a> <hr> A Line \n<HR>\r\n Foo</BODY></HTML>\n";
	}

	($stdout, $stderr) = capture { test9() };

	ok($stderr eq '');

	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));
	ok(length($body) eq $length);
	ok($headers !~ /^Status: 500/m);
	ok($body =~ /<hr>A Line<hr>Foo/);
	ok($body =~ /<A HREF="\/foo\.htm">Click<\/a>/i);

	# Optimise to self referring CGIs
	#..........................................
	$ENV{'SCRIPT_NAME'} = '/cgi-bin/foo.fcgi';
	sub test9a {
		my $b = new_ok('FCGI::Buffer');

		$b->init(optimise_content => 1);

		print "Content-type: text/html; charset=ISO-8859-1\n\n";
		print "<HTML><BODY><A HREF=\"http://www.example.com/cgi-bin/foo.fcgi?arg2=b\">Click</a> <hr> A Line \n<HR>\r\n Foo</BODY></HTML>\n";
	}

	($stdout, $stderr) = capture { test9a() };

	ok($stderr eq '');

	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));
	ok(length($body) eq $length);
	ok($headers !~ /^Status: 500/m);
	ok($body =~ /<hr>A Line<hr>Foo/);
	ok($body =~ /<A HREF="\?arg2=b">Click<\/a>/i);

	#..........................................
	# Space left intact after </em>
	sub test10 {
		my $b = new_ok('FCGI::Buffer');

		$b->init(optimise_content => 1, lint_content => 0);

		print "Content-type: text/html; charset=ISO-8859-1\n\n";
		print "<HTML><BODY>\n<p><em>The Brass Band Portal</em> is visited some 500 times</BODY></HTML>\n";
	}

	($stdout, $stderr) = capture { test10() };

	ok($stderr eq '');

	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));
	ok(length($body) eq $length);
	ok($headers !~ /^Status: 500/m);
	ok($body eq "<HTML><BODY><p><em>The Brass Band Portal</em> is visited some 500 times</BODY></HTML>");

	#..........................................
	delete $ENV{'SERVER_NAME'};
	sub test11 {
		my $b = new_ok('FCGI::Buffer');

		$b->init({ optimise_content => 1, lint_content => 1 });

		print "Content-type: text/html; charset=ISO-8859-1\n\n";
		print "<HTML><BODY><A HREF=\"http://www.example.com/foo.htm\">Click</BODY></HTML>\n";
	}

	($stdout, $stderr) = capture { test11() };

	ok($stderr =~ /<a>.+is never closed/);

	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));
	ok(length($body) eq $length);
	ok($headers =~ /^Status: 500/m);
	ok($body =~ /<a>.+is never closed/);

	#..........................................
	$ENV{'SERVER_PROTOCOL'} = 'HTTP/1.1';
	delete $ENV{'HTTP_ACCEPT_ENCODING'};

	sub test12 {
		my $b = new_ok('FCGI::Buffer');

		$b->init({ optimise_content => 1 });

		print "Content-type: text/html; charset=ISO-8859-1\n\n";
		print "<HTML><BODY><TABLE><TR><TD>foo</TD>  <TD>bar</TD></TR></TABLE></BODY></HTML>\n";
	}

	($stdout, $stderr) = capture { test12() };

	ok($stderr eq '');
	ok($stdout =~ /<TD>foo<\/TD><TD>bar<\/TD>/mi);
	ok($stdout =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));

	ok($stdout =~ /ETag: "([A-Za-z0-F0-f]{32})"/m);
	my $etag = $1;
	ok(defined($etag));

	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
	ok(length($body) eq $length);
	ok(length($body) > 0);

	#..........................................
	# Test HTTP_RANGE
	$ENV{'HTTP_RANGE'} = 'bytes=-40';
	($stdout, $stderr) = capture { test12() };

	ok($stderr eq '');
	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));
	ok($length <= 40);
	ok($body =~ /^<HTML>/);
	ok($body !~ /<\/HTML>$/ms);

	ok($headers =~ /ETag: "([A-Za-z0-F0-f]{32})"/m);
	$etag = $1;
	ok(defined($etag));

	ok(length($body) eq $length);
	ok(length($body) > 0);

	$ENV{'HTTP_RANGE'} = 'bytes=20-';
	($stdout, $stderr) = capture { test12() };

	ok($stderr eq '');
	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));
	ok($body !~ /^<HTML>/);
	ok($body =~ /<\/HTML>$/ms);

	ok($headers =~ /^Status: 206 Partial Content/m);
	ok($headers =~ /ETag: "([A-Za-z0-F0-f]{32})"/m);
	$etag = $1;
	ok(defined($etag));

	ok(length($body) eq $length);
	ok(length($body) > 0);
	ok($body !~ /^<HTML>/);
	ok($body =~ /<\/HTML>$/ms);

	$ENV{'HTTP_RANGE'} = 'bytes=30-39';
	($stdout, $stderr) = capture { test12() };

	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
	ok($stderr eq '');
	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));
	ok($length <= 10);
	ok($headers =~ /^Status: 206 Partial Content/m);
	ok($headers =~ /ETag: "([A-Za-z0-F0-f]{32})"/m);
	$etag = $1;
	ok(defined($etag));

	ok(length($body) eq $length);
	ok(length($body) > 0);
	delete $ENV{'HTTP_RANGE'};

	#..........................................
	# Check no problems if content_type isn't set
	$ENV{'SERVER_PROTOCOL'} = 'HTTP/1.1';
	delete $ENV{'HTTP_ACCEPT_ENCODING'};

	sub test12a {
		my $b = new_ok('FCGI::Buffer');

		$b->init({ optimise_content => 1 });

		print "charset=ISO-8859-1\n\n";
		print "<HTML><BODY><TABLE><TR><TD>foo</TD>  <TD>bar</TD></TR></TABLE></BODY></HTML>\n";
	}

	($stdout, $stderr) = capture { test12a() };

	ok($stdout =~ /<TD>foo<\/TD>  <TD>bar<\/TD>/mi);

	ok($stdout =~ /ETag: "([A-Za-z0-F0-f]{32})"/m);
	$etag = $1;
	ok(defined($etag));

	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));
	ok(length($body) eq $length);
	ok($length > 0);

	#..........................................
	$ENV{'HTTP_IF_NONE_MATCH'} = "\"$etag\"";

	($stdout, $stderr) = capture { test12a() };

	ok($stderr eq '');
	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
	ok($headers =~ /^Status: 304 Not Modified/mi);
	ok(length($body) == 0);

	$ENV{'REQUEST_METHOD'} = 'HEAD';

	($stdout, $stderr) = capture { test12a() };

	ok($stderr eq '');
	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
	ok($headers =~ /^Status: 304 Not Modified/mi);
	ok(length($body) == 0);

	#..........................................
	delete $ENV{'HTTP_ACCEPT_ENCODING'};
	$ENV{'REQUEST_METHOD'} = 'GET';

	sub test13 {
		my $b = new_ok('FCGI::Buffer');

		$b->set_options(optimise_content => 1, generate_304 => 0);

		print "Content-type: text/html; charset=ISO-8859-1\n\n";
		print "<HTML><BODY><TABLE><TR><TD>foo</TD>\t  <TD>bar</TD></TR></TABLE></BODY></HTML>\n";
	}

	($stdout, $stderr) = capture { test13() };

	ok($stderr eq '');
	ok(defined($stdout));
	ok($stdout =~ /<TD>foo<\/TD><TD>bar<\/TD>/mi);
	ok($stdout !~ /^Status: 304 Not Modified/mi);
	ok($stdout =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));

	ok($stdout =~ /ETag: "([A-Za-z0-F0-f]{32})"/m);
	$etag = $1;
	ok(defined($etag));

	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
	ok(defined($length));
	ok(length($body) eq $length);
	ok(length($body) > 0);

	#..........................................
	delete $ENV{'HTTP_ACCEPT_ENCODING'};
	$ENV{'SERVER_PROTOCOL'} = 'HTTP/1.0';
	$ENV{'REQUEST_METHOD'} = 'GET';

	sub test13a {
		my $b = new_ok('FCGI::Buffer');

		$b->set_options(optimise_content => 1, generate_304 => 0);

		print "Content-type: text/html; charset=ISO-8859-1\n\n";
		print "<HTML><BODY><TABLE><TR><TD>foo</TD>\t  <TD>bar</TD></TR></TABLE></BODY></HTML>\n";
	}

	($stdout, $stderr) = capture { test13a() };

	ok($stderr eq '');
	ok(defined($stdout));
	ok($stdout =~ /<TD>foo<\/TD><TD>bar<\/TD>/mi);
	ok($stdout !~ /^Status: 304 Not Modified/mi);
	ok($stdout =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));

	ok($stdout !~ /ETag: /m);	# HTTP/1.0 doesn't support Etag
	$etag = $1;
	ok(defined($etag));

	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
	ok(defined($length));
	ok(length($body) eq $length);
	ok(length($body) > 0);

	#..........................................
	$ENV{'HTTP_IF_NONE_MATCH'} = $etag;
	$ENV{'SERVER_PROTOCOL'} = 'HTTP/1.1';

	($stdout, $stderr) = capture { test13() };

	ok($stderr eq '');

	ok($stdout !~ /^Status: 304 Not Modified/mi);
	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
	ok(length($body) > 0);

	#..........................................
	delete $ENV{'HTTP_IF_NONE_MATCH'};
	$ENV{'HTTP_IF_MODIFIED_SINCE'} = DateTime->now();

	sub test14 {
		my $b = new_ok('FCGI::Buffer');

		$b->set_options({ optimise_content => 1, generate_etag => 0, info => new_ok('CGI::Info') });

		print "Content-type: text/html; charset=ISO-8859-1\n\n";
		print "<HTML><BODY><TABLE><TR><TD>foo</TD>\t  <TD>bar</TD></TR></TABLE></BODY></HTML>\n";
	}

	($stdout, $stderr) = capture { test14() };

	ok($stderr eq '');
	ok(defined($stdout));
	ok($stdout !~ /ETag: "([A-Za-z0-F0-f]{32})"/m);
	ok($stdout !~ /^Status: 304 Not Modified/mi);

	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;

	ok(length($body) != 0);
	ok(defined($length));
	ok(length($body) == $length);

	#..........................................
	delete $ENV{'HTTP_IF_NONE_MATCH'};
	$ENV{'HTTP_IF_MODIFIED_SINCE'} = 'Mon, 13 Jul 2015 15:09:08 GMT';

	($stdout, $stderr) = capture { test14() };

	ok($stderr eq '');
	ok(defined($stdout));
	ok($stdout !~ /ETag: "([A-Za-z0-F0-f]{32})"/m);
	ok($stdout !~ /^Status: 304 Not Modified/mi);

	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;

	ok(length($body) != 0);
	ok(defined($length));
	ok(length($body) == $length);

	#......................................
	$ENV{'HTTP_IF_MODIFIED_SINCE'} = 'This is an invalid date';

	($stdout, $stderr) = capture { test14() };
	ok($stdout !~ /ETag: "([A-Za-z0-F0-f]{32})"/m);
	ok($stdout !~ /^Status: 304 Not Modified/mi);

	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;

	ok(length($body) != 0);
	ok(defined($length));
	ok(length($body) == $length);

	#......................................
	# Check no output does nothing strange

	delete $ENV{'HTTP_IF_MODIFIED_SINCE'};

	sub test15 {
		my $b = new_ok('FCGI::Buffer');
	}

	($stdout, $stderr) = capture { test15() };

	ok($stdout eq '');
	ok($stderr eq '');

	#......................................
	# Check no body does nothing strange
	sub test16 {
		my $b = new_ok('FCGI::Buffer');

		$b->set_options({ optimise_content => 1, generate_etag => 0, info => new_ok('CGI::Info') });

		print "Content-type: text/html; charset=ISO-8859-1\n\n";
	}

	($stdout, $stderr) = capture { test16() };

	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

	ok(length($body) == 0);
	ok($headers =~ /^Content-type: text\/html; charset=ISO-8859-1/m);
	ok($stderr eq '');

	#..........................................
	# Check wide character handling
	delete $ENV{'HTTP_IF_NONE_MATCH'};

	sub test17 {
		my $b = new_ok('FCGI::Buffer');

		$b->set_options({ optimise_content => 1, generate_etag => 0 });

		print "Content-type: text/html; charset=ISO-8859-1\n\n";
		print "<HTML><BODY><TABLE><TR><TD>foo\x{0142}</TD>\t  <TD>bar</TD></TR></TABLE></BODY></HTML>\n";
	}

	($stdout, $stderr) = capture { test17() };

	ok($stderr eq '');
	ok(defined($stdout));
	ok($stdout !~ /ETag: "([A-Za-z0-F0-f]{32})"/m);
	ok($stdout !~ /^Status: 304 Not Modified/mi);

	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;

	# diag("length = " . length($body) . ", 1 = $1");

	ok(length($body) != 0);
	ok(defined($length));
	ok(length($body) == $length);

	#..........................................
	# Check output

	sub test18 {
		my $b = new_ok('FCGI::Buffer');

		$b->set_options({ optimise_content => 1, generate_etag => 0 });

		print "Content-type: text/html; charset=ISO-8859-1\n\n";
		print << 'EOF';
<HTML>
	<HEAD>
		<meta name="Description" content="Test necessary spaces are preserved">
	</HEAD>
	<BODY>
		 <a href="music.fcgi">music</a> and <a href="computing.fcgi">computing</a>
	</BODY>
</HTML>
EOF
	}

	($stdout, $stderr) = capture { test18() };

	ok($stderr eq '');
	ok(defined($stdout));
	ok($stdout !~ /ETag: "([A-Za-z0-F0-f]{32})"/m);
	ok($stdout !~ /^Status: 304 Not Modified/mi);

	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

	ok($body =~ / and /m);
	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok($headers =~ /MISS/m);

	ok(length($body) != 0);
	ok(defined($length));
	ok(length($body) == $length);

	#..........................................
	# Check handling of more complex tables
	$ENV{'SERVER_PROTOCOL'} = 'HTTP/1.1';
	delete $ENV{'HTTP_ACCEPT_ENCODING'};

	sub test19 {
		my $b = new_ok('FCGI::Buffer');

		$b->init({ optimise_content => 1 });

		print "Content-type: text/html; charset=ISO-8859-1\n\n",
			"<HTML><BODY><TABLE><TR><TD ALIGN=\"CENTER\"><A HREF=\"#anchor\"></A></TD><TD>foo</TD>  <TD>bar</TD></TR></TABLE></BODY></HTML>\n";
	}

	($stdout, $stderr) = capture { test19() };

	ok($stderr eq '');
	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));

	ok($headers =~ /ETag: "([A-Za-z0-F0-f]{32})"/m);
	$etag = $1;
	ok(defined($etag));

	ok($body =~ /<TD ALIGN="CENTER"><A HREF="#anchor"><\/A><\/TD><TD>foo<\/TD><TD>bar<\/TD>/mi);
	ok(length($body) eq $length);
	ok(length($body) > 0);

	ok($etag eq Digest::MD5->new()->add($body)->hexdigest());


	#..........................................
	# Check removal of protocol

	sub test20 {
		my $b = new_ok('FCGI::Buffer');

		$b->set_options({ optimise_content => 1, generate_etag => 0 });

		print "Content-type: text/html; charset=ISO-8859-1\n\n";
		print << 'EOF';
<HTML>
	<HEAD>
	</HEAD>
	<BODY>
		 <a href="http://www.example.com">example</a>
		 <a href="https://www.nigelhorne.com">nigelhorne</a>
	</BODY>
</HTML>
EOF
	}

	($stdout, $stderr) = capture { test20() };

	ok($stderr eq '');
	ok(defined($stdout));
	ok($stdout !~ /ETag: "([A-Za-z0-F0-f]{32})"/m);
	ok($stdout !~ /^Status: 304 Not Modified/mi);

	($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;

	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok($headers =~ /MISS/m);

	ok(length($body) != 0);
	ok(defined($length));
	ok(length($body) == $length);

	ok($body =~ /<a href="\/\/www.example.com"/);
	ok($body !~ /<a href="\/\/www.nigelhorne.com"/);

}
