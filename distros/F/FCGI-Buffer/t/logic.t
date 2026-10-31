#!perl -w

# Equivalence partition tests for the decisions made by FCGI::Buffer.
# Each test is one partition, or the boundary between two, of a decision; values
# which fall in a partition that's already tested aren't tested again.

use strict;
use warnings;
use Test::Most tests => 17;
use Test::Needs 'CHI';
use Capture::Tiny ':all';
use CGI::Info;
use Compress::Zlib;
use HTTP::Date;
use File::Temp;
use Readonly;
use Test::NoWarnings;

BEGIN {
	use_ok('FCGI::Buffer');
}

# A minimal stand-in for CGI::Info
package My::Info;

sub new { return bless { status => 200 }, shift }
sub host_name { return 'www.example.com' }
sub status { my $self = shift; $self->{status} = shift if(@_); return $self->{status} }

package main;

Readonly::Scalar my $ETAG => '"0123456789abcdef0123456789abcdef"';

delete @ENV{qw(
	HTTP_ACCEPT_ENCODING HTTP_TE SERVER_PROTOCOL HTTP_RANGE Range HTTP_USER_AGENT
	REMOTE_ADDR HTTP_IF_NONE_MATCH HTTP_IF_MODIFIED_SINCE HTTP_COOKIE
	HTTP_CACHE_CONTROL NO_CACHE NO_STORE REQUEST_URI PATH_INFO
)};
$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
$ENV{'REQUEST_METHOD'} = 'GET';
$ENV{'QUERY_STRING'} = '';

# An object for testing internal methods.  Output is switched back to STDOUT,
# and the buffer is removed when it's destroyed, so that nothing is printed
package My::Buffer;

our @ISA = ('FCGI::Buffer');

sub DESTROY {
	my $self = shift;
	delete $self->{buf};
	$self->SUPER::DESTROY();
}

package main;

sub buffer {
	my %fields = @_;

	my $b = My::Buffer->new();
	select($b->{old_buf});
	$b->{o} = [];
	@{$b}{keys %fields} = values %fields;
	return $b;
}

subtest 'new(): invalid calls are refused' => sub {
	my $rc;
	warning_like { $rc = FCGI::Buffer::new() } qr/use ->new\(\) not ::new\(\)/, 'function call warns';
	ok(!defined($rc), 'and returns undef');

	warning_like { $rc = FCGI::Buffer->new('odd') } qr/Invalid arguments/, 'odd number of arguments warns';
	ok(!defined($rc), 'and returns undef');
};

subtest 'new(): generate_etag defaults from the protocol' => sub {
	foreach my $test(
		[ undef, 0 ],
		[ 'HTTP/1.0', 0 ],
		[ 'HTTP/1.1', 1 ],
		[ 'HTTP/2.0', 1 ],
		[ 'HTTP/1.10', 0 ],	# Boundary: must be anchored
	) {
		my ($protocol, $expect) = @{$test};
		local $ENV{'SERVER_PROTOCOL'} = $protocol;
		is(buffer()->{generate_etag}, $expect, defined($protocol) ? $protocol : 'no protocol');
	}

	local $ENV{'SERVER_PROTOCOL'} = 'HTTP/1.1';
	my $b;
	capture {
		$b = FCGI::Buffer->new(generate_etag => 0);
		select($b->{old_buf});
		delete $b->{buf};
	};
	is($b->{generate_etag}, 0, 'an explicit generate_etag is not overridden');
};

subtest 'can_cache()' => sub {
	foreach my $test(
		[ {}, 1, 'nothing forbids it' ],
		[ { NO_CACHE => 0 }, 0, 'NO_CACHE is set, even to false' ],
		[ { NO_STORE => '' }, 0, 'NO_STORE is set' ],
		[ { HTTP_CACHE_CONTROL => 'no-store' }, 0, 'no-store' ],
		[ { HTTP_CACHE_CONTROL => 'no-cache' }, 0, 'no-cache' ],
		[ { HTTP_CACHE_CONTROL => 'private' }, 0, 'private' ],
		[ { HTTP_CACHE_CONTROL => 'max-age=0' }, 0, 'max-age=0' ],
		[ { HTTP_CACHE_CONTROL => 'max-age=1' }, 1, 'boundary: max-age=1' ],
		[ { HTTP_CACHE_CONTROL => 'No-Cache' }, 0, 'directives are case insensitive' ],
		[ { HTTP_CACHE_CONTROL => 'max-age=60, no-cache' }, 0, 'any one of several directives' ],
	) {
		my ($env, $expect, $name) = @{$test};
		local @ENV{keys %{$env}} = values %{$env};
		my $b = buffer();
		is($b->can_cache(), $expect, $name);
		is($b->{x_cache}, $expect ? 'HIT' : 'MISS', "$name: X-Cache");
	}

	# Invariant: the answer doesn't change during a request
	my $b = buffer();
	ok($b->can_cache(), 'cacheable');
	local $ENV{'NO_CACHE'} = 1;
	ok($b->can_cache(), 'and stays so');
};

