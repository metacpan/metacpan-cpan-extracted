#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The test reaches no network. Every fetch goes to a server on the
# loopback interface, and that server answers with a canned response.
#
# A host holds one of the three commands, and the CI runner holds
# curl and wget. The fetch subtests therefore run for each command
# that PATH holds, and the argument subtests use a stub under the
# name of a command, so all three dialects stay readable everywhere.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);
use Test::More;
use File::Basename qw(basename dirname);
use File::Temp     qw(tempdir);
use FindBin        qw($RealBin);
use IO::Socket::INET;
use POSIX ();
use lib "$RealBin/../../lib";

use_ok('Fugu::Curl');
use Fugu::Process;

my $dir = tempdir( CLEANUP => 1 );

# The canned answers. The token {PORT} takes the port of the server,
# so a redirect can name the server itself.
my $OK       = "HTTP/1.0 200 OK\r\nContent-Length: 6\r\n\r\nhello\n";
my $MISSING  = "HTTP/1.0 404 Not Found\r\nContent-Length: 10\r\n\r\nnot here\r\n";
my $REDIRECT = "HTTP/1.0 302 Found\r\n"
    . "Location: http://127.0.0.1:{PORT}/final\r\n"
    . "Content-Length: 0\r\n\r\n";

my $stubs = 0;

# stub($name, $body):
#	Write an executable stub under $name, in a directory of its
#	own, and return its path. The module reads the base name of a
#	command as its dialect, so a stub named wget drives the wget
#	dialect on a host that has no wget.
sub stub ( $name, $body = "#!/bin/sh\nexit 7\n" )
{
	my $bin = "$dir/stub" . ++$stubs;
	mkdir $bin or die "Cannot create $bin: $!";

	my $path = "$bin/$name";
	open my $fh, '>', $path or die "Cannot write $path: $!";
	print {$fh} $body;
	close $fh or die "Cannot close $path: $!";
	chmod 0755, $path or die "Cannot chmod $path: $!";

	return $path;
}

# listener():
#	A listening socket on the loopback interface, on a port that
#	the kernel picks.
sub listener ()
{
	return IO::Socket::INET->new(
		LocalAddr => '127.0.0.1',
		LocalPort => 0,
		Listen    => 5,
		Proto     => 'tcp',
		ReuseAddr => 1,
	) || die "Cannot listen on the loopback interface: $!";
}

# server(@responses):
#	Start a server that answers each request with the next
#	response, and return its pid and its port. The caller stops
#	it with Fugu::Process->terminate.
sub server (@responses)
{
	my $listen = listener();
	my $port   = $listen->sockport;

	my $pid = fork;
	die "Cannot fork: $!" unless defined $pid;

	if ( $pid == 0 ) {
		for my $response (@responses) {
			my $client = $listen->accept or last;

			# Read the request head, up to the blank line.
			while ( my $line = <$client> ) {
				last if $line =~ /\A\r?\n\z/;
			}

			$response =~ s/\{PORT\}/$port/g;
			print {$client} $response;
			close $client;
		}

		# _exit, so the child runs no END block of Test::More
		# and writes no second plan.
		POSIX::_exit(0);
	}

	close $listen;
	return ( $pid, $port );
}

# closed_port():
#	A port on the loopback interface that no program listens on.
sub closed_port ()
{
	my $listen = listener();
	my $port   = $listen->sockport;
	close $listen;

	return $port;
}

# body($path):
#	The bytes of a file, or undef.
sub body ($path)
{
	open my $fh, '<', $path or return;
	binmode $fh;

	return do { local $/; <$fh> };
}

# leftovers($path):
#	Every temporary sibling that a fetch of $path can leave.
sub leftovers ($path)
{
	my $parent = dirname($path);
	my $base   = basename($path);

	return glob "$parent/.$base.*";
}

# --- the subtests that need no command ------------------------------------

subtest 'the constants hold the documented values' => sub {
	is( Fugu::Curl::DEFAULT_TIMEOUT(), 600, 'the default timeout is 600' );
	is( Fugu::Curl::PROCESS_MARGIN(),
		30, 'the process bound holds 30 seconds above the flag' );
	is( Fugu::Curl::CURL_TIMEOUT_EXIT(),
		28, 'the curl timeout exit code is 28' );
	is_deeply(
		[ Fugu::Curl::COMMANDS() ],
		[qw(curl wget ftp)],
		'the search order is curl, wget, ftp'
	);
};

