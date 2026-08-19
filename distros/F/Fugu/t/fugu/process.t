#!/usr/bin/env perl
# ex:ts=8 sw=4:
use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";

use Cwd        ();
use File::Temp qw(tempdir);

use_ok('Fugu::Process');

# Test 2: Basic spawn and terminate
{
	my $result = Fugu::Process->spawn_command(
		cmd => [ 'sleep', '300' ],
	);

	ok( $result->{success}, 'Spawned sleep process' );
	ok( defined $result->{pid}, 'Got PID' );
	my $pid = $result->{pid};

	ok( Fugu::Process->is_alive($pid), 'Process is alive' );

	my $killed = Fugu::Process->terminate( $pid, grace_period => 2 );
	ok( $killed, 'Terminated process' );

	ok( !Fugu::Process->is_alive($pid), 'Process is dead' );
}

# Test 3: a process that exits at once still spawned successfully.
# The exec resolved, so the spawn is a success; the caller that needs
# the outcome uses run.
{
	my $result = Fugu::Process->spawn_command(
		cmd => [ 'sh', '-c', 'exit 1' ],
	);

	ok( $result->{success}, 'A fast exit is still a successful spawn' );
	ok( defined $result->{pid}, 'and carries the PID' );
	Fugu::Process->wait_exit( $result->{pid}, 2 );
}

# Test 3c: An exec that fails reports its own reason at once, through
# the close-on-exec pipe and not through a wait-and-guess sleep.
{
	my $start  = time;
	my $result = Fugu::Process->spawn_command(
		cmd => ['/nonexistent/definitely-not-a-command'],
	);
	my $elapsed = time - $start;

	ok( !$result->{success}, 'An exec failure is a failure' );
	like(
		$result->{error},
		qr/Cannot exec .*definitely-not-a-command/,
		'the error names the command'
	);
	like( $result->{error}, qr/No such file|not found/i,
		'and carries the reason from the system' );
	ok( $elapsed <= 2, 'the report does not wait for a sleep' );
}

# Test 4: Invalid command
{
	my $result = Fugu::Process->spawn_command( cmd => [] );

	ok( !$result->{success}, 'Rejected empty command' );
	like( $result->{error}, qr/non-empty arrayref/, 'and says why' );

	my $scalar = Fugu::Process->spawn_command( cmd => 'sleep 1' );
	ok( !$scalar->{success}, 'Rejected a non-arrayref command' );
}

# Test 8: is_alive edge cases
{
	ok( !Fugu::Process->is_alive(undef),  'undef PID is not alive' );
	ok( !Fugu::Process->is_alive(''),     'Empty PID is not alive' );
	ok( !Fugu::Process->is_alive('abc'),  'Non-numeric PID is not alive' );
	ok( !Fugu::Process->is_alive(999999), 'Non-existent PID is not alive' );
	ok( Fugu::Process->is_alive($$),      'Own PID is alive' );
}

# Test 9: wait_exit
{
	my $result = Fugu::Process->spawn_command(
		cmd => [ 'sleep', '1' ],
	);

	my $exited = Fugu::Process->wait_exit( $result->{pid}, 5 );
	ok( $exited, 'Process exited within timeout' );
}

# Test 10: wait_exit timeout
{
	my $result = Fugu::Process->spawn_command(
		cmd => [ 'sleep', '10' ],
	);

	my $exited = Fugu::Process->wait_exit( $result->{pid}, 1 );
	ok( !$exited, 'Timeout waiting for exit' );

	Fugu::Process->terminate( $result->{pid} );
}

# Test 11: Graceful and forced termination
{
	# A process that ignores SIGTERM (sleep handles it)
	my $result = Fugu::Process->spawn_command(
		cmd => [ 'sleep', '300' ],
	);

	my $start  = time;
	my $killed = Fugu::Process->terminate( $result->{pid}, grace_period => 2 );
	my $elapsed = time - $start;

	ok( $killed, 'Process terminated' );
	ok( $elapsed < 5, 'Terminated quickly (graceful)' );
}

# Test 13: I/O redirection
{
	my $tmpdir  = tempdir( CLEANUP => 1 );
	my $outfile = "$tmpdir/fugu-process-test.txt";

	my $result = Fugu::Process->spawn_command(
		cmd    => [ 'echo', 'test output' ],
		stdout => $outfile,
	);

	sleep 1;
	Fugu::Process->wait_exit( $result->{pid}, 2 );

	ok( -f $outfile, 'Output file created' );
	if ( -f $outfile ) {
		open my $fh, '<', $outfile
		    or do { fail("Cannot read $outfile: $!"); };
		my $content = <$fh>;
		close $fh;
		like( $content, qr/test output/, 'Output redirected correctly' );
	}
}

# Test 14: exit_code maps a raw wait status to a 0-255 code
{
	is( Fugu::Process->exit_code(0),        0, 'status 0 -> exit 0' );
	is( Fugu::Process->exit_code( 1 << 8 ), 1, 'exit code 1 preserved' );
	is( Fugu::Process->exit_code( 2 << 8 ), 2, 'exit code 2 preserved' );
	is( Fugu::Process->exit_code( 255 << 8 ),
		255, 'exit code 255 preserved' );
	is( Fugu::Process->exit_code(-1), 1,   'a failed start -> 1' );
	is( Fugu::Process->exit_code(15), 143, 'signal 15 -> 128 + signal' );
	is( Fugu::Process->exit_code(2),  130, 'signal 2 -> 128 + signal' );
}