subtest 'init()' => sub {
	my $b = buffer();
	$b->init(optimise_content => 2, lint_content => 1, generate_304 => 0, compress_content => undef);
	is($b->{optimise_content}, 2, 'option is set');
	is($b->{lint_content}, 1, 'option is set');
	is($b->{generate_304}, 0, 'false option is set');
	is($b->{compress_content}, 1, 'undef option is ignored');

	my $cache = CHI->new(driver => 'Memory', datastore => {});
	{
		local $ENV{'HTTP_CACHE_CONTROL'} = 'max-age = 60';
		$b->init(cache => $cache, cache_duration => '1 hour');
	}
	is($b->{cache}, $cache, 'cache is set');
	is($b->{cache_duration}, '60 seconds', "the client's max-age wins");

	$b->init(cache => undef);
	ok(!exists($b->{cache}), 'cache => undef turns the cache off');
};

subtest '_should_gzip()' => sub {
	no warnings 'redefine';
	local *FCGI::Buffer::_can_load = sub { return $_[0] eq 'Compress::Zlib' };

	foreach my $test(
		[ {}, undef, '', 'client accepts nothing' ],
		[ { HTTP_ACCEPT_ENCODING => 'gzip' }, undef, 'gzip', 'Accept-Encoding' ],
		[ { HTTP_TE => 'gzip' }, undef, 'gzip', 'TE' ],
		[ { HTTP_ACCEPT_ENCODING => 'deflate' }, undef, '', 'unsupported encoding' ],
		[ { HTTP_ACCEPT_ENCODING => 'GZIP' }, undef, 'gzip', 'case insensitive' ],
		[ { HTTP_ACCEPT_ENCODING => 'gzip;q=0, x-gzip' }, undef, 'x-gzip', 'q=0 is not acceptable' ],
		[ { HTTP_ACCEPT_ENCODING => 'gzip;q=0.001' }, undef, 'gzip', 'boundary: smallest q above 0' ],
		[ { HTTP_ACCEPT_ENCODING => 'br, gzip' }, undef, 'gzip', 'an encoding that can not be loaded is skipped' ],
		[ { HTTP_ACCEPT_ENCODING => 'gzip' }, ['image', 'png'], '', 'only text is compressed' ],
		[ { HTTP_ACCEPT_ENCODING => 'gzip' }, ['Text', 'html'], 'gzip', 'content type is case insensitive' ],
	) {
		my ($env, $content_type, $expect, $name) = @{$test};
		local @ENV{keys %{$env}} = values %{$env};
		is(buffer(content_type => $content_type)->_should_gzip(), $expect, $name);
	}

	local $ENV{'HTTP_ACCEPT_ENCODING'} = 'gzip';
	is(buffer(compress_content => 0)->_should_gzip(), '', 'compress_content => 0');
};

subtest '_compress()' => sub {
	my $text = 'The quick brown fox jumped over the lazy dog. ' x 10;

	foreach my $encoding(undef, '') {
		my $b = buffer(body => $text);
		$b->_compress(encoding => $encoding);
		is($b->{body}, $text, 'no encoding: unchanged');
	}

	my $b = buffer(body => 'x' x 31);
	$b->_compress(encoding => 'gzip');
	is($b->{body}, 'x' x 31, 'boundary: one byte under the minimum is not compressed');

	$b = buffer(body => 'x' x 32);
	$b->_compress(encoding => 'gzip');
	is(Compress::Zlib::memGunzip($b->{body}), 'x' x 32, 'boundary: the minimum is compressed');

	$b = buffer(body => $text, info => My::Info->new(), o => ['Vary: Accept-Encoding']);
	$b->_compress(encoding => 'x-gzip');
	is(Compress::Zlib::memGunzip($b->{body}), $text, 'x-gzip is gzip');
	is_deeply($b->{o}, ['Vary: Accept-Encoding', 'Content-Encoding: gzip'], 'headers are added once');

	# Random bytes don't compress
	my $random = join('', map { chr(int(rand(256))) } 1..64);
	$b = buffer(body => $random);
	$b->_compress(encoding => 'gzip');
	is($b->{body}, $random, 'not compressed when it would get bigger');
	is_deeply($b->{o}, [], 'and no headers');

	$b = buffer(body => $text, info => My::Info->new());
	$b->_compress(encoding => 'deflate');
	is($b->{status}, 406, 'unsupported encoding is a 406');
	is($b->{info}->status(), 406, 'and CGI::Info is told');
};

