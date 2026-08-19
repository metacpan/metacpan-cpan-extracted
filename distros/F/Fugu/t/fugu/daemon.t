#!/usr/bin/env perl
# ex:ts=8 sw=4:
use v5.36;
use Test::More;
use FindBin  qw($RealBin);
use lib "$RealBin/../../lib";
use File::Temp  qw(tempdir);
use Time::HiRes qw(time sleep);

use_ok('Fugu::Daemon');
use_ok('Fugu::Pidfile');

my $lib = "$RealBin/../../lib";
my $dir = tempdir( CLEANUP => 1 );

# slurp($path):
#	Read a whole file, or return the empty string.
sub slurp ($path)
{
	open my $fh, '<', $path or return '';
	local $/;
	my $data = <$fh>;
	close $fh;
	return $data // '';
}

# wait_for($path, $seconds):
#	Poll for a file that another process writes. The daemon under
#	test is detached, so there is nothing to wait on but the
#	filesystem. The poll tolerates a slow scheduler.
sub wait_for ( $path, $seconds = 10 )
{
	my $deadline = time + $seconds;
	while ( time < $deadline ) {
		return 1 if -s $path;
		sleep 0.05;
	}
	return 0;
}

# start_daemon($code):
#	Run $code in a detached daemon. The method returns the exit
#	status of the process that called daemonize, which is the
#	parent half of the fork. The daemon itself lives on.
sub start_daemon ($code)
{
	my $pid = fork;
	die "fork: $!" unless defined $pid;
	if ( $pid == 0 ) {
		exec { $^X } $^X, "-I$lib", '-e', $code;
		exit 127;
	}
	waitpid $pid, 0;
	return $? >> 8;
}

# stop($pid):
#	Stop a daemon that a test started.
sub stop ($pid)
{
	return unless defined $pid && $pid =~ /^\d+$/;
	kill 'TERM', $pid;
	return;
}

# Test 1: the child detaches, takes the PID file, changes to the root
# directory, and applies the umask
{
	my $pidfile = "$dir/detach.pid";
	my $report  = "$dir/detach.txt";

	my $status = start_daemon(<<"CODE");
use v5.36;
use Cwd ();
use Fugu::Daemon;
Fugu::Daemon->daemonize(
	logfile => '/dev/null',
	pidfile => '$pidfile',
);
open my \$fh, '>', '$report' or exit 1;
printf {\$fh} "cwd=%s\\numask=%04o\\npid=%d\\n",
    Cwd::getcwd(), umask, \$\$;
close \$fh;
sleep 30;
CODE

	is( $status, 0, 'the process that daemonized exits with status 0' );

	ok( wait_for($pidfile), 'the daemon wrote its PID file' );
	ok( wait_for($report),  'the daemon reported its state' );

	my $lock = Fugu::Pidfile->new( path => $pidfile );
	my $pid  = $lock->read_pid;
	ok( defined $pid, 'the PID file holds a PID' );

	my $state = slurp($report);
	like( $state, qr{^cwd=/$}m,      'the daemon changed to /' );
	like( $state, qr/^umask=0022$/m, 'the daemon applied the umask' );
	like( $state, qr/^pid=\Q$pid\E$/m,
		'the PID file names the daemon itself' );

	is( $lock->is_running, $pid, 'the daemon is alive' );

	stop($pid);
	$lock->remove;
}

# Test 2: the lock is exclusive. A second daemon on the same PID file
# must not start.
{
	my $pidfile = "$dir/exclusive.pid";
	my $marker  = "$dir/second-started";

	start_daemon(<<"CODE");
use Fugu::Daemon;
Fugu::Daemon->daemonize(logfile => '/dev/null', pidfile => '$pidfile');
sleep 30;
CODE
	ok( wait_for($pidfile), 'the first daemon holds the PID file' );

	my $lock = Fugu::Pidfile->new( path => $pidfile );
	my $pid  = $lock->read_pid;

	start_daemon(<<"CODE");
use Fugu::Daemon;
Fugu::Daemon->daemonize(logfile => '/dev/null', pidfile => '$pidfile');
open my \$fh, '>', '$marker' or exit 1;
print {\$fh} \$\$;
close \$fh;
sleep 30;
CODE

	# The second daemon dies inside daemonize. Give it more time
	# than it would need to reach the marker if the lock did not
	# hold.
	ok( !wait_for( $marker, 2 ), 'the second daemon did not start' );
	is( $lock->read_pid, $pid, 'the PID file still names the first' );

	stop($pid);
	$lock->remove;
}

# Test 4: with no pidfile argument, daemonize creates nothing
{
	my $report = "$dir/no-pidfile.txt";

	start_daemon(<<"CODE");
use Fugu::Daemon;
my \$held = Fugu::Daemon->daemonize(logfile => '/dev/null');
open my \$fh, '>', '$report' or exit 1;
print {\$fh} defined \$held ? 'held' : 'none';
close \$fh;
CODE

	ok( wait_for( $report, 5 ), 'the daemon ran' );
	is( slurp($report), 'none', 'daemonize returns nothing' );
}

done_testing();
