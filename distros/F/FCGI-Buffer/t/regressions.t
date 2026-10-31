#!perl -w

# End to end tests of faults found by a gap analysis of the module: leaks of
# private data, lost or corrupted responses and bad protocol handling.
# Each runs a whole request, since most of them were in how the steps combine.

use strict;
use warnings;
use Test::Most tests => 30;
use Test::Needs 'CHI', 'DBD::SQLite';
use Capture::Tiny ':all';
use CGI::Info;
use Compress::Zlib;
use DBI;
use File::Find;
use File::Spec;
use File::Temp qw(tempdir);
use HTTP::Date;
use Test::NoWarnings;

BEGIN {
	use_ok('FCGI::Buffer');
}

# A minimal stand-in for CGI::Lingua
package My::Lingua;

sub new { my ($class, $language) = @_; return bless { language => $language }, $class }
sub language { return $_[0]->{language} }

# A logger which keeps what it's told, and can be told how to behave
package My::Logger;

sub new { my ($class, %args) = @_; return bless { %args, warnings => [] }, $class }
sub trace { die "logger failed\n" if($_[0]->{die_in_trace}) }
sub debug { }
sub info { }
sub warn { my $self = shift; push @{$self->{warnings}}, join('', @_) }
sub error { }

# Logs at debug level, and remembers what was logged
package My::DebugLogger;

our @ISA = ('My::Logger');

sub is_debug { return 1 }
sub debug { my $self = shift; push @{$self->{debug}}, join('', @_) }

# A cache which fails when asked to do something
package My::BadCache;

sub new { my ($class, $bad) = @_; return bless { bad => $bad }, $class }
sub get_object { die "cache is down\n" if($_[0]->{bad} eq 'get_object'); return }
sub set { die "cache is down\n" if($_[0]->{bad} eq 'set') }
sub get { return }
sub remove { }

package main;

delete @ENV{qw(
	HTTP_ACCEPT_ENCODING HTTP_TE HTTP_RANGE Range HTTP_IF_RANGE HTTP_USER_AGENT
	REMOTE_ADDR HTTP_IF_NONE_MATCH HTTP_IF_MODIFIED_SINCE HTTP_COOKIE PATH_INFO
	C_DOCUMENT_ROOT HTTP_CACHE_CONTROL NO_CACHE NO_STORE HTTP_AUTHORIZATION
	REMOTE_USER CONTENT_LENGTH CONTENT_TYPE
)};
$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
$ENV{'REQUEST_METHOD'} = 'GET';
$ENV{'SERVER_PROTOCOL'} = 'HTTP/1.1';
$ENV{'SCRIPT_NAME'} = '/cgi-bin/page.fcgi';
$ENV{'QUERY_STRING'} = 'a=1';
$ENV{'REQUEST_URI'} = '/cgi-bin/page.fcgi?a=1';
$ENV{'HTTP_HOST'} = 'www.example.com';

# is_cached() needs a script whose age it can find
my $script = File::Spec->catfile(tempdir(CLEANUP => 1), 'page.fcgi');
open(my $fout, '>', $script) or die "$script: $!";
close $fout;
utime(1_000_000, 1_000_000, $script);
$ENV{'SCRIPT_FILENAME'} = $script;
$0 = $script;

my $PADDING = 'x' x 200;
my $PAGE = "Content-type: text/html\n\n<html><body>$PADDING</body></html>\n";

sub cache { return CHI->new(driver => 'Memory', datastore => {}) }