subtest '_apply_range()' => sub {
	my $body = join('', 0..9);
	my $partial = sub { return { status => 206, body => $_[0], content_range => "bytes $_[1]/10" } };
	my $unsatisfiable = { status => 416, content_range => 'bytes */10' };

	foreach my $test(
		[ 'bytes=0-0', $partial->('0', '0-0'), 'boundary: a single byte' ],
		[ 'bytes=2-5', $partial->('2345', '2-5'), 'includes both ends' ],
		[ 'bytes=7-', $partial->('789', '7-9'), 'open ended' ],
		[ 'bytes=8-20', $partial->('89', '8-9'), 'end past the end of the body stops at the end' ],
		[ 'bytes=-3', $partial->('789', '7-9'), 'suffix is the last bytes' ],
		[ 'bytes=-10', $partial->($body, '0-9'), 'boundary: suffix of the whole body' ],
		[ 'bytes=-11', $partial->($body, '0-9'), 'boundary: suffix longer than the body' ],
		[ 'bytes=9-', $partial->('9', '9-9'), 'boundary: starts at the last byte' ],
		[ 'bytes=10-', $unsatisfiable, 'boundary: starts after the end' ],
		[ 'bytes=10-12', $unsatisfiable, 'closed range after the end' ],
		[ 'bytes=-0', $unsatisfiable, 'boundary: empty suffix' ],
		[ 'bytes=5-4', undef, 'boundary: backwards is ignored' ],
		[ 'bytes=20-5', undef, 'backwards after the end is ignored, not 416' ],
		[ 'bytes=-', undef, 'no numbers' ],
		[ 'bytes=0-1,3-4', undef, 'multiple ranges' ],
		[ 'items=0-1', undef, 'other units' ],
	) {
		my ($range, $expect, $name) = @{$test};
		is_deeply(scalar(FCGI::Buffer::_apply_range($body, $range)), $expect, "$range: $name");
	}

	is_deeply(FCGI::Buffer::_apply_range('', 'bytes=-5'), { status => 416, content_range => 'bytes */0' }, 'any suffix of an empty body is unsatisfiable');
};

subtest 'Range responses' => sub {
	my $text = join('', 'a'..'z');

	my $request = sub {
		my $range = shift;
		local $ENV{'HTTP_RANGE'} = $range;
		my ($stdout, $stderr) = capture {
			my $b = FCGI::Buffer->new();
			$b->init(generate_etag => 0);
			print "Content-type: text/plain\n\n$text";
		};
		my ($headers, $body) = split /\r?\n\r?\n/, $stdout, 2;
		return ($headers, $body, $stderr);
	};

	my ($headers, $body, $stderr) = $request->('bytes=-5');
	is($stderr, '', 'no errors');
	like($headers, qr/^Status: 206 /m, '206 status');
	like($headers, qr/^Content-Range: bytes 21-25\/26\r?$/m, 'Content-Range');
	is($body, 'vwxyz', 'the last 5 bytes');

	($headers, $body, $stderr) = $request->('bytes=26-');
	is($stderr, '', 'no errors');
	like($headers, qr/^Status: 416 /m, '416 status');
	like($headers, qr/^Content-Range: bytes \*\/26\r?$/m, 'Content-Range gives the length');
	unlike($headers, qr/^Content-Length: [1-9]/m, 'no Content-Length');
	ok(!defined($body) || ($body eq ''), 'no body');
};

