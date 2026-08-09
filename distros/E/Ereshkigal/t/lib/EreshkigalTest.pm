package EreshkigalTest;

use 5.006;
use strict;
use warnings;
use Exporter         qw( import );
use Cwd              ();
use File::Temp       ();
use IO::Socket::UNIX ();
use JSON::MaybeXS    qw( encode_json decode_json );
use POSIX            qw( WNOHANG );

=head1 NAME

EreshkigalTest - Shared helpers for the Ereshkigal test suite.

=cut

our @EXPORT_OK = qw(
	test_dir
	socket_path_ok
	wait_for_socket
	wait_for_gone
	wait_for_exit
	spawn_kur
	spawn_manager
	write_config
	mock_server
	read_ban_csv
);

my @pids;
my $parent_pid = $$;
my $dist_root  = Cwd::getcwd();

# temp dir for a test, cleaned up on scope exit
sub test_dir {
	return File::Temp->newdir( TEMPLATE => 'ereshkigal-t-XXXXXX', TMPDIR => 1 );
}

# sun_path is limited to ~104 chars on the BSDs, so make sure the longest
# path a test will bind a socket at is going to fit... if not the test
# should skip rather than fail with a confusing bind error
sub socket_path_ok {
	my ($dir) = @_;

	return length( $dir . '/run/kur/some-long-name.sock' ) < 100 ? 1 : 0;
}

sub wait_for_socket {
	my ( $path, $timeout ) = @_;
	$timeout = 10 if !defined($timeout);

	my $waited = 0;
	while ( $waited < $timeout ) {
		return 1 if -S $path;
		select( undef, undef, undef, 0.1 );
		$waited += 0.1;
	}

	return 0;
} ## end sub wait_for_socket

sub wait_for_gone {
	my ( $path, $timeout ) = @_;
	$timeout = 10 if !defined($timeout);

	my $waited = 0;
	while ( $waited < $timeout ) {
		return 1 if !-e $path;
		select( undef, undef, undef, 0.1 );
		$waited += 0.1;
	}

	return 0;
} ## end sub wait_for_gone

# waits for the PID to exit, returning the exit code, or undef if it did not
# exit with in the timeout
sub wait_for_exit {
	my ( $pid, $timeout ) = @_;
	$timeout = 10 if !defined($timeout);

	my $waited = 0;
	while ( $waited < $timeout ) {
		my $reaped = waitpid( $pid, WNOHANG );
		if ( $reaped == $pid || $reaped == -1 ) {
			@pids = grep { $_ != $pid } @pids;
			return $? >> 8;
		}
		select( undef, undef, undef, 0.1 );
		$waited += 0.1;
	}

	return undef;
} ## end sub wait_for_exit

sub _spawn {
	my ( $quiet, @cmd ) = @_;

	my $pid = fork();
	die( 'fork failed... ' . $! ) if !defined($pid);
	if ( !$pid ) {
		if ($quiet) {
			open( STDERR, '>', '/dev/null' );
			open( STDOUT, '>', '/dev/null' );
		}
		exec(@cmd) || exit 127;
	}
	push( @pids, $pid );

	return $pid;
} ## end sub _spawn

# fork+exec a kur via the current perl, no daemonizing... quiet redirects
# it's stdout/stderr to /dev/null for spawns expected to fail noisily
sub spawn_kur {
	my (%opts) = @_;

	return _spawn(
		$opts{quiet},                                         $^X,
		'-I' . $dist_root . '/lib',                           $dist_root . '/src_bin/kur',
		'--foreground',                                       '--name',
		$opts{name},                                          '--backend',
		defined( $opts{backend} ) ? $opts{backend} : 'dummy', '--run',
		$opts{run},                                           '--cache',
		$opts{cache},                                         defined( $opts{args} ) ? @{ $opts{args} } : (),
	);
} ## end sub spawn_kur

# fork+exec a manager via the current perl, no daemonizing
sub spawn_manager {
	my ($config) = @_;

	return _spawn(
		0, $^X,
		'-I' . $dist_root . '/lib',
		$dist_root . '/src_bin/ereshkigal',
		'start', '--foreground', '--config', $config
	);
} ## end sub spawn_manager