subtest 'an empty PATH resolves nothing' => sub {
	local $ENV{PATH} = '';

	my $curl = Fugu::Curl->new;
	is( $curl->is_available, 0,     'is_available returns 0' );
	is( $curl->command,      undef, 'command returns undef' );
	is( $curl->status,       undef, 'status is undef before a fetch' );
	like( $curl->error, qr/curl, wget, ftp/,
		'error names the search list' );

	my $path = "$dir/absent-command";
	is( $curl->arguments( 'http://127.0.0.1:1/x', $path ),
		undef, 'arguments returns undef' );
	is( $curl->fetch( 'http://127.0.0.1:1/x', $path ),
		undef, 'fetch returns undef' );
	is( $curl->status, 'absent', 'the status is absent' );
	like( $curl->error, qr{\Qhttp://127.0.0.1:1/x\E},
		'the reason names the URL' );
	ok( !-e $path, 'no file appears at the destination' );
};

subtest 'a command that the module cannot drive is a clean failure' => sub {
	my $absent = Fugu::Curl->new( command => "$dir/no-such-curl" );
	is( $absent->is_available, 0, 'an absent path gives 0' );
	like( $absent->error, qr{\Q$dir/no-such-curl\E},
		'error names the path' );

	my $wrong =
	    Fugu::Curl->new( command => stub('fugu-not-a-downloader') );
	is( $wrong->is_available, 0, 'an executable of another name gives 0' );
	like( $wrong->error, qr/not a known downloader/,
		'error names the reason' );
};

subtest 'arguments holds the flag set of each dialect' => sub {
	my $url = 'https://example.org/dl/asset.tgz';
	my $tmp = "$dir/.asset.tgz.1";

	my %expected = (
		curl => [
			'--fail',       '--location',
			'--silent',     '--show-error',
			'--max-time',   42,
			'--output',     $tmp,
			'--write-out',  '%{http_code}',
			$url,
		],
		wget => [
			'--no-verbose', '--tries=1',
			'--timeout=42', "--output-document=$tmp",
			$url,
		],
		ftp => [ '-V', '-M', '-w', 42, '-o', $tmp, $url ],
	);

	for my $name ( Fugu::Curl::COMMANDS() ) {
		my $path = stub($name);
		my $curl = Fugu::Curl->new( command => $path, timeout => 42 );

		is( $curl->is_available, 1, "a stub named $name resolves" );
		is_deeply(
			$curl->arguments( $url, $tmp ),
			[ $path, @{ $expected{$name} } ],
			"$name takes its own flag set"
		);
	}
};

subtest 'the default timeout reaches the flag of the command' => sub {
	my $curl = Fugu::Curl->new( command => stub('curl') );
	my $args = $curl->arguments( 'https://example.org/a', "$dir/t" );

	ok( scalar( grep { $_ eq '600' } @$args ),
		'the argument list holds the default bound' );
};

subtest 'no argument list turns the TLS check off' => sub {

	# Each command verifies the certificate of the peer by
	# default, and one flag would undo it: -k and --insecure for
	# curl, --no-check-certificate for wget, and -S for the ftp
	# of OpenBSD.
	my @unsafe = qw(
	    -k -S --insecure --no-check-certificate --no-verify-peer
	    --proxy-insecure --ssl-no-revoke
	);

	for my $name ( Fugu::Curl::COMMANDS() ) {
		my $curl = Fugu::Curl->new( command => stub($name) );
		my $args =
		    $curl->arguments( 'https://example.org/a', "$dir/t" );

		for my $flag (@unsafe) {
			ok( !scalar( grep { $_ eq $flag } @$args ),
				"$name passes no $flag" );
		}
	}
};

subtest 'the module reads the HTTP status of each dialect' => sub {
	is( Fugu::Curl::_http_code( 'curl', { stdout => "404\n" } ),
		404, 'curl reports the status on standard output' );
	is( Fugu::Curl::_http_code( 'curl', { stdout => '000' } ),
		undef, 'the curl report 000 is no status' );
	is(
		Fugu::Curl::_http_code(
			'wget',
			{
				stderr => "http://127.0.0.1:1/x:\n"
				    . '2026-09-10 10:00:00 '
				    . "ERROR 404: Not Found.\n"
			} ),
		404,
		'wget names the status in its diagnostic'
	);
	is(
		Fugu::Curl::_http_code(
			'ftp',
			{
				stderr => 'ftp: Error retrieving file: '
				    . "404 Not Found\n"
			} ),
		404,
		'the ftp of OpenBSD names the status in its diagnostic'
	);
	is(
		Fugu::Curl::_http_code(
			'wget', { stderr => 'failed: Connection refused.' } ),
		undef,
		'a connection failure holds no status'
	);
};

subtest '_last_line takes the reason out of a diagnostic' => sub {
	is( Fugu::Curl::_last_line("one\ntwo\n"),
		'two', 'the last line holds the reason' );
	is( Fugu::Curl::_last_line("only\n\n"),
		'only', 'a trailing blank line drops' );
	is( Fugu::Curl::_last_line(undef),
		'', 'an absent diagnostic gives the empty string' );
};

subtest '_temp_name names a hidden sibling of the destination' => sub {
	my $temp = Fugu::Curl::_temp_name("$dir/asset.tgz");
	like( $temp, qr{\A\Q$dir\E/\.asset\.tgz\.},
		'the name sits in the directory of the destination' );
};

subtest 'a command that leaves a partial file leaves nothing behind' => sub {

	# curl removes its own output file on a failure, and wget
	# leaves one. The stub therefore writes a partial file and
	# reports a 404, in the diagnostic form of wget.
	my $path = stub( 'wget', <<'SH' );
#!/bin/sh
for arg in "$@"; do
	case "$arg" in
	--output-document=*) out="${arg#--output-document=}" ;;
	esac
done
printf 'partial' > "$out"
echo "http://example.org/a:" >&2
echo "2026-09-10 10:00:00 ERROR 404: Not Found." >&2
exit 8
SH

	my $dest = "$dir/partial";
	my $curl = Fugu::Curl->new( command => $path );

	is( $curl->fetch( 'http://example.org/a', $dest ),
		undef, 'fetch returns undef' );
	is( $curl->status, 'http', 'the status is http' );
	is( $curl->code,   404,    'the code is 404' );
	ok( !-e $dest, 'no file appears at the destination' );
	is_deeply( [ leftovers($dest) ],
		[], 'the module removed the partial file' );
};

