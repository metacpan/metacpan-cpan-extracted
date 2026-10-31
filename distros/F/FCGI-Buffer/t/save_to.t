#!perl -w

# Tests for the save_to feature: the static pages that it writes and the
# links that it rewrites to point to them

use strict;
use warnings;
use Test::Most tests => 26;
use Test::Needs 'CHI', 'DBD::SQLite';
use Capture::Tiny ':all';
use CGI::Info;
use HTTP::Date;
use Storable;
use File::Spec;
use File::Temp qw(tempdir);
use Test::NoWarnings;

BEGIN {
	use_ok('FCGI::Buffer');
}

# A minimal stand-in for CGI::Lingua
package My::Lingua;

sub new { my ($class, $language) = @_; return bless { language => $language }, $class }
sub language { return $_[0]->{language} }

# To test what writes files, without sending anything
package My::Writer;

our @ISA = ('FCGI::Buffer');

sub new { return bless { problems => [] }, shift }
sub _problem { push @{$_[0]->{problems}}, $_[1] }
sub DESTROY { }

package main;

delete @ENV{qw(
	HTTP_ACCEPT_ENCODING HTTP_TE SERVER_PROTOCOL HTTP_RANGE HTTP_USER_AGENT
	REMOTE_ADDR HTTP_IF_NONE_MATCH HTTP_IF_MODIFIED_SINCE HTTP_COOKIE PATH_INFO
	C_DOCUMENT_ROOT HTTP_CACHE_CONTROL
)};
$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
$ENV{'REQUEST_METHOD'} = 'GET';
$ENV{'SCRIPT_NAME'} = '/cgi-bin/page.fcgi';