subtest '_check_if_none_match()' => sub {
	foreach my $test(
		[ undef, 0, 'no If-None-Match' ],
		[ $ETAG, 1, 'matches' ],
		[ '"other"', 0, 'does not match' ],
		[ "\"other\", $ETAG", 1, 'in a list' ],
		[ "W/$ETAG", 1, 'weak ETag' ],
		[ '*', 1, 'any' ],
	) {
		my ($header, $expect, $name) = @{$test};
		local $ENV{'HTTP_IF_NONE_MATCH'} = $header;
		my $b = buffer(etag => $ETAG, send_body => 1, status => 200);
		is($b->_check_if_none_match(), $expect, $name);
		is($b->{status}, $expect ? 304 : 200, "$name: status");
		is($b->{send_body}, $expect ? 0 : 1, "$name: send_body");
	}

	local $ENV{'HTTP_IF_NONE_MATCH'} = $ETAG;
	is(buffer()->_check_if_none_match(), 0, 'no ETag of our own, and no warning');
};

subtest '_check_modified_since()' => sub {
	my $now = time;

	foreach my $test(
		[ { generate_304 => 0 }, HTTP::Date::time2str($now), $now, 200, 'generate_304 is off' ],
		[ {}, undef, $now, 200, 'no date' ],
		[ {}, 'not a date', $now, 200, 'invalid date' ],
		[ { script_mtime => $now + 1 }, HTTP::Date::time2str($now), $now - 10, 200, 'script is newer than the date' ],
		[ {}, HTTP::Date::time2str($now), $now, 304, 'boundary: modified at the date' ],
		[ {}, HTTP::Date::time2str($now), $now + 1, 200, 'boundary: modified after the date' ],
	) {
		my ($fields, $since, $modified, $expect, $name) = @{$test};
		my $b = buffer(status => 200, send_body => 1, script_mtime => $now - 100, %{$fields});
		$b->_check_modified_since({ since => $since, modified => $modified });
		is($b->{status}, $expect, $name);
	}
};

subtest '_x_cache_headers()' => sub {
	is_deeply(buffer()->_x_cache_headers('HIT', 'MISS'), ['X-Cache: HIT', 'X-Cache-Lookup: MISS'], 'without CGI::Info');
	is_deeply(
		buffer(info => My::Info->new())->_x_cache_headers('MISS', 'MISS'),
		['X-Cache: MISS from www.example.com', 'X-Cache-Lookup: MISS from www.example.com'],
		'with CGI::Info'
	);
};

subtest 'optimise_content: document.write merging terminates' => sub {
	my $writes = join('', map { "document.write($_);" } 1..20);
	my ($stdout) = capture {
		my $b = FCGI::Buffer->new();
		$b->init(optimise_content => 2, generate_etag => 0);
		print "Content-type: text/html\n\n", qq{<html><body><script type="text/javascript">$writes</script></body></html>};
	};
	like($stdout, qr/document\.write\(1\+2\+3\+.*\+20\)/, 'all calls are merged into one');
};

subtest 'HEAD requests have no body' => sub {
	foreach my $test([ 'GET', 1 ], [ 'HEAD', 0 ]) {
		my ($method, $has_body) = @{$test};
		local $ENV{'REQUEST_METHOD'} = $method;
		my ($stdout) = capture {
			my $b = FCGI::Buffer->new();
			$b->init(generate_etag => 0);
			print "Content-type: text/plain\n\nhello\n";
		};
		my (undef, $body) = split /\r?\n\r?\n/, $stdout, 2;
		is(($body =~ /hello/) ? 1 : 0, $has_body, $method);
	}
};

subtest "an ETag in the script's own headers gives a 304 when cached" => sub {
	my $cache = CHI->new(driver => 'Memory', datastore => {});
	local $ENV{'SERVER_PROTOCOL'} = 'HTTP/1.1';

	my $request = sub {
		my ($stdout) = capture {
			my $b = FCGI::Buffer->new();
			$b->init(cache => $cache, cache_key => 'etag', generate_etag => 0, info => CGI::Info->new());
			if(!$b->is_cached()) {
				print "Content-type: text/plain\nETag: $ETAG\n\n", 'x' x 100;
			}
		};
		return $stdout;
	};

	$request->();
	local $ENV{'HTTP_IF_NONE_MATCH'} = $ETAG;
	like($request->(), qr/^Status: 304/m, '304 Not Modified');
};

subtest 'save_to TTL defaults' => sub {
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	my $b = buffer();
	my $save_to = { directory => $dir };
	$b->init(save_to => $save_to);
	is($b->{save_to}->{ttl}, 600, 'ttl defaults to 10 minutes');

	$b = buffer();
	$b->init(save_to => { directory => $dir, ttl => 0 });
	is($b->{save_to}->{ttl}, 0, 'boundary: ttl of 0 (forever) is kept');
};