subtest 'a rename that fails leaves nothing behind' => sub {

	# rename(2) refuses a directory as the destination of a file.
	# The stub writes the temporary file and exits 0, so the fetch
	# reaches the rename, and the rename fails.
	my $path = stub( 'curl', <<'SH' );
#!/bin/sh
out=
while [ $# -gt 0 ]; do
	case "$1" in
	--output) out="$2"; shift ;;
	esac
	shift
done
printf 'bytes' > "$out"
exit 0
SH

	my $dest = "$dir/rename-target";
	mkdir $dest or die "Cannot create $dest: $!";

	my $curl = Fugu::Curl->new( command => $path );

	is( $curl->fetch( 'http://example.org/a', $dest ),
		undef, 'fetch returns undef' );
	is( $curl->status, 'network', 'the status is network' );
	like( $curl->error, qr/cannot rename/,
		'the reason names the rename' );
	is_deeply( [ leftovers($dest) ],
		[], 'the module removed the temporary file' );
};

subtest 'the proxy variables reach the command' => sub {

	# The stub writes what it inherited, so the test proves the
	# passthrough without a proxy and without a network.
	my $record = "$dir/proxy.txt";
	my $path   = stub( 'curl', <<"SH" );
#!/bin/sh
printf '%s\\n' "\$http_proxy" > '$record'
exit 7
SH

	local $ENV{http_proxy} = 'http://127.0.0.1:1';

	my $curl = Fugu::Curl->new( command => $path );
	is( $curl->fetch( 'http://example.org/a', "$dir/proxied" ),
		undef, 'the stub fails, and fetch returns undef' );
	is( $curl->status, 'network', 'the status is network' );
	is( body($record), "http://127.0.0.1:1\n",
		'the child holds the proxy variable of the parent' );
};

# --- the subtests that need a command -------------------------------------

my @available = grep { defined Fugu::Process->find_command($_) }
    Fugu::Curl::COMMANDS();

# The ftp of a Linux host is another program, and it fetches no HTTP
# URL. The fetch subtests therefore take ftp on OpenBSD only.
my @fetchers = grep { $_ ne 'ftp' || $^O eq 'openbsd' } @available;

subtest 'new resolves the first command of the order' => sub {
	plan skip_all => 'no downloader on PATH' unless @available;

	my $curl = Fugu::Curl->new;
	is( $curl->is_available, 1,     'is_available returns 1' );
	is( $curl->error,        undef, 'error is undef' );
	like( $curl->command, qr{(?:\A|/)\Q$available[0]\E\z},
		"command holds $available[0], the first one of the order" );
};