# Test 15: run captures both streams and the exit code
{
	my $r = Fugu::Process->run(
		cmd => [ 'sh', '-c', 'echo out; echo err >&2; exit 3' ] );

	is( $r->{exit_code}, 3, 'run reports the exit code' );
	ok( !$r->{success}, 'a non-zero exit is not a success' );
	like( $r->{stdout}, qr/^out$/m,  'run captured stdout' );
	like( $r->{stderr}, qr/^err$/m,  'run captured stderr' );
	ok( !$r->{timed_out}, 'and it did not time out' );
}

# Test 16: run feeds stdin and never goes through a shell
{
	my $r = Fugu::Process->run(
		cmd   => [ 'cat' ],
		stdin => "hello\n",
	);
	is( $r->{stdout}, "hello\n", 'run feeds stdin to the child' );
	ok( $r->{success}, 'and reports success' );

	# An argument that a shell would treat as an operator stays one
	# argument, because the command is a list
	my $shell = Fugu::Process->run( cmd => [ 'echo', 'a; touch b' ] );
	is( $shell->{stdout}, "a; touch b\n", 'no shell interprets the argument' );
}

# Test 17: run enforces its timeout
{
	my $start = time;
	my $r     = Fugu::Process->run(
		cmd     => [ 'sleep', '30' ],
		timeout => 1,
	);
	my $elapsed = time - $start;

	ok( $r->{timed_out}, 'run reports the timeout' );
	ok( !$r->{success},  'a timed-out run is not a success' );
	ok( $elapsed < 10,   'and it returned near the deadline' );
}

# Test 18: run reports an exec failure without starting anything
{
	my $r = Fugu::Process->run(
		cmd => ['/nonexistent/definitely-not-a-command'] );

	ok( !$r->{success}, 'run fails when the exec fails' );
	like( $r->{error}, qr/Cannot exec/, 'and names the exec' );

	my $empty = Fugu::Process->run( cmd => [] );
	ok( !$empty->{success}, 'run rejects an empty command' );
}

# Test 19: run drains a child that writes more than one pipe buffer.
# A reader that took the streams in sequence would deadlock here.
{
	my $r = Fugu::Process->run(
		cmd => [
			'sh', '-c',
			'i=0; while [ $i -lt 400 ]; do '
			    . 'echo "0123456789012345678901234567890123456789"; '
			    . 'echo "x" >&2; i=$((i+1)); done'
		],
		timeout => 30,
	);

	ok( $r->{success}, 'a chatty child completes' );
	is( length( $r->{stdout} ), 400 * 41, 'stdout arrived whole' );
	is( length( $r->{stderr} ), 400 * 2,  'stderr arrived whole' );
}

# Test 20: the cwd option moves the child and nothing else. mandoc
# resolves a cross-reference against its working directory, so a
# caller needs a child that starts somewhere else.
subtest 'run starts the child in the named directory' => sub {
	my $dir = tempdir( CLEANUP => 1 );
	mkdir "$dir/inside" or die "Cannot create the directory: $!";

	open my $fh, '>', "$dir/inside/marker" or die "Cannot write: $!";
	close $fh;

	my $before = Cwd::getcwd();

	my $r = Fugu::Process->run(
		cmd     => [ 'ls' ],
		cwd     => "$dir/inside",
		timeout => 30,
	);
	ok( $r->{success}, 'the child runs' );
	like( $r->{stdout}, qr/^marker$/m, 'and lists that directory' );

	is( Cwd::getcwd(), $before, 'the caller did not move' );

	# A directory that does not exist must not become a silent run
	# in the directory the caller happened to be in.
	$r = Fugu::Process->run(
		cmd     => [ 'ls' ],
		cwd     => "$dir/absent",
		timeout => 30,
	);
	ok( !$r->{success}, 'an absent directory fails the run' );
	like( $r->{error}, qr/Cannot chdir to \Q$dir\E\/absent/,
		'and the message names it' );

	# The passthrough path forks its own child, so it needs the
	# same chdir. It captures nothing, so the proof is a command
	# that fails unless it runs in the right directory.
	#
	# No timeout here: a passthrough run that is given one reaps
	# the child inside wait_exit and then reads a stale status, so
	# every such run reports a failure. That is a separate defect
	# and no caller in the tree hits it.
	$r = Fugu::Process->run(
		cmd         => [ 'test', '-f', 'marker' ],
		cwd         => "$dir/inside",
		passthrough => 1,
	);
	ok( $r->{success}, 'a passthrough child runs in the directory too' );

	$r = Fugu::Process->run(
		cmd         => [ 'test', '-f', 'marker' ],
		cwd         => $dir,
		passthrough => 1,
	);
	ok( !$r->{success}, 'and not in the one the caller was in' );

	$r = Fugu::Process->run(
		cmd         => [ 'true' ],
		cwd         => "$dir/absent",
		passthrough => 1,
	);
	ok( !$r->{success}, 'an absent directory fails a passthrough run' );
	like( $r->{error}, qr/Cannot chdir/, 'and says why' );
};

done_testing();