# Run one request through FCGI::Buffer.  Returns the body and stderr
sub request {
	my %args = @_;

	my %env = %{$args{'env'} || {}};
	my $request_uri = $args{'uri'};
	my $query_string = ($request_uri =~ /\?(.*)$/) ? $1 : '';

	local $ENV{'REQUEST_URI'} = $request_uri;
	local $ENV{'QUERY_STRING'} = $query_string;
	local @ENV{keys %env} = values %env;

	my ($stdout, $stderr) = capture {
		my $b = FCGI::Buffer->new();
		my $info = CGI::Info->new();
		$b->init({
			info => $info,
			cache => $args{'cache'},
			save_to => $args{'save_to'},
			($args{'no_lingua'} ? () : (lingua => $args{'lingua'} || My::Lingua->new('English'))),
			($args{'optimise_content'} ? (optimise_content => $args{'optimise_content'}) : ()),
		});
		# As a script does: nothing to print if it's in the cache
		unless($args{'if_cached'} && $b->is_cached()) {
			print $args{'headers'} || '', "Content-type: text/html\n\n",
				'<HTML><HEAD><TITLE>t</TITLE></HEAD><BODY>', $args{'html'}, "</BODY></HTML>\n";
		}
	};
	my ($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
	return ($body, $stderr, $headers);
}

# A new document root, save_to area and cache for each scenario
sub setup {
	my %args = @_;

	my $docroot = tempdir(CLEANUP => 1);
	my $dir = $args{'outside_docroot'} ? tempdir(CLEANUP => 1) : File::Spec->catdir($docroot, 'static');
	$ENV{'DOCUMENT_ROOT'} = $docroot;
	return (
		$docroot,
		{ directory => $dir, ttl => 3600, create_table => 1 },
		CHI->new(driver => 'Memory', datastore => {})
	);
}

sub slurp {
	my $file = shift;
	open(my $fin, '<', $file) or return;
	local $/;
	my $rc = <$fin>;
	close $fin;
	return $rc;
}

# Turn a URL path from a rewritten link back into the file it should serve
sub url_to_file {
	my ($docroot, $url) = @_;
	my @segments = map { my $s = $_; $s =~ s/%([0-9A-F]{2})/chr(hex($1))/ge; $s } split(/\//, $url);
	shift @segments;	# Leading empty segment
	return File::Spec->catfile($docroot, @segments);
}

subtest 'links to self in a static page point to its URL, not its filename' => sub {
	my ($docroot, $save_to, $cache) = setup();

	my ($body, $stderr) = request(
		uri => '/cgi-bin/page.fcgi?a=1',
		html => '<a href="/cgi-bin/page.fcgi?a=1">self</a><a href="?b=2">other</a>',
		cache => $cache,
		save_to => $save_to,
	);
	is($stderr, '', 'no errors');

	my $file = File::Spec->catfile($docroot, 'static', 'web', 'English', 'page.fcgi', 'a=1.html');
	ok(-f $file, 'static page is written') or return;
	my $html = slurp($file);
	like($html, qr{<a href="/static/web/English/page\.fcgi/a=1\.html">self</a>}, 'self link points to the static URL');
	unlike($html, qr/\Q$docroot\E/, 'the document root is not in the static page');
	like($html, qr{<a href="/cgi-bin/page\.fcgi\?b=2">other</a>}, 'relative links are made absolute');
};

subtest 'a request with no arguments is not saved as a hidden .html file' => sub {
	my ($docroot, $save_to, $cache) = setup();

	my (undef, $stderr) = request(
		uri => '/cgi-bin/page.fcgi',
		html => 'home page',
		cache => $cache,
		save_to => $save_to,
	);
	is($stderr, '', 'no errors');

	my $sdir = File::Spec->catdir($docroot, 'static', 'web', 'English', 'page.fcgi');
	ok(!-e File::Spec->catfile($sdir, '.html'), 'no .html file');
	ok(-f File::Spec->catfile($sdir, 'index.html'), 'index.html is written');

	my ($body) = request(
		uri => '/cgi-bin/page.fcgi?a=1',
		html => '<a href="/cgi-bin/page.fcgi">home</a>',
		cache => $cache,
		save_to => $save_to,
	);
	like($body, qr{<a href="/static/web/English/page\.fcgi/index\.html">home</a>}, 'link to the home page uses index.html');
};

subtest 'a document root with a trailing slash still gives an absolute URL' => sub {
	my ($docroot, $save_to, $cache) = setup();
	local $ENV{'DOCUMENT_ROOT'} = "$docroot/";

	request(uri => '/cgi-bin/page.fcgi?a=1', html => 'a', cache => $cache, save_to => $save_to);
	my ($body) = request(
		uri => '/cgi-bin/page.fcgi?b=2',
		html => '<a href="/cgi-bin/page.fcgi?a=1">a</a>',
		cache => $cache,
		save_to => $save_to,
	);
	like($body, qr{<a href="/static/web/English/page\.fcgi/a=1\.html">a</a>}, 'URL starts with a /');
};

subtest 'save_to is turned off when it is outside of the document root' => sub {
	my ($docroot, $save_to, $cache) = setup(outside_docroot => 1);

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	request(uri => '/cgi-bin/page.fcgi?a=1', html => 'a', cache => $cache, save_to => $save_to);
	ok(!-e File::Spec->catfile($save_to->{'directory'}, 'web', 'English', 'page.fcgi', 'a=1.html'), 'no page which nothing could link to');
	is(scalar(@warnings), 1, 'a warning is given');
	like($warnings[0], qr/not under the document root/, 'saying why');

	my ($body, $stderr) = request(
		uri => '/cgi-bin/page.fcgi?b=2',
		html => '<a href="/cgi-bin/page.fcgi?a=1">a</a>',
		cache => $cache,
		save_to => $save_to,
	);
	is($stderr, '', 'no errors');
	is(scalar(@warnings), 1, 'the warning is only given once');
	like($body, qr{<a href="/cgi-bin/page\.fcgi\?a=1">a</a>}, 'link still points to the CGI script');
};

subtest 'unsafe characters in arguments give a working, escaped URL' => sub {
	my ($docroot, $save_to, $cache) = setup();

	foreach my $test(
		[ 'q=a%5Cb%26c%25d', 'backslash' ],
		[ 'q=caf%C3%A9%20%2Fx', 'utf8' ],
	) {
		my ($query, $html) = @{$test};
		request(uri => "/cgi-bin/page.fcgi?$query", html => $html, cache => $cache, save_to => $save_to);
		my ($body) = request(
			uri => '/cgi-bin/page.fcgi?x=1',
			html => qq{<a href="/cgi-bin/page.fcgi?$query">$html</a>},
			cache => $cache,
			save_to => $save_to,
		);
		ok($body =~ m{<a href="(/static/[^"]+\.html)">$html</a>}, "$html: link is rewritten") or next;
		my $url = $1;
		unlike($url, qr/[#?\\&\s]|%(?![0-9A-F]{2})/, "$html: URL has no unescaped characters");
		my $file = url_to_file($docroot, $url);
		ok(-f $file, "$html: the URL leads to the static page");
		like(slurp($file), qr/\Q$html\E/, "$html: and it is the right page");
	}
};

subtest 'arguments differing only by spaces get different static pages' => sub {
	my ($docroot, $save_to, $cache) = setup();

	request(uri => '/cgi-bin/page.fcgi?city=New%20York', html => 'with space', cache => $cache, save_to => $save_to);
	request(uri => '/cgi-bin/page.fcgi?city=NewYork', html => 'without space', cache => $cache, save_to => $save_to);

	my $sdir = File::Spec->catdir($docroot, 'static', 'web', 'English', 'page.fcgi');
	opendir(my $dh, $sdir) or die "$sdir: $!";
	my @files = grep { /\.html$/ } readdir($dh);
	closedir($dh);
	is(scalar(@files), 2, 'two static pages') or diag(join(', ', @files));
};

subtest 'optimise_content does not empty links to the script itself' => sub {
	local $ENV{'SERVER_NAME'} = 'www.example.com';
	local $ENV{'HTTP_HOST'} = 'www.example.com';

	my ($body, $stderr) = request(
		uri => '/cgi-bin/page.fcgi?a=1',
		optimise_content => 1,
		html => '<a href="/cgi-bin/page.fcgi">home</a> <a href="/cgi-bin/page.fcgi?b=2" class="c">b</a> ' .
			'<a href="http://www.example.com.evil.org/x">evil</a> <a href="http://www.example.com/y">y</a>',
	);
	is($stderr, '', 'no errors');
	like($body, qr{<a href="/cgi-bin/page\.fcgi">home</a>}, 'link to script with no arguments is untouched');
	like($body, qr{<a href="\?b=2" class="c">b</a>}, 'link to script with arguments is shortened');
	like($body, qr{<a href="//www\.example\.com\.evil\.org/x">}, 'other site with our name as a prefix is not made local');
	like($body, qr{<a href="/y">}, 'link to our own site is made local');
};

subtest 'regex metacharacters in URLs' => sub {
	my ($docroot, $save_to, $cache) = setup();

	my (undef, $stderr) = request(uri => '/cgi-bin/page.fcgi?a=(1', html => 'paren', cache => $cache, save_to => $save_to);
	is($stderr, '', 'a ( in the URL does not die');

	request(uri => '/cgi-bin/page.fcgi?q=a+b', html => 'plus', cache => $cache, save_to => $save_to);
	my $body;
	($body, $stderr) = request(
		uri => '/cgi-bin/page.fcgi?x=1',
		html => '<a href="/cgi-bin/page.fcgi?q=a+b">plus</a><a href="/cgi-bin/page.fcgi?q=aab">aab</a>',
		cache => $cache,
		save_to => $save_to,
	);
	is($stderr, '', 'no errors');
	like($body, qr{<a href="/static/[^"]+\.html">plus</a>}, 'link with a + is rewritten');
	like($body, qr{<a href="/cgi-bin/page\.fcgi\?q=aab">aab</a>}, 'a different link which would match a+b as a regex is not');
};

subtest 'links with ; and &amp; are found' => sub {
	my ($docroot, $save_to, $cache) = setup();

	request(uri => '/cgi-bin/page.fcgi?a=1;b=2', html => 'semi', cache => $cache, save_to => $save_to);
	request(uri => '/cgi-bin/page.fcgi?c=1&d=2', html => 'amp', cache => $cache, save_to => $save_to);
	my ($body) = request(
		uri => '/cgi-bin/page.fcgi?x=1',
		html => '<a href="/cgi-bin/page.fcgi?a=1;b=2">semi</a><a href="?c=1&amp;d=2">amp</a>',
		cache => $cache,
		save_to => $save_to,
	);
	like($body, qr{<a href="/static/[^"]+\.html">semi</a>}, 'link with ; is rewritten');
	like($body, qr{<a href="/static/[^"]+\.html">amp</a>}, 'link with &amp; is rewritten');
};

subtest 'languages with punctuation' => sub {
	my ($docroot, $save_to, $cache) = setup();
	my $lingua = My::Lingua->new('English (United Kingdom)');

	request(uri => '/cgi-bin/page.fcgi?a=1', html => 'a', cache => $cache, save_to => $save_to, lingua => $lingua);
	my ($body, $stderr) = request(
		uri => '/cgi-bin/page.fcgi?b=2',
		html => '<a href="/cgi-bin/page.fcgi?a=1">a</a>',
		cache => $cache,
		save_to => $save_to,
		lingua => $lingua,
	);
	is($stderr, '', 'no errors');
	ok($body =~ m{<a href="(/static/[^"]+\.html)">a</a>}, 'link is rewritten') or return;
	ok(-f url_to_file($docroot, $1), 'the URL leads to the static page');
};

subtest 'quotes in the URL' => sub {
	my ($docroot, $save_to, $cache) = setup();

	my (undef, $stderr) = request(uri => "/cgi-bin/page.fcgi?name=O'Brien", html => 'quote', cache => $cache, save_to => $save_to);
	is($stderr, '', 'no errors');
	my ($body) = request(
		uri => '/cgi-bin/page.fcgi?x=1',
		html => q{<a href="/cgi-bin/page.fcgi?name=O'Brien">quote</a>},
		cache => $cache,
		save_to => $save_to,
	);
	like($body, qr{<a href="/static/[^"]+\.html">quote</a>}, 'the page was recorded and the link rewritten');
};

subtest 'pages that depend on cookies are not saved' => sub {
	my ($docroot, $save_to, $cache) = setup();
	my $sdir = File::Spec->catdir($docroot, 'static', 'web', 'English', 'page.fcgi');

	request(
		uri => '/cgi-bin/page.fcgi?a=1',
		html => 'Logged in as Fred',
		cache => $cache,
		save_to => $save_to,
		env => { HTTP_COOKIE => 'session=fred' },
	);
	ok(!-e File::Spec->catfile($sdir, 'a=1.html'), 'no static page when there is a session cookie');

	request(
		uri => '/cgi-bin/page.fcgi?b=2',
		html => 'Anyone',
		cache => $cache,
		save_to => $save_to,
		env => { HTTP_COOKIE => '__utma=1; __utmz=2' },
	);
	ok(-f File::Spec->catfile($sdir, 'b=2.html'), 'analytics cookies do not stop the page being saved');

	request(
		uri => '/cgi-bin/page.fcgi?c=3',
		html => 'Anyone',
		cache => $cache,
		save_to => $save_to,
		env => { HTTP_COOKIE => 'csrf_token=1:2:3' },
	);
	ok(-f File::Spec->catfile($sdir, 'c=3.html'), 'a csrf_token cookie does not stop the page being saved');

	request(
		uri => '/cgi-bin/page.fcgi?d=4',
		html => 'Logged in as Fred',
		cache => $cache,
		save_to => $save_to,
		env => { HTTP_COOKIE => 'csrf_token=1:2:3; session=fred' },
	);
	ok(!-e File::Spec->catfile($sdir, 'd=4.html'), 'a csrf_token cookie does not hide a session cookie');
};

subtest 'a csrf_token cookie is not part of the cache key' => sub {
	my (undef, undef, $cache) = setup();

	foreach my $token('1:2:3', '4:5:6') {
		request(uri => '/cgi-bin/page.fcgi?a=1', html => 'Anyone', cache => $cache, env => { HTTP_COOKIE => "csrf_token=$token" });
	}
	is(scalar($cache->get_keys()), 1, 'clients with different tokens share one entry');
};

# is_cached() compares the cache with the age of the script, so it has to exist
my $script = File::Spec->catfile(tempdir(CLEANUP => 1), 'page.fcgi');
open(my $fout, '>', $script) or die "$script: $!";
close $fout;
utime(1_000_000, 1_000_000, $script);
$ENV{'SCRIPT_FILENAME'} = $script;
$0 = $script;

# The value of each of the headers with the given name
sub header_values {
	my ($headers, $name) = @_;

	return $headers =~ /^\Q$name\E:\s*(.+?)\r?$/mgi;
}

# A page that links to /cgi-bin/page.fcgi?a=1, which has no static page yet
sub page_with_link {
	my ($save_to, $cache, %env) = @_;

	return request(
		uri => '/cgi-bin/page.fcgi?b=2',
		html => '<a href="/cgi-bin/page.fcgi?a=1">a</a>',
		cache => $cache,
		save_to => $save_to,
		if_cached => 1,
		env => { SERVER_PROTOCOL => 'HTTP/1.1', %env },
	);
}

subtest 'the ETag of a page not in the cache describes its rewritten links' => sub {
	my (undef, $save_to, $cache) = setup();

	my ($body, undef, $headers) = page_with_link($save_to, $cache);
	unlike($body, qr{/static/}, 'there is nothing to link to yet');
	my ($old_etag) = header_values($headers, 'ETag');

	request(uri => '/cgi-bin/page.fcgi?a=1', html => 'a', cache => $cache, save_to => $save_to);

	# Another cache, so that the page has to be made again
	my $empty = CHI->new(driver => 'Memory', datastore => {});
	($body, undef, $headers) = page_with_link($save_to, $empty, HTTP_IF_NONE_MATCH => $old_etag);
	unlike($headers, qr/^Status: 304/m, 'a client with the old links is not sent a 304');
	like($body, qr{<a href="/static/}, 'it is sent the new ones');
	my ($new_etag) = header_values($headers, 'ETag');
	isnt($new_etag, $old_etag, 'with a different ETag');

	(undef, undef, $headers) = page_with_link($save_to, $empty);
	like($headers, qr/^X-FCGI-Buffer-[\d.]+: Hit/m, 'now it is in the cache');
	is((header_values($headers, 'ETag'))[0], $new_etag, 'a hit has the same ETag as the miss');

	(undef, undef, $headers) = page_with_link($save_to, CHI->new(driver => 'Memory', datastore => {}), HTTP_IF_NONE_MATCH => $new_etag);
	like($headers, qr/^Status: 304/m, 'a client with the new links is sent a 304 on a miss');

	(undef, undef, $headers) = page_with_link($save_to, $empty, HTTP_IF_NONE_MATCH => $new_etag);
	like($headers, qr/^Status: 304/m, 'and on a hit');

	# The links are looked at again for each request
	my ($cached) = map { Storable::thaw($empty->get($_))->{'body'} } grep { /b=2/ } $empty->get_keys();
	like($cached, qr{<a href="/cgi-bin/page\.fcgi\?a=1">}, 'the cache holds the links that the script wrote');
};

subtest 'If-Modified-Since is not used for a page in the cache if If-None-Match fails' => sub {
	my (undef, $save_to, $cache) = setup();

	my (undef, undef, $headers) = page_with_link($save_to, $cache);
	my ($old_etag) = header_values($headers, 'ETag');
	my ($date) = header_values($headers, 'Last-Modified');

	request(uri => '/cgi-bin/page.fcgi?a=1', html => 'a', cache => $cache, save_to => $save_to);

	# What a browser sends
	my $body;
	($body, undef, $headers) = page_with_link($save_to, $cache, HTTP_IF_NONE_MATCH => $old_etag, HTTP_IF_MODIFIED_SINCE => $date);
	like($headers, qr/^X-FCGI-Buffer-[\d.]+: Hit/m, 'it is in the cache');
	unlike($headers, qr/^Status: 304/m, 'no 304 for a client with the old links');
	like($body, qr{<a href="/static/}, 'it is sent the new ones');
	my ($new_etag) = header_values($headers, 'ETag');

	(undef, undef, $headers) = page_with_link($save_to, $cache, HTTP_IF_MODIFIED_SINCE => $date);
	like($headers, qr/^Status: 304/m, 'If-Modified-Since on its own still gives a 304');
	is((header_values($headers, 'ETag'))[0], $new_etag, 'with the ETag of the current page');

	(undef, undef, $headers) = page_with_link($save_to, $cache, HTTP_IF_MODIFIED_SINCE => $date, HTTP_ACCEPT_ENCODING => 'gzip');
	like($headers, qr/^Status: 304/m, 'and when the client accepts gzip');
	unlike($headers, qr/^Content-Encoding/m, 'with no Content-Encoding');
};

subtest 'one Expires header is sent' => sub {
	my (undef, $save_to, $cache) = setup();

	request(uri => '/cgi-bin/page.fcgi?a=1', html => 'a', cache => $cache, save_to => $save_to);

	foreach my $request(['a miss', 'Miss'], ['a hit', 'Hit'], ['another hit', 'Hit']) {
		my (undef, undef, $headers) = page_with_link($save_to, $cache);
		like($headers, qr/^X-FCGI-Buffer-[\d.]+: $request->[1]/m, "this is $request->[0]");
		is(scalar(() = header_values($headers, 'Expires')), 1, "one on $request->[0]");
	}
	my ($key) = grep { /b=2/ } $cache->get_keys();
	unlike(Storable::thaw($cache->get($key))->{'headers'}, qr/^Expires/mi, 'none is kept in the cache');
};

subtest 'the script\'s Expires is kept' => sub {
	my (undef, $save_to, $cache) = setup();

	request(uri => '/cgi-bin/page.fcgi?a=1', html => 'a', cache => $cache, save_to => $save_to);

	my $soon = HTTP::Date::time2str(time + 60);
	my %page = (uri => '/cgi-bin/page.fcgi?b=2', html => '<a href="/cgi-bin/page.fcgi?a=1">a</a>', cache => $cache, save_to => $save_to, if_cached => 1);

	my (undef, undef, $headers) = request(%page, headers => "Expires: $soon\n");
	is_deeply([header_values($headers, 'Expires')], [$soon], 'it is earlier than the static page, on a miss');
	(undef, undef, $headers) = request(%page, headers => "Expires: $soon\n");
	like($headers, qr/^X-FCGI-Buffer-[\d.]+: Hit/m, 'now it is in the cache');
	is_deeply([header_values($headers, 'Expires')], [$soon], 'and on a hit');

	my $later = HTTP::Date::time2str(time + 7200);
	(undef, undef, $headers) = request(%page, uri => '/cgi-bin/page.fcgi?c=3', headers => "Expires: $later\n");
	my @expires = header_values($headers, 'Expires');
	is(scalar(@expires), 1, 'one, when the static page expires first');
	isnt($expires[0], $later, 'which is the static page');
};

subtest '_one_expires' => sub {
	my @none = ('Content-Type: text/html', 'ETag: "a"');
	is_deeply([FCGI::Buffer::_one_expires(@none)], \@none, 'no Expires');

	my @one = ('Expires: 0', 'ETag: "a"');
	is_deeply([FCGI::Buffer::_one_expires(@one)], \@one, 'one is left alone, even if invalid');

	my ($first, $second) = ('Expires: Fri, 30 Oct 2026 18:00:00 GMT', 'Expires: Fri, 30 Oct 2026 19:00:00 GMT');
	is_deeply([FCGI::Buffer::_one_expires($second, 'ETag: "a"', $first)], ['ETag: "a"', $first], 'the earliest of two');
	is_deeply([FCGI::Buffer::_one_expires($first, $first)], [$first], 'the same one twice');
	is_deeply([FCGI::Buffer::_one_expires('expires: 0', $first)], ['expires: 0'], 'an invalid date means already expired');
};

subtest 'a page that includes the client\'s csrf_token is not stored' => sub {
	foreach my $test(
		[ 'as it is', 'SECRETOFVICTIM', 'SECRETOFVICTIM' ],
		[ 'when the cookie is encoded', 'SECRET%3AOFVICTIM', 'SECRET:OFVICTIM' ],
	) {
		my ($name, $cookie, $value) = @{$test};
		my ($docroot, $save_to, $cache) = setup();
		my %page = (
			uri => '/cgi-bin/page.fcgi?a=1',
			html => qq{<form><input type="hidden" name="csrf_token" value="$value"></form>},
			cache => $cache,
			save_to => $save_to,
			if_cached => 1,
		);

		my ($body) = request(%page, env => { HTTP_COOKIE => "csrf_token=$cookie; __utma=1" });
		like($body, qr/\Q$value\E/, "$name: its owner is sent it");

		is(scalar($cache->get_keys()), 0, "$name: it is not in the cache");
		ok(!-e File::Spec->catfile($docroot, 'static', 'web', 'English', 'page.fcgi', 'a=1.html'), "$name: there is no static page");

		($body) = request(%page, html => 'Another client');
		unlike($body, qr/\Q$value\E/, "$name: the next client is not sent it");
	}

	my ($docroot, $save_to, $cache) = setup();
	request(uri => '/cgi-bin/page.fcgi?a=1', html => 'Anyone', cache => $cache, save_to => $save_to, env => { HTTP_COOKIE => 'csrf_token=SECRETOFVICTIM' });
	is(scalar($cache->get_keys()), 1, 'a page without it is still stored');
};

subtest 'links can give the arguments in any order' => sub {
	my (undef, $save_to, $cache) = setup();

	request(uri => '/cgi-bin/page.fcgi?b=2&a=1', html => 'page', cache => $cache, save_to => $save_to);

	my %page = (uri => '/cgi-bin/page.fcgi?c=3', cache => $cache, save_to => $save_to);
	my ($body) = request(%page, html => '<a href="/cgi-bin/page.fcgi?a=1&amp;b=2">x</a>');
	like($body, qr{<a href="/static/[^"]+\.html">x</a>}, 'another order');

	($body) = request(%page, html => '<a href="?b=2&amp;a=1">x</a>');
	like($body, qr{<a href="/static/[^"]+\.html">x</a>}, 'the order it was asked for in, to itself');

	($body) = request(%page, html => '<a href="/cgi-bin/page.fcgi?a=1&amp;b=3">x</a>');
	unlike($body, qr{/static/}, 'different arguments are a different page');
};

subtest 'static pages are written atomically' => sub {
	my ($docroot, $save_to, $cache) = setup();
	my $sdir = File::Spec->catdir($docroot, 'static', 'web', 'English', 'page.fcgi');

	request(uri => '/cgi-bin/page.fcgi?a=1', html => 'page', cache => $cache, save_to => $save_to);

	my $file = File::Spec->catfile($sdir, 'a=1.html');
	like(slurp($file), qr/page/, 'the page is written');
	is((stat($file))[2] & 0777, 0666 & ~umask(), 'the web server can read it');

	opendir(my $dh, $sdir) or die "$sdir: $!";
	my @files = grep { !/^\.\.?$/ } readdir($dh);
	closedir($dh);
	is_deeply(\@files, ['a=1.html'], 'nothing else is left behind');
};

subtest '_write_atomically' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $writer = My::Writer->new();
	my $file = File::Spec->catfile($dir, 'page.html');

	ok($writer->_write_atomically($file, 'old'), 'a new file');
	is(slurp($file), 'old', 'has the contents');

	ok($writer->_write_atomically($file, 'new'), 'replacing a file');
	is(slurp($file), 'new', 'has the new contents');

	my $missing = File::Spec->catfile($dir, 'missing', 'page.html');
	ok(!$writer->_write_atomically($missing, 'x'), "the file can't be created");
	like($writer->{problems}->[0], qr/Can't create \Q$missing\E/, 'and that is reported');

	# rename() can't replace a directory
	my $target = File::Spec->catdir($dir, 'target');
	mkdir $target or die "$target: $!";
	$writer = My::Writer->new();
	ok(!$writer->_write_atomically($target, 'x'), "the file can't be moved into place");
	like($writer->{problems}->[0], qr/Can't create \Q$target\E/, 'and that is reported');

	opendir(my $dh, $dir) or die "$dir: $!";
	my @files = sort grep { !/^\.\.?$/ } readdir($dh);
	closedir($dh);
	is_deeply(\@files, ['page.html', 'target'], 'the temporary file is removed');
};

subtest 'save_to works without a lingua object' => sub {
	my ($docroot, $save_to, $cache) = setup();

	my (undef, $stderr) = request(uri => '/cgi-bin/page.fcgi?a=1', html => 'a', cache => $cache, save_to => $save_to, no_lingua => 1);
	is($stderr, '', 'no errors');
	ok(-f File::Spec->catfile($docroot, 'static', 'web', 'default', 'page.fcgi', 'a=1.html'), 'static page is written');
	my $body;
	($body, $stderr) = request(
		uri => '/cgi-bin/page.fcgi?b=2',
		html => '<a href="/cgi-bin/page.fcgi?a=1">a</a>',
		cache => $cache,
		save_to => $save_to,
		no_lingua => 1,
	);
	is($stderr, '', 'no errors');
	like($body, qr{<a href="/static/web/default/page\.fcgi/a=1\.html">a</a>}, 'link is rewritten');
};

subtest 'PATH_INFO is part of the cache key' => sub {
	my ($docroot, $save_to, $cache) = setup();

	request(uri => '/cgi-bin/page.fcgi/a', html => 'page a', cache => $cache, env => { PATH_INFO => '/a' });

	local $ENV{'PATH_INFO'} = '/b';
	local $ENV{'REQUEST_URI'} = '/cgi-bin/page.fcgi/b';
	local $ENV{'QUERY_STRING'} = '';
	my $is_cached;
	capture {
		my $b = FCGI::Buffer->new();
		$b->init({ info => CGI::Info->new(), cache => $cache });
		$is_cached = $b->is_cached();
	};
	ok(!$is_cached, '/b is not served from the cache entry for /a');
};