for my $name (@fetchers) {
	my $curl = Fugu::Curl->new( command => $name, timeout => 5 );

	subtest "$name: a 200 answer lands at the destination" => sub {
		my ( $pid, $port ) = server($OK);
		my $path = "$dir/$name-200";

		is( $curl->fetch( "http://127.0.0.1:$port/asset", $path ),
			1, 'fetch returns 1' );
		is( $curl->status, 'ok',      'the status is ok' );
		is( $curl->error,  undef,     'error is undef' );
		is( body($path),   "hello\n", 'the file holds the bytes' );
		is_deeply( [ leftovers($path) ],
			[], 'no temporary file stays' );
		is( $curl->code, 200, 'curl reports the HTTP status' )
		    if $name eq 'curl';

		Fugu::Process->terminate($pid);
	};

	subtest "$name: a 404 answer fails with the http status" => sub {
		my ( $pid, $port ) = server($MISSING);
		my $path = "$dir/$name-404";
		my $url  = "http://127.0.0.1:$port/missing";

		is( $curl->fetch( $url, $path ), undef, 'fetch returns undef' );
		is( $curl->status, 'http', 'the status is http' );
		is( $curl->code,   404,    'the code is 404' );
		ok( !-e $path, 'no file appears at the destination' );
		is_deeply( [ leftovers($path) ],
			[], 'no temporary file stays' );
		like( $curl->error, qr/\A\Q$name\E:/,
			'error names the command' );
		like( $curl->error, qr/\Q$url\E/, 'error names the URL' );
		like( $curl->error, qr/404/,      'error names the status' );

		Fugu::Process->terminate($pid);
	};

	subtest "$name: a redirect lands at the destination" => sub {
		my ( $pid, $port ) = server( $REDIRECT, $OK );
		my $path = "$dir/$name-302";

		is( $curl->fetch( "http://127.0.0.1:$port/moved", $path ),
			1, 'fetch returns 1' );
		is( body($path), "hello\n",
			'the file holds the bytes of the target' );

		Fugu::Process->terminate($pid);
	};

	subtest "$name: a server that never answers stops at the bound" =>
	    sub {
		my $listen = listener();
		my $slow = Fugu::Curl->new( command => $name, timeout => 1 );
		my $path = "$dir/$name-stall";

		is(
			$slow->fetch(
				'http://127.0.0.1:'
				    . $listen->sockport . '/slow',
				$path
			),
			undef,
			'fetch returns undef'
		);

		if ( $name eq 'curl' ) {
			is( $slow->status, 'timeout',
				'the status is timeout' );
		}
		else {
			# wget and the ftp of OpenBSD report no
			# timeout of their own, so a stall under
			# their own flag takes the network status.
			like( $slow->status, qr/\A(?:timeout|network)\z/,
				'the status is timeout or network' );
		}

		ok( !-e $path, 'no file appears at the destination' );
		is_deeply( [ leftovers($path) ],
			[], 'no temporary file stays' );
		close $listen;
	    };

	subtest "$name: a closed port fails with the network status" => sub {
		my $path = "$dir/$name-refused";
		my $url  = 'http://127.0.0.1:' . closed_port() . '/asset';

		is( $curl->fetch( $url, $path ), undef, 'fetch returns undef' );
		is( $curl->status, 'network', 'the status is network' );
		is( $curl->code,   undef,     'the code is undef' );
		ok( !-e $path, 'no file appears at the destination' );
	};

	subtest "$name: a failure keeps the old bytes of the destination" =>
	    sub {
		my $path = "$dir/$name-replace";
		open my $fh, '>', $path or die "Cannot write $path: $!";
		print {$fh} "old\n";
		close $fh or die "Cannot close $path: $!";

		my ( $pid, $port ) = server($MISSING);
		is( $curl->fetch( "http://127.0.0.1:$port/missing", $path ),
			undef, 'the failed fetch returns undef' );
		is( body($path), "old\n",
			'the destination holds the old bytes' );
		Fugu::Process->terminate($pid);

		( $pid, $port ) = server($OK);
		is( $curl->fetch( "http://127.0.0.1:$port/asset", $path ),
			1, 'the next fetch returns 1' );
		is( body($path), "hello\n",
			'the destination holds the new bytes' );
		is_deeply( [ leftovers($path) ],
			[], 'no temporary file stays' );
		Fugu::Process->terminate($pid);
	    };
}

done_testing();