# writes a smoke test style config into the test dir, along with a wrapper
# so the manager can spawn the in-tree kur, returning the config path
sub write_config {
	my ( $dir, %opts ) = @_;

	my $group = getgrgid( ( split( /\s+/, $( ) )[0] );

	my $wrapper = $dir . '/kur-wrapper';
	open( my $wrapper_fh, '>', $wrapper )
		|| die( 'Failed to open "' . $wrapper . '"... ' . $! );
	print $wrapper_fh "#!/bin/sh\nexec " . $^X . ' -I' . $dist_root . '/lib ' . $dist_root . "/src_bin/kur \"\$@\"\n";
	close($wrapper_fh);
	chmod( 0755, $wrapper );

	my $kurs_toml
		= defined( $opts{kurs_toml} )
		? $opts{kurs_toml}
		: '[kur.sshd]
backend   = "dummy"
ports     = [ "22" ]
protocols = [ "tcp" ]

[kur.smtp]
backend   = "dummy"
ports     = [ "25" ]
protocols = [ "tcp" ]
';

	my $config = $dir . '/ereshkigal.toml';
	open( my $config_fh, '>', $config )
		|| die( 'Failed to open "' . $config . '"... ' . $! );
	print $config_fh 'run_base_dir   = "'
		. $dir . '/run"' . "\n"
		. 'cache_base_dir = "'
		. $dir
		. '/cache"' . "\n"
		. 'socket_group   = "'
		. $group . '"' . "\n"
		. 'socket_mode    = "0660"' . "\n"
		. 'kur_bin        = "'
		. $wrapper . '"' . "\n"
		. ( defined( $opts{settings_toml} ) ? $opts{settings_toml} : '' ) . "\n"
		. $kurs_toml;
	close($config_fh);

	return $config;
} ## end sub write_config

# forks a trivial blocking one connection at a time JSON server for testing
# clients against... responses is a hash of command => response where the
# response may be...
#     - a hash ref :: encoded to JSON and sent, or if it contains a true
#           __no_reply__ it just sits there, for timeout testing
#     - a code ref :: called with the decoded request and a per connection
#           state hashref, the return used as above
#     - a plain scalar :: sent raw, for testing undecodable responses
# multiple requests may be sent on one connection, which along with the per
# connection state allows scripting conversations such as the auth challenge
sub mock_server {
	my ( $socket_path, $responses ) = @_;

	my $listener = IO::Socket::UNIX->new(
		'Type'   => IO::Socket::UNIX::SOCK_STREAM(),
		'Local'  => $socket_path,
		'Listen' => 5,
	) || die( 'Failed to create the mock server socket at "' . $socket_path . '"... ' . $! );

	my $pid = fork();
	die( 'fork failed... ' . $! ) if !defined($pid);
	if ( !$pid ) {
		$SIG{PIPE} = 'IGNORE';
		while ( my $conn = $listener->accept ) {
			my $state = {};
			while ( my $line = <$conn> ) {
				my $request;
				eval { $request = decode_json($line); };
				my $command = ref($request) eq 'HASH' ? $request->{command} : undef;
				$command = '' if !defined($command);
				my $response = $responses->{$command};
				if ( ref($response) eq 'CODE' ) {
					$response = $response->( $request, $state );
				}
				if ( !defined($response) ) {
					$response = { 'status' => 'error', 'error' => 'unknown command: ' . $command };
				}
				if ( ref($response) eq '' ) {
					print $conn $response . "\n";
				} elsif ( ref($response) eq 'HASH' && $response->{__no_reply__} ) {
					sleep(60);
				} else {
					print $conn encode_json($response) . "\n";
				}
			} ## end while ( my $line = <$conn> )
			close($conn);
		} ## end while ( my $conn = $listener->accept )
		exit 0;
	} ## end if ( !$pid )
	close($listener);
	push( @pids, $pid );

	return $pid;
} ## end sub mock_server

# reads a kur ban state CSV, returning { ip => { time => ..., left => ... } }
sub read_ban_csv {
	my ($path) = @_;

	open( my $fh, '<', $path ) || die( 'Failed to open "' . $path . '"... ' . $! );
	my @lines = <$fh>;
	close($fh);

	shift(@lines);    # the header

	my $rows = {};
	foreach my $line (@lines) {
		chomp($line);
		next if $line eq '';
		my ( $ip, $time, $left ) = split( /,/, $line );
		$rows->{$ip} = { 'time' => $time, 'left' => $left };
	}

	return $rows;
} ## end sub read_ban_csv

# make sure no daemons get stranded, even if a test dies half way through
END {
	if ( $$ != $parent_pid ) {
		return;
	}
	# keep the waitpid calls below from clobbering the exit code of the test
	local $?;
	foreach my $pid (@pids) {
		kill( 'TERM', $pid );
	}
	my $waited = 0;
	while ( @pids && $waited < 5 ) {
		@pids = grep { waitpid( $_, WNOHANG ) == 0 } @pids;
		last if !@pids;
		select( undef, undef, undef, 0.1 );
		$waited += 0.1;
	}
	foreach my $pid (@pids) {
		kill( 'KILL', $pid );
		waitpid( $pid, 0 );
	}
} ## end END

1;