# Run one request.  Returns the headers, body and stderr
sub request {
	my %args = @_;

	local %ENV = (%ENV, %{$args{'env'} || {}});
	my ($stdout, $stderr) = capture {
		my $b = FCGI::Buffer->new();
		$b->init({ info => CGI::Info->new(), %{$args{'init'} || {}} });
		print $args{'output'};
		undef $b;
	};
	my ($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
	return ($headers, $body, $stderr);
}

# Would the next request be answered by the cache?
sub is_hit {
	my %args = @_;

	local %ENV = (%ENV, %{$args{'env'} || {}});
	my $hit;
	my $stdout = capture_stdout {
		my $b = FCGI::Buffer->new();
		$b->init({ info => CGI::Info->new(), cache => $args{'cache'}, %{$args{'init'} || {}} });
		$hit = $b->is_cached();
		print "Content-type: text/html\n\nregenerated\n" unless($hit);
		undef $b;
	};
	my ($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
	return ($hit, $headers, $body);
}

# A new document root and save_to area
sub setup {
	my $docroot = tempdir(CLEANUP => 1);
	$ENV{'DOCUMENT_ROOT'} = $docroot;
	return ($docroot, { directory => File::Spec->catdir($docroot, 'static'), ttl => 3600, create_table => 1 });
}

sub static_pages {
	my $dir = shift;

	my @files;
	find(sub { push @files, $File::Find::name if(-f $_ && /\.html$/) }, $dir);
	return @files;
}

sub slurp {
	my $file = shift;

	open(my $fin, '<:raw', $file) or return;
	local $/;
	return scalar(<$fin>);
}

sub database {
	my $save_to = shift;

	return DBI->connect('dbi:SQLite:dbname=' . File::Spec->catfile($save_to->{'directory'}, 'fcgi.buffer.sql'), undef, undef, { RaiseError => 1 });
}

subtest 'UTF-8 printed as bytes is not encoded a second time' => sub {
	my $utf8 = "caf\xc3\xa9";
	my $output = "Content-type: text/html; charset=utf-8\n\n<html><body>$utf8 $PADDING</body></html>\n";

	my (undef, $body) = request(output => $output);
	like($body, qr/\Q$utf8\E/, 'not compressed');

	my $headers;
	($headers, $body) = request(output => $output, env => { HTTP_ACCEPT_ENCODING => 'gzip' });
	like($headers, qr/^Content-Encoding: gzip/m, 'it is compressed');
	like(Compress::Zlib::memGunzip($body), qr/\Q$utf8\E/, 'compressed');

	(undef, $body) = request(output => $output, init => { optimise_content => 1 });
	like($body, qr/\Q$utf8\E/, 'optimised');

	my ($docroot, $save_to) = setup();
	request(output => $output, init => { cache => cache(), save_to => $save_to });
	my ($file) = static_pages($docroot);
	like(slurp($file), qr/\Q$utf8\E/, 'static page');

	# Characters are a different matter
	($headers, $body) = request(output => "Content-type: text/plain\n\n" . ("\x{263A}" x 50), env => { HTTP_ACCEPT_ENCODING => 'gzip' });
	is(Compress::Zlib::memGunzip($body), "\xe2\x98\xba" x 50, 'characters are encoded once');
};

subtest 'Range' => sub {
	my ($headers, $body) = request(
		output => "Status: 200 OK\r\nContent-type: text/plain\r\n\r\n0123456789",
		env => { HTTP_RANGE => 'bytes=0-3' }
	);
	like($headers, qr/^Status: 206/m, "the script's Status: 200 doesn't stop a 206");
	unlike($headers, qr/^Status: 200/m, 'and is not also sent');
	is($body, '0123', 'part of the body');

	($headers, $body) = request(
		output => "Status: 404 Not Found\r\nContent-type: text/plain\r\n\r\n0123456789",
		env => { HTTP_RANGE => 'bytes=0-3' }
	);
	like($headers, qr/^Status: 404/m, 'an error is not cut up');
	unlike($headers, qr/^Content-Range/m, 'no Content-Range on an error');
	is($body, '0123456789', 'all of the error is sent');

	($headers, $body) = request(output => $PAGE, env => { HTTP_RANGE => 'bytes=0-99', HTTP_ACCEPT_ENCODING => 'gzip' });
	like($headers, qr/^Content-Range: bytes 0-99\//m, 'gzip: Content-Range');
	unlike($headers, qr/^Content-Encoding/m, 'gzip: a part is not compressed');
	is(length($body), 100, 'gzip: and has the right length');

	($headers, $body) = request(output => "Content-type: text/plain\n\n" . ("\x{263A}" x 10), env => { HTTP_RANGE => 'bytes=0-2' });
	like($headers, qr{^Content-Range: bytes 0-2/30}m, 'wide characters: counted in bytes');
	like($headers, qr/^Content-Length: 3/m, 'wide characters: Content-Length');
	is($body, "\xe2\x98\xba", 'wide characters: the bytes asked for');

	my $post = { REQUEST_METHOD => 'POST', CONTENT_LENGTH => 0, CONTENT_TYPE => 'application/x-www-form-urlencoded', HTTP_RANGE => 'bytes=0-3' };
	($headers) = request(output => $PAGE, env => $post);
	unlike($headers, qr/^Content-Range/m, 'POST: ignored');

	my ($full) = request(output => $PAGE);
	my ($etag) = $full =~ /^ETag: (\S+)/m;
	($headers, $body) = request(output => $PAGE, env => { HTTP_RANGE => 'bytes=0-3', HTTP_IF_RANGE => '"stale"' });
	unlike($headers, qr/^Content-Range/m, 'If-Range with an old ETag gives the whole page');
	($headers, $body) = request(output => $PAGE, env => { HTTP_RANGE => 'bytes=0-3', HTTP_IF_RANGE => $etag });
	like($headers, qr/^Content-Range/m, 'If-Range with the current ETag gives the part');
	is(length($body), 4, 'of the right length');
	($headers) = request(output => $PAGE, env => { HTTP_RANGE => 'bytes=0-3', HTTP_IF_RANGE => "W/$etag" });
	unlike($headers, qr/^Content-Range/m, 'a weak ETag is not good enough');
	($headers) = request(output => $PAGE, env => { HTTP_RANGE => 'bytes=0-3', HTTP_IF_RANGE => HTTP::Date::time2str(1_000_000) });
	like($headers, qr/^Content-Range/m, "If-Range with the script's date");
	($headers) = request(output => $PAGE, env => { HTTP_RANGE => 'bytes=0-3', HTTP_IF_RANGE => HTTP::Date::time2str(2_000_000) });
	unlike($headers, qr/^Content-Range/m, 'If-Range with another date');

	($headers, $body) = request(output => $PAGE, init => { cache => cache() }, env => { HTTP_RANGE => 'bytes=0-3' });
	unlike($headers, qr/^Content-Range/m, 'with a cache the whole page is sent, as documented');
	like($body, qr/<\/html>/, 'all of it');
};

subtest 'headers from the script' => sub {
	my ($headers, $body) = request(
		output => "Content-Length: 228\r\nContent-type: text/plain\r\n\r\n$PADDING",
		env => { HTTP_ACCEPT_ENCODING => 'gzip' }
	);
	my @lengths = $headers =~ /^Content-Length: (\d+)/mg;
	is_deeply(\@lengths, [ length($body) ], 'the Content-Length is that of what is sent');

	($headers) = request(output => "Content-type: text/plain\nContent-Length: 5\n\nhello");
	@lengths = $headers =~ /^Content-Length: (\d+)/mg;
	is_deeply(\@lengths, [ 5 ], 'lines ending in LF: one Content-Length');

	($headers) = request(output => "Content-type: text/plain\nStatus: 404 Not Found\n\nhello");
	my @statuses = $headers =~ /^Status: (.+?)\r?$/mg;
	is_deeply(\@statuses, [ '404 Not Found' ], 'lines ending in LF: one Status');

	($headers) = request(output => "Content-type: text/plain\r\nstatus: 404 Gone Away\r\n\r\nhello");
	@statuses = $headers =~ /^status: (.+?)\r?$/mgi;
	is_deeply(\@statuses, [ '404 Gone Away' ], "the script's own wording is kept");

	($headers) = request(output => "Etag: \"abc\"\r\nContent-type: text/plain\r\n\r\nhello");
	my @etags = $headers =~ /^ETag: (.+?)\r?$/mgi;
	is(scalar(@etags), 1, "one ETag, whatever the script's case");

	my $gzipped = Compress::Zlib::memGzip($PADDING);
	my $cache = cache();
	my $body2;
	($headers, $body2) = request(
		output => "Content-Encoding: gzip\r\nContent-type: text/html\r\n\r\n$gzipped",
		env => { HTTP_ACCEPT_ENCODING => 'gzip' },
		init => { cache => $cache, optimise_content => 1 },
	);
	my @encodings = $headers =~ /^Content-Encoding: (\S+)/mg;
	is_deeply(\@encodings, [ 'gzip' ], 'already compressed: not compressed again');
	is(Compress::Zlib::memGunzip($body2), $PADDING, 'already compressed: and not optimised');
	my ($hit) = is_hit(cache => $cache);
	ok(!$hit, 'already compressed: not stored, since the header would be lost');
};

subtest 'conditional requests' => sub {
	my ($headers) = request(output => $PAGE);
	my ($etag) = $headers =~ /^ETag: (\S+)/m;
	like($etag, qr/^"[0-9a-f]{32}"$/, 'uncompressed ETag');

	($headers) = request(output => "Status: 200 OK\r\n$PAGE", env => { HTTP_IF_NONE_MATCH => $etag });
	my @statuses = $headers =~ /^Status: (\d+)/mg;
	is_deeply(\@statuses, [ 304 ], "a 304 doesn't also have the script's Status: 200");

	my $post = { REQUEST_METHOD => 'POST', CONTENT_LENGTH => 0, CONTENT_TYPE => 'application/x-www-form-urlencoded' };
	my $body;
	($headers, $body) = request(output => $PAGE, env => { %{$post}, HTTP_IF_NONE_MATCH => $etag });
	like($headers, qr/^Status: 412/m, 'POST: a match gives 412');
	ok(!length($body || ''), 'with no body');

	my $future = HTTP::Date::time2str(time + 3600);
	($headers) = request(output => $PAGE, env => { %{$post}, HTTP_IF_MODIFIED_SINCE => $future });
	like($headers, qr/^Status: 200/m, 'POST: If-Modified-Since is ignored');

	($headers) = request(output => $PAGE, env => { HTTP_IF_MODIFIED_SINCE => $future });
	like($headers, qr/^Status: 304/m, 'If-Modified-Since works');

	($headers) = request(output => $PAGE, env => { HTTP_IF_MODIFIED_SINCE => $future, HTTP_IF_NONE_MATCH => '"other"' });
	like($headers, qr/^Status: 200/m, "If-Modified-Since isn't used when If-None-Match fails");

	($headers) = request(output => "Status: 404 Not Found\r\n$PAGE", env => { HTTP_IF_MODIFIED_SINCE => $future });
	like($headers, qr/^Status: 404/m, 'a 404 stays a 404');

	($headers) = request(output => $PAGE, env => { HTTP_ACCEPT_ENCODING => 'gzip' });
	my ($gzip_etag) = $headers =~ /^ETag: (\S+)/m;
	(my $expected = $etag) =~ s/"$/-gzip"/;
	is($gzip_etag, $expected, 'the compressed version has its own ETag');

	($headers) = request(output => $PAGE, env => { HTTP_ACCEPT_ENCODING => 'gzip', HTTP_IF_NONE_MATCH => $gzip_etag });
	like($headers, qr/^Status: 304/m, 'which matches');
	like($headers, qr/^ETag: \Q$gzip_etag\E/m, "and the 304 gives the client's ETag back");
	unlike($headers, qr/^Content-Encoding/m, "a 304 doesn't have a Content-Encoding");

	($headers) = request(output => $PAGE);
	like($headers, qr/^Vary: Accept-Encoding/m, 'Vary is sent when not compressed');
	($headers) = request(output => "Content-type: image/png\n\n$PADDING");
	unlike($headers, qr/^Vary/m, "but not with something that wouldn't be compressed");
	($headers) = request(output => $PAGE, env => { HTTP_ACCEPT_ENCODING => 'gzip' });
	my @vary = $headers =~ /^(Vary: .+?)\r?$/mg;
	is(scalar(@vary), 1, 'and only once when compressed');

	foreach my $protocol('HTTP/1.1', 'HTTP/2', 'HTTP/2.0', 'HTTP/3', 'HTTP/3.0') {
		($headers) = request(output => $PAGE, env => { SERVER_PROTOCOL => $protocol });
		like($headers, qr/^ETag/m, "$protocol has ETags");
	}
	($headers) = request(output => $PAGE, env => { SERVER_PROTOCOL => 'HTTP/1.0' });
	unlike($headers, qr/^ETag/m, 'HTTP/1.0 has none');
};

subtest 'a response from the cache' => sub {
	my $cache = cache();
	request(output => $PAGE, init => { cache => $cache });

	my $future = HTTP::Date::time2str(time + 3600);
	my ($hit, $headers, $body) = is_hit(cache => $cache, env => { HTTP_IF_MODIFIED_SINCE => $future });
	ok($hit, 'is in the cache');
	like($headers, qr/^Status: 304/m, 'If-Modified-Since gives a 304');
	ok(!length($body || ''), 'with no body');

	my ($etag) = (is_hit(cache => $cache))[1] =~ /^ETag: (\S+)/m;
	($hit, $headers) = is_hit(cache => $cache, env => { HTTP_IF_NONE_MATCH => $etag });
	like($headers, qr/^Status: 304/m, 'If-None-Match gives a 304');

	($hit, $headers) = is_hit(cache => $cache, init => { generate_304 => 0 }, env => { HTTP_IF_NONE_MATCH => $etag });
	ok($hit, 'with generate_304 off it is still in the cache');
	unlike($headers, qr/^Status: 304/m, 'but If-None-Match gives no 304');

	($hit, $headers, $body) = is_hit(cache => $cache, env => { HTTP_ACCEPT_ENCODING => 'gzip' });
	like($headers, qr/^ETag: "[0-9a-f]{32}-gzip"/m, 'the compressed version has its own ETag');
	my @lengths = $headers =~ /^Content-Length: (\d+)/mg;
	is_deeply(\@lengths, [ length($body) ], 'one correct Content-Length');
	like(Compress::Zlib::memGunzip($body), qr/<\/html>/, 'and is the page');
};

subtest 'clients that have logged in' => sub {
	foreach my $env({ HTTP_AUTHORIZATION => 'Basic abc' }, { REMOTE_USER => 'alice' }) {
		my ($name) = keys %{$env};
		my $cache = cache();
		my ($docroot, $save_to) = setup();
		request(output => $PAGE, env => $env, init => { cache => $cache, save_to => $save_to });
		my ($hit) = is_hit(cache => $cache);
		ok(!$hit, "$name: not in the cache");
		is(scalar(static_pages($docroot)), 0, "$name: no static page");
	}
};

subtest 'a cache_key does not make a page with cookies public' => sub {
	my ($docroot, $save_to) = setup();
	request(
		output => $PAGE,
		env => { HTTP_COOKIE => 'session=fred' },
		init => { cache => cache(), cache_key => 'key', save_to => $save_to }
	);
	is(scalar(static_pages($docroot)), 0, 'no static page');
};

subtest 'responses that say they are not to be shared' => sub {
	foreach my $header('Set-Cookie: session=victim', 'Cache-Control: private', 'Cache-Control: no-store', 'cache-control: max-age=60, No-Cache', 'Vary: Accept-Language', 'Vary: User-Agent, Accept-Encoding') {
		my $cache = cache();
		my ($docroot, $save_to) = setup();
		my ($headers) = request(output => "$header\r\n$PAGE", init => { cache => $cache, save_to => $save_to });
		like($headers, qr/^\Q$header\E/m, "$header: is sent to this client");
		my $hit;
		($hit, $headers) = is_hit(cache => $cache);
		ok(!$hit, "$header: not in the cache");
		unlike($headers, qr/^\Q$header\E/m, "$header: not sent to the next client");
		is(scalar(static_pages($docroot)), 0, "$header: no static page");
	}

	foreach my $header('Cache-Control: max-age=60', 'Vary: Accept-Encoding') {
		my $cache = cache();
		request(output => "$header\r\n$PAGE", init => { cache => $cache });
		my ($hit) = is_hit(cache => $cache);
		ok($hit, "$header: is cached");
	}

	my $cache = cache();
	my %lingua = (lingua => My::Lingua->new('English'));
	request(output => "Vary: Accept-Language\r\n$PAGE", init => { cache => $cache, %lingua });
	my ($hit) = is_hit(cache => $cache, init => \%lingua);
	ok($hit, 'Vary: Accept-Language is cached if lingua is part of the key');
};

subtest 'POST is not cached' => sub {
	my $post = { REQUEST_METHOD => 'POST', CONTENT_LENGTH => 0, CONTENT_TYPE => 'application/x-www-form-urlencoded' };
	my $cache = cache();
	my ($docroot, $save_to) = setup();
	request(output => $PAGE, env => $post, init => { cache => $cache, save_to => $save_to });
	my ($hit) = is_hit(cache => $cache, env => $post);
	ok(!$hit, 'the script is run again');
	is(scalar(static_pages($docroot)), 0, 'no static page');
};

subtest 'a script that dies part way through' => sub {
	my $cache = cache();
	my ($docroot, $save_to) = setup();
	capture {
		eval {
			my $b = FCGI::Buffer->new();
			$b->init({ info => CGI::Info->new(), cache => $cache, save_to => $save_to });
			print "Content-type: text/html\n\n<html><body>Part of";
			die "failed\n";
		};
		is($@, "failed\n", "the caller's exception isn't disturbed");
	};
	my ($hit) = is_hit(cache => $cache);
	ok(!$hit, 'the truncated page is not cached');
	is(scalar(static_pages($docroot)), 0, 'or saved');

	$cache = cache();
	request(output => $PAGE, init => { cache => $cache });
	($hit) = is_hit(cache => $cache);
	ok($hit, 'a whole page is');

	$cache = cache();
	request(output => "Content-type: text/html\n\n<p>A fragment</p>\n", init => { cache => $cache });
	($hit) = is_hit(cache => $cache);
	ok($hit, 'and so is a fragment that has no <html>');
};

subtest 'expired entries in the cache are not used' => sub {
	my $cache = cache();
	request(output => $PAGE, init => { cache => $cache, cache_duration => '1 second' });
	my ($hit) = is_hit(cache => $cache);
	ok($hit, 'is there at first');
	sleep 3;
	my ($headers, $body);
	($hit, $headers, $body) = is_hit(cache => $cache);
	ok(!$hit, 'has expired');
	like($body, qr/regenerated/, 'so the page is made again');
};

subtest "the client's max-age" => sub {
	my $b = FCGI::Buffer->new();
	select($b->{old_buf});
	foreach my $test([ 'max-age=60', '60 seconds' ], [ 'max-age=600', '600 seconds' ], [ 'max-age=601', '1 hour' ], [ 'max-age=99999999', '1 hour' ], [ 'max-age=1abc', '1 hour' ]) {
		my ($header, $expected) = @{$test};
		local $ENV{'HTTP_CACHE_CONTROL'} = $header;
		delete $b->{cache_duration};
		delete $b->{x_cache};
		$b->init(cache => cache(), cache_duration => '1 hour');
		is($b->{cache_duration}, $expected, $header);
	}
	delete $b->{buf};

	my ($headers, $body, $stderr) = request(output => $PAGE, init => { cache => cache() }, env => { HTTP_CACHE_CONTROL => 'max-age=1abc' });
	is($stderr, '', 'an invalid max-age is not an error');
	like($body, qr/<\/html>/, 'and the page is sent');
};

subtest 'failures do not lose the page' => sub {
	my $logger = My::Logger->new();

	my ($docroot, $save_to) = setup();
	delete $save_to->{'create_table'};
	my ($headers, $body) = request(output => $PAGE, init => { cache => cache(), save_to => $save_to, logger => $logger });
	like($body, qr/<\/html>/, 'no table: the page is sent');
	like($logger->{warnings}->[0], qr/no such table/, 'no table: and the reason is logged');

	($docroot, $save_to) = setup();
	mkdir $save_to->{'directory'};
	open(my $db, '>', File::Spec->catfile($save_to->{'directory'}, 'fcgi.buffer.sql')) or die $!;
	print $db 'This is not a database, ' x 100;
	close $db;
	(undef, $body) = request(output => $PAGE, init => { cache => cache(), save_to => $save_to, logger => $logger });
	like($body, qr/<\/html>/, 'corrupt database: the page is sent');

	($docroot, $save_to) = setup();
	mkdir $save_to->{'directory'};
	open(my $file, '>', File::Spec->catfile($save_to->{'directory'}, 'web')) or die $!;
	close $file;
	(undef, $body) = request(output => $PAGE, init => { cache => cache(), save_to => $save_to, logger => $logger });
	like($body, qr/<\/html>/, "can't create the directories: the page is sent");

	($docroot, $save_to) = setup();
	my $sdir = File::Spec->catdir($save_to->{'directory'}, 'web', 'default', 'page.fcgi');
	File::Path::make_path(File::Spec->catdir($sdir, 'a=1.html'));
	$logger = My::Logger->new();
	(undef, $body) = request(output => $PAGE, init => { cache => cache(), save_to => $save_to, logger => $logger });
	like($body, qr/<\/html>/, "can't create the page: the page is sent");
	like($logger->{warnings}->[0], qr/Can't create/, "can't create the page: and it is logged");

	$logger = My::Logger->new();
	(undef, $body) = request(output => $PAGE, init => { cache => My::BadCache->new('set'), logger => $logger });
	like($body, qr/<\/html>/, 'the cache fails to store: the page is sent');
	like($logger->{warnings}->[0], qr/cache is down/, 'the cache fails to store: and it is logged');

	$logger = My::Logger->new();
	my ($hit, undef, $regenerated) = is_hit(cache => My::BadCache->new('get_object'), init => { logger => $logger });
	ok(!$hit, 'the cache fails to read: is a miss');
	like($regenerated, qr/regenerated/, 'the cache fails to read: the page is made');

	# Falling back to what the script printed
	$logger = My::Logger->new(die_in_trace => 1);
	($headers, $body) = request(output => $PAGE, env => { HTTP_ACCEPT_ENCODING => 'gzip' }, init => { logger => $logger });
	like($body, qr/<\/html>/, 'the logger fails: the page is sent as it was printed');
	like($logger->{warnings}->[0], qr/logger failed/, 'the logger fails: and it is reported');

	my ($stdout, $stderr) = capture {
		my $b = FCGI::Buffer->new();
		$b->init(logger => My::Logger->new(die_in_trace => 1));
		print $PAGE;
		undef $b;
		print 'printed afterwards';
	};
	like($stdout, qr/printed afterwards$/, 'and what the process prints next is not lost');
	is(select(), 'main::STDOUT', 'since the old file handle is selected again');

	# A cache which said that it had the page, then didn't
	($stdout, $stderr) = capture {
		my $b = FCGI::Buffer->new();
		$b->init(logger => My::Logger->new(die_in_trace => 1));
		undef $b;
	};
	like($stdout, qr/^Status: 500/, 'with nothing to send it is an error');
};

subtest 'a logger without the methods that are used' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	package My::DebugOnly;
	sub new { return bless {}, shift }
	sub debug { }

	package main;

	my ($headers, $body) = request(output => $PAGE, init => { logger => My::DebugOnly->new() });
	like($body, qr/<\/html>/, 'the page is sent');
	like($warnings[0], qr/logger doesn't understand trace/, 'and a warning given');
	is(select(), 'main::STDOUT', 'the old file handle is selected again');

	my $b = FCGI::Buffer->new(logger => 'not an object');
	select($b->{old_buf});
	ok(!defined($b->{logger}), 'new() checks the logger as well');
	delete $b->{buf};
};

subtest 'bad arguments to init and new' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	foreach my $test(
		[ 'a string', '/tmp/x', qr/save_to must be a hash reference/ ],
		[ 'no directory', { ttl => 1 }, qr/save_to needs a directory/ ],
		[ 'not a directory', { directory => 'Makefile.PL' }, qr/isn't a directory/ ],
	) {
		my ($name, $save_to, $message) = @{$test};
		@warnings = ();
		my $stdout = capture_stdout {
			my $b = FCGI::Buffer->new();
			is($b->init(save_to => $save_to), $b, "$name: init still returns the object");
			ok(!defined($b->{save_to}), "$name: save_to isn't used");
			print $PAGE;
		};
		like($warnings[0], $message, "$name: gives a warning");
		like($stdout, qr/<\/html>/, "$name: the page is sent");
	}

	SKIP: {
		skip('root can write to anything', 2) if($> == 0);

		my $dir = tempdir(CLEANUP => 1);
		chmod 0555, $dir;
		@warnings = ();
		my $stdout = capture_stdout {
			my $b = FCGI::Buffer->new()->init({ save_to => { directory => $dir } });
			ok($b->can_cache(), 'unwriteable: calls can still be chained');
			print $PAGE;
		};
		like($warnings[0], qr/isn't writeable/, 'unwriteable: gives a warning');
		chmod 0755, $dir;
	}

	lives_ok { FCGI::Buffer->import(generate_etag => 1) } 'arguments to use are ignored';

	my $b = FCGI::Buffer->new(save_to => 'garbage');
	select($b->{old_buf});
	ok(!defined($b->{save_to}), 'new() checks save_to as well');
	delete $b->{buf};

	# The same message about the same thing isn't repeated
	@warnings = ();
	$b = FCGI::Buffer->new(save_to => 'garbage');
	select($b->{old_buf});
	is(scalar(@warnings), 0, 'each problem is only reported once');
	delete $b->{buf};

	{
		local $ENV{'REQUEST_METHOD'} = 'POST';
		$b = FCGI::Buffer->new(cache => cache());
		select($b->{old_buf});
		ok(!defined($b->{cache}), "new() doesn't use the cache when it isn't allowed to");
		delete $b->{buf};
	}
};

subtest 'stored cross-site scripting through the URL' => sub {
	my ($docroot, $save_to) = setup();
	request(
		output => qq{Content-type: text/html\n\n<html><body><a href="?b=2">x</a></body></html>\n},
		env => { REQUEST_URI => '/cgi-bin/page.fcgi/"><script>alert(1)</script>?a=1', PATH_INFO => '/x' },
		init => { cache => cache(), save_to => $save_to }
	);
	my ($file) = static_pages($docroot);
	my $html = slurp($file);
	unlike($html, qr/<script>/, 'no script in the static page');
	like($html, qr{<a href="/cgi-bin/page\.fcgi/&quot;&gt;&lt;script&gt;}, 'the URL is escaped');
};

subtest 'static pages that pass their ttl' => sub {
	my ($docroot, $save_to) = setup();
	my %page = map { $_ => "Content-type: text/html\n\n<html><body>Version $_</body></html>\n" } (1, 2);
	my $other = { QUERY_STRING => 'z=9', REQUEST_URI => '/cgi-bin/page.fcgi?z=9' };

	request(output => $page{1}, init => { cache => cache(), save_to => $save_to });
	my ($file) = static_pages($docroot);
	like(slurp($file), qr/Version 1/, 'is saved');

	# A link to it is rewritten whilst it's live
	my $link = qq{Content-type: text/html\n\n<html><body><a href="$ENV{REQUEST_URI}">a</a></body></html>\n};
	my (undef, $body) = request(output => $link, env => $other, init => { cache => cache(), save_to => $save_to });
	like($body, qr{<a href="/static/}, 'a link goes to the static page');

	my $dbh = database($save_to);
	$dbh->do('UPDATE fcgi_buffer SET creation = creation - 99999');

	my $headers;
	(undef, $body) = request(output => $link, env => $other, init => { cache => cache(), save_to => $save_to });
	unlike($body, qr{<a href="/static/}, 'after the ttl a link goes to the script');
	ok(!-e $file, 'and the page has gone');
	my ($count) = $dbh->selectrow_array('SELECT COUNT(*) FROM fcgi_buffer WHERE path = ?', undef, $file);
	is($count, 0, 'as has its row');

	($headers) = request(output => $page{2}, init => { cache => cache(), save_to => $save_to });
	like(slurp($file), qr/Version 2/, 'the next request saves it again');

	# The row is found by the page itself, with no other page to clean it up
	$dbh->do('UPDATE fcgi_buffer SET creation = creation - 99999');
	request(output => $page{1}, init => { cache => cache(), save_to => $save_to });
	like(slurp($file), qr/Version 1/, 'and again');

	($headers) = request(
		output => qq{Content-type: text/html\n\n<html><body><a href="$ENV{REQUEST_URI}">self</a></body></html>\n},
		init => { cache => cache(), save_to => $save_to }
	);
	my ($expires) = $headers =~ /^Expires: (.+?)\r?$/m;
	ok(defined($expires), 'it is sent with an Expires header');
	cmp_ok(HTTP::Date::str2time($expires), '>', time, 'which is in the future');

	# A ttl of 0 is forever
	($docroot, $save_to) = setup();
	$save_to->{'ttl'} = 0;
	request(output => $page{1}, init => { cache => cache(), save_to => $save_to });
	$dbh = database($save_to);
	$dbh->do('UPDATE fcgi_buffer SET creation = creation - 99999');
	request(output => $page{2}, init => { cache => cache(), save_to => $save_to });
	($file) = static_pages($docroot);
	like(slurp($file), qr/Version 1/, 'a ttl of 0 is never replaced');
};

subtest 'a link to a static page which has been deleted' => sub {
	my ($docroot, $save_to) = setup();
	request(output => $PAGE, init => { cache => cache(), save_to => $save_to });
	my ($file) = static_pages($docroot);
	unlink $file;

	my $logger = My::Logger->new();
	my (undef, $body) = request(
		output => qq{Content-type: text/html\n\n<html><body><a href="$ENV{REQUEST_URI}">a</a></body></html>\n},
		env => { QUERY_STRING => 'z=9', REQUEST_URI => '/cgi-bin/page.fcgi?z=9' },
		init => { cache => cache(), save_to => $save_to, logger => $logger }
	);
	like($body, qr{<a href="/cgi-bin/page\.fcgi\?a=1">}, 'the link goes to the script');
	like($logger->{warnings}->[0], qr/Remove entry/, 'and it is logged');
	my ($count) = database($save_to)->selectrow_array('SELECT COUNT(*) FROM fcgi_buffer WHERE path = ?', undef, $file);
	is($count, 0, 'and the row has gone');
};

subtest 'virtual hosts sharing a directory' => sub {
	my ($docroot, $save_to) = setup();
	my $page_on = sub { "Content-type: text/html\n\n<html><body>Site $_[0]</body></html>\n" };

	request(output => $page_on->('A'), env => { HTTP_HOST => 'a.example' }, init => { cache => cache(), save_to => $save_to });

	my (undef, $body) = request(
		output => qq{Content-type: text/html\n\n<html><body><a href="$ENV{REQUEST_URI}">a</a></body></html>\n},
		env => { HTTP_HOST => 'b.example', QUERY_STRING => 'z=1', REQUEST_URI => '/cgi-bin/page.fcgi?z=1' },
		init => { cache => cache(), save_to => $save_to }
	);
	like($body, qr{<a href="/cgi-bin/page\.fcgi\?a=1">}, "B doesn't link to A's static page");

	request(output => $page_on->('B'), env => { HTTP_HOST => 'b.example' }, init => { cache => cache(), save_to => $save_to });
	my @pages = grep { !/z=1/ } static_pages($docroot);
	is(scalar(@pages), 2, 'each has its own file');
	is_deeply([ sort map { slurp($_) =~ /Site (\w)/ } @pages ], [ 'A', 'B' ], 'and neither has replaced the other');

	(undef, $body) = request(
		output => qq{Content-type: text/html\n\n<html><body><a href="$ENV{REQUEST_URI}">a</a></body></html>\n},
		env => { HTTP_HOST => 'b.example', QUERY_STRING => 'z=2', REQUEST_URI => '/cgi-bin/page.fcgi?z=2' },
		init => { cache => cache(), save_to => $save_to }
	);
	ok($body =~ m{<a href="(/static/[^"]+)">}, "B does link to its own page") or return;
	like(slurp($docroot . $1), qr/Site B/, 'which is the right one');
};

subtest 'only HTML is saved' => sub {
	my ($docroot, $save_to) = setup();
	my $png = "\x89PNG\r\n\x1a\n" . join('', map { chr } 0..255);
	my $cache = cache();
	my (undef, $body) = request(output => "Content-type: image/png\r\n\r\n$png", init => { cache => $cache, save_to => $save_to });
	is(scalar(static_pages($docroot)), 0, 'a PNG is not saved');
	is($body, $png, 'and is sent untouched');

	request(output => qq{Content-type: application/json\n\n{"a":"<a href=\\"/x\\">"}}, init => { cache => cache(), save_to => $save_to });
	is(scalar(static_pages($docroot)), 0, 'nor is JSON');
};

subtest 'without a cache no static pages are written' => sub {
	my ($docroot, $save_to) = setup();
	request(output => $PAGE, init => { save_to => $save_to });
	is(scalar(static_pages($docroot)), 0, 'as documented');
};

subtest 'max_pages' => sub {
	my ($docroot, $save_to) = setup();
	$save_to->{'max_pages'} = 3;
	my $logger = My::Logger->new();
	my $cache = cache();
	foreach my $i(1..5) {
		request(
			output => $PAGE,
			env => { QUERY_STRING => "n=$i", REQUEST_URI => "/cgi-bin/page.fcgi?n=$i" },
			init => { cache => $cache, save_to => $save_to, logger => $logger }
		);
	}
	is(scalar(static_pages($docroot)), 3, 'no more than the limit are written');
	like($logger->{warnings}->[0], qr/limit of 3 pages/, 'and it is logged');

	# Old ones can still be replaced, once they've expired
	database($save_to)->do('UPDATE fcgi_buffer SET creation = creation - 99999');
	request(output => $PAGE, init => { cache => cache(), save_to => $save_to });
	is(scalar(static_pages($docroot)), 1, 'making space when they expire');

	($docroot, $save_to) = setup();
	$save_to->{'max_pages'} = 0;
	foreach my $i(1..2) {
		request(output => $PAGE, env => { QUERY_STRING => "n=$i", REQUEST_URI => "/cgi-bin/page.fcgi?n=$i" }, init => { cache => cache(), save_to => $save_to });
	}
	is(scalar(static_pages($docroot)), 2, '0 is no limit');
};

subtest 'optimise_content leaves <pre> and <textarea> alone' => sub {
	my $pre = "<pre class=\"c\">  a\n    b\n\n  c</pre>";
	my $textarea = "<TEXTAREA name=\"t\">\n   x\n\n   y  z\n</TEXTAREA>";
	foreach my $level(1, 2) {
		my (undef, $body) = request(
			output => "Content-type: text/html\n\n<html><body><p>  one  </p>\n\n$pre\n  <div>  two </div>\n$textarea</body></html>\n",
			init => { optimise_content => $level }
		);
		like($body, qr/\Q$pre\E/, "level $level: <pre>");
		like($body, qr/\Q$textarea\E/, "level $level: <textarea>");
		like($body, qr/<p>one<\/p>/, "level $level: the rest is still optimised");
		unlike($body, qr/FCGIBUFFER/, "level $level: the marker has gone");
	}

	my (undef, $body) = request(
		output => "Content-type: text/html\n\n<html><body><pre>not closed  <textarea>nor this</body></html>\n",
		init => { optimise_content => 1 }
	);
	like($body, qr/not closed/, 'an unterminated tag does no harm');
};

subtest 'bad cached data' => sub {
	require Storable;

	my $logger = My::Logger->new();
	my ($docroot, $save_to) = setup();
	my $cache = cache();
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	request(output => $PAGE, init => { cache => $cache, save_to => $save_to, cache_key => 'key' });
	ok(scalar(static_pages($docroot)), 'there is a static page');
	$cache->set('key', Storable::freeze({ headers => 'Content-type: text/html' }), '1 hour');

	my ($hit, $headers, $body) = is_hit(cache => $cache, init => { cache_key => 'key', save_to => $save_to, logger => $logger });
	ok($hit, 'it seems to be in the cache');
	like($headers, qr/^Status: 500/m, 'the body is missing, so that is an error');
	ok(!defined($cache->get('key')), 'it is removed from the cache');
	is(scalar(static_pages($docroot)), 0, 'and so is the static page');
};

subtest 'the debug log of what changed' => sub {
	FCGI::Buffer::_can_load('Text::Diff') or return plan(skip_all => 'Text::Diff is not installed');

	my $logger = My::DebugLogger->new();
	my $cache = cache();
	request(output => $PAGE, init => { cache => $cache, cache_key => 'key' });
	request(
		output => "Content-type: text/html\n\n<html><body>Changed</body></html>\n",
		env => { HTTP_IF_NONE_MATCH => '"other"' },
		init => { cache => $cache, cache_key => 'key', logger => $logger }
	);
	ok(grep({ /^diffs: / } @{$logger->{debug}}), 'the differences are logged');
};

subtest 'a save_to outside of the document root is reported by a logger' => sub {
	my $docroot = tempdir(CLEANUP => 1);
	my $elsewhere = tempdir(CLEANUP => 1);
	local $ENV{'DOCUMENT_ROOT'} = $docroot;
	my $logger = My::Logger->new();
	my ($headers, $body) = request(output => $PAGE, init => { cache => cache(), logger => $logger, save_to => { directory => $elsewhere } });
	like($logger->{warnings}->[0], qr/not under the document root/, 'it is logged');
	like($body, qr/<\/html>/, 'and the page is sent');
	is(scalar(static_pages($elsewhere)), 0, 'with no static page');
};

subtest 'Last-Modified' => sub {
	my ($headers) = request(output => $PAGE);
	like($headers, qr/^Last-Modified: /m, 'comes from the script when there is no cache');
	($headers) = request(output => $PAGE, init => { cache => cache() });
	like($headers, qr/^Last-Modified: /m, 'and from the cache when there is one');
};

subtest 'NO_CACHE and NO_STORE' => sub {
	foreach my $name('NO_CACHE', 'NO_STORE') {
		foreach my $value(1, 0) {
			local $ENV{$name} = $value;
			my $b = FCGI::Buffer->new();
			select($b->{old_buf});
			ok(!$b->can_cache(), "$name=$value stops the cache being used");
			delete $b->{buf};
		}
	}
};
