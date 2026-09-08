#!/usr/bin/env perl
# ex:ts=8 sw=4:
use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";

use Cwd        ();
use Fcntl      qw(F_SETFD);
use File::Temp qw(tempdir);
use Fugu::CLI  qw(EXIT_ERROR);

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

# The env option names the exact environment of the child. Each
# subtest that runs the interpreter names it through $^X, an
# absolute path. Only the bare-name subtest depends on PATH, and
# that dependence is its subject.
subtest 'run with env gives the child exactly the named variables' => sub {
	my $r = Fugu::Process->run(
		cmd =>
		    [ $^X, '-e', 'print "$_=$ENV{$_}\n" for sort keys %ENV' ],
		env => { BBB => 'two', AAA => 'one' },
	);
	ok( $r->{success}, 'the child runs' );
	is( $r->{stdout}, "AAA=one\nBBB=two\n",
		'the child holds the named variables and nothing else' );
};

subtest 'run without env gives the child the parent environment' => sub {
	local $ENV{FUGU_TEST_MARKER} = 'from-the-parent';
	my $r = Fugu::Process->run(
		cmd => [ $^X, '-e', 'print $ENV{FUGU_TEST_MARKER} // ""' ],
	);
	ok( $r->{success}, 'the child runs' );
	is( $r->{stdout}, 'from-the-parent', 'the marker reached the child' );
};

subtest 'env => {} gives the child an empty environment' => sub {
	my $r = Fugu::Process->run(
		cmd => [ $^X, '-e', 'print scalar keys %ENV' ],
		env => {},
	);
	ok( $r->{success}, 'the child runs' );
	is( $r->{stdout}, '0', 'the child holds no variable' );
};

subtest 'the parent %ENV does not change' => sub {
	local $ENV{FUGU_TEST_MARKER} = 'stays';
	my %before = %ENV;

	Fugu::Process->run(
		cmd => [ $^X, '-e', '1' ],
		env => { ONLY => 'this' },
	);
	is_deeply( \%ENV, \%before, 'the same keys and values after run' );

	my $result = Fugu::Process->spawn_command(
		cmd => [ $^X, '-e', '1' ],
		env => { ONLY => 'this' },
	);
	Fugu::Process->wait_exit( $result->{pid}, 5 ) if $result->{success};
	is_deeply( \%ENV, \%before,
		'the same keys and values after spawn_command' );
};

subtest 'a passthrough run carries env to the child' => sub {

	# Passthrough captures nothing, so the proof is the exit code:
	# the child exits 0 only when the variable matches.
	my $r = Fugu::Process->run(
		cmd => [
			$^X, '-e',
			'exit((($ENV{FUGU_PASS} // q{}) eq q{yes}) ? 0 : 1)'
		],
		env         => { FUGU_PASS => 'yes' },
		passthrough => 1,
	);
	ok( $r->{success}, 'the child saw the variable' );
	is( $r->{exit_code}, 0, 'and exited 0' );
};

subtest 'spawn_command carries env to the child' => sub {
	my $dir = tempdir( CLEANUP => 1 );
	my $out = "$dir/env.txt";

	my $result = Fugu::Process->spawn_command(
		cmd =>
		    [ $^X, '-e', 'print "$_=$ENV{$_}\n" for sort keys %ENV' ],
		stdout => $out,
		env    => { ONE => '1', TWO => '2' },
	);
	ok( $result->{success}, 'the child spawned' );
	Fugu::Process->wait_exit( $result->{pid}, 5 );

	open my $fh, '<', $out or die "Cannot read $out: $!";
	my $content = do { local $/; <$fh> };
	close $fh;
	is( $content, "ONE=1\nTWO=2\n",
		'the file holds the exact environment' );
};

subtest 'spawn_perl carries env and the child keeps its modules' => sub {
	my $dir = tempdir( CLEANUP => 1 );
	my $out = "$dir/perl.txt";

	# The -I flags carry @INC in the argument list, so a child
	# with no PERL5LIB still loads a module of this checkout.
	my $result = Fugu::Process->spawn_perl(
		code => 'use Fugu::CLI; '
		    . 'print join(",", map { "$_=$ENV{$_}" } sort keys %ENV)',
		stdout => $out,
		env    => { FUGU_PERL => 'loaded' },
	);
	ok( $result->{success}, 'the child spawned' );
	Fugu::Process->wait_exit( $result->{pid}, 5 );

	open my $fh, '<', $out or die "Cannot read $out: $!";
	my $content = do { local $/; <$fh> };
	close $fh;
	is( $content, 'FUGU_PERL=loaded',
		'the module loaded and the environment is exact' );
};

subtest 'a bare command name needs PATH in env' => sub {
	my $dir  = tempdir( CLEANUP => 1 );
	my $prog = "$dir/fugu-env-prog";

	open my $fh, '>', $prog or die "Cannot write $prog: $!";
	print {$fh} "#!/bin/sh\nexit 0\n";
	close $fh;
	chmod 0755, $prog or die "Cannot chmod $prog: $!";

	# The default path of execvp(3) does not hold the temporary
	# directory, so the bare name fails without PATH.
	my $r = Fugu::Process->run(
		cmd => ['fugu-env-prog'],
		env => {},
	);
	ok( !$r->{success}, 'the bare name fails without PATH' );
	like( $r->{error}, qr/Cannot exec fugu-env-prog/,
		'and the error names the command' );

	$r = Fugu::Process->run(
		cmd => ['fugu-env-prog'],
		env => { PATH => $dir },
	);
	ok( $r->{success}, 'the same name succeeds with PATH in env' );
};

subtest 'a bad env returns an error and starts nothing' => sub {
	my @bad = (
		[ 'a value that is not a hashref' => 'not-a-hashref' ],
		[ 'an empty name'                 => { ''     => 'x' } ],
		[ 'an equals sign in a name'      => { 'A=B'  => 'x' } ],
		[ 'a NUL byte in a name'          => { "A\0B" => 'x' } ],
		[ 'an undefined value'            => { A      => undef } ],
		[ 'a reference value'             => { A      => [] } ],
		[ 'a NUL byte in a value'         => { A      => "x\0y" } ],
		[ 'a wide character in a name'    => { "\x{263a}" => 'x' } ],
		[ 'a wide character in a value'   => { A => "\x{263a}" } ],
	);

	for my $case (@bad) {
		my ( $name, $env ) = @$case;

		my $r = Fugu::Process->run(
			cmd => [ $^X, '-e', '1' ],
			env => $env,
		);
		ok( !$r->{success}, "run rejects $name" );
		ok( $r->{error},    'and says why' );

		my $s = Fugu::Process->spawn_command(
			cmd => [ $^X, '-e', '1' ],
			env => $env,
		);
		ok( !$s->{success},    "spawn_command rejects $name" );
		ok( !exists $s->{pid}, 'and starts nothing' );
	}

	my $r = Fugu::Process->run(
		cmd => [ $^X, '-e', '1' ],
		env => 'not-a-hashref',
	);
	is( $r->{exit_code}, EXIT_ERROR, 'the run shape: EXIT_ERROR' );
	is( $r->{stdout},    '',         'stdout is empty' );
	is( $r->{stderr},    '',         'stderr is empty' );
};

# _gone_soon($pid):
#	Poll until the process is dead, for up to five seconds. The
#	is_alive call reaps a zombie child of the test. A group member
#	that is not a child of the test waits for init to reap it, so
#	it can answer for a moment.
sub _gone_soon ($pid)
{
	for ( 1 .. 100 ) {
		return 1 unless Fugu::Process->is_alive($pid);
		select undef, undef, undef, 0.05;
	}

	return 0;
}

# _read_pids($file):
#	Poll until the file holds two pids, then return them. The
#	child writes the file directly after its fork, so the wait is
#	short.
sub _read_pids ($file)
{
	for ( 1 .. 100 ) {
		if ( open my $fh, '<', $file ) {
			my $content = do { local $/; <$fh> };
			close $fh;

			# The newline proves that the write is complete,
			# so a partial pid can never match.
			my @pids = $content =~ /^(\d+) (\d+)\n\z/;
			return @pids if @pids == 2;
		}
		select undef, undef, undef, 0.05;
	}

	return;
}

# The leader-and-grandchild program. It forks a grandchild that
# sleeps, writes both pids to the named file, and sleeps itself.
my $LEADER_CODE =
      'my $pid = fork; die "fork: $!" unless defined $pid; '
    . 'if ($pid == 0) { sleep 60; exit 0 } '
    . 'open my $fh, ">", $ARGV[0] or die "open: $!"; '
    . 'print {$fh} "$$ $pid\n"; close $fh; '
    . 'sleep 60';

subtest 'run with new_session makes the child a group leader' => sub {
	my $r = Fugu::Process->run(
		cmd         => [ $^X, '-e', 'print "$$ ", getpgrp(0)' ],
		new_session => 1,
	);
	ok( $r->{success}, 'the child runs' );
	my ( $pid, $pgid ) = split / /, $r->{stdout};
	is( $pgid, $pid, 'the group id of the child equals its pid' );
};

subtest 'run without new_session keeps the child in the caller group' =>
    sub {
	my $r = Fugu::Process->run(
		cmd => [ $^X, '-e', 'print getpgrp(0)' ],
	);
	ok( $r->{success}, 'the child runs' );
	is( $r->{stdout}, getpgrp(0), 'the child stays in the group' );
    };

subtest 'run with new_session and a timeout stops the whole group' => sub {
	my $dir  = tempdir( CLEANUP => 1 );
	my $file = "$dir/pids.txt";

	my $start = time;
	my $r     = Fugu::Process->run(
		cmd         => [ $^X, '-e', $LEADER_CODE, $file ],
		new_session => 1,
		timeout     => 2,
	);
	my $elapsed = time - $start;

	ok( $r->{timed_out}, 'run reports the timeout' );
	ok( $elapsed < 15,   'and it returned near the deadline' );

	my ( $leader, $grandchild ) = _read_pids($file);
	ok( defined $grandchild, 'the child wrote both pids' );
	return unless defined $grandchild;
	ok( _gone_soon($leader),     'the leader is gone' );
	ok( _gone_soon($grandchild), 'the grandchild is gone' );
};

subtest 'terminate with group stops the leader and the grandchild' => sub {
	my $dir  = tempdir( CLEANUP => 1 );
	my $file = "$dir/pids.txt";

	my $result = Fugu::Process->spawn_command(
		cmd       => [ $^X, '-e', $LEADER_CODE, $file ],
		daemonize => 1,
	);
	ok( $result->{success}, 'the leader spawned' );

	my ( $leader, $grandchild ) = _read_pids($file);
	ok( defined $grandchild, 'the child wrote both pids' );
	return unless defined $grandchild;

	my $killed = Fugu::Process->terminate(
		$leader,
		group        => 1,
		grace_period => 2,
	);
	ok( $killed,                 'terminate reports the group gone' );
	ok( _gone_soon($leader),     'the leader is gone' );
	ok( _gone_soon($grandchild), 'the grandchild is gone' );
};

subtest 'terminate without group signals the one pid' => sub {
	my $dir  = tempdir( CLEANUP => 1 );
	my $file = "$dir/pids.txt";

	my $result = Fugu::Process->spawn_command(
		cmd       => [ $^X, '-e', $LEADER_CODE, $file ],
		daemonize => 1,
	);
	ok( $result->{success}, 'the leader spawned' );

	my ( $leader, $grandchild ) = _read_pids($file);
	ok( defined $grandchild, 'the child wrote both pids' );
	return unless defined $grandchild;

	my $killed =
	    Fugu::Process->terminate( $leader, grace_period => 2 );
	ok( $killed,             'the leader is terminated' );
	ok( _gone_soon($leader), 'the leader is gone' );
	ok( kill( 0, $grandchild ), 'the grandchild still answers' );

	# Clean up the grandchild
	kill 'KILL', $grandchild;
};

subtest 'spawn_peer starts a peer child over a socketpair' => sub {

	# The child needs no descriptor argument: the number is part
	# of the contract, so it opens fd 3 itself.
	my $r = Fugu::Process->spawn_peer(
		cmd => [
			$^X, '-e',
			'open my $peer, q{+<&=}, 3 or die "open: $!"; '
			    . 'my $line = <$peer>; '
			    . 'print {$peer} "echo: $line"; '
			    . 'close $peer'
		],
	);
	ok( $r->{success}, 'the peer spawned' ) or diag $r->{error};
	ok( defined $r->{pid},    'the result carries the pid' );
	ok( defined $r->{socket}, 'and the parent end' );

	my $sock = $r->{socket};
	syswrite $sock, "ping\n";
	is( readline($sock), "echo: ping\n", 'the child echoed over fd 3' );

	close $sock;
	ok( Fugu::Process->wait_exit( $r->{pid}, 5 ), 'the peer exited' );
};

subtest 'spawn_peer puts the child end on the named number' => sub {
	my $r = Fugu::Process->spawn_peer(
		cmd => [
			$^X, '-e',
			'open my $peer, q{+<&=}, 9 or die "open: $!"; '
			    . 'print {$peer} "on 9"; close $peer'
		],
		fd => 9,
	);
	ok( $r->{success}, 'the peer spawned' ) or diag $r->{error};

	is( readline( $r->{socket} ), 'on 9', 'the child end sits on fd 9' );

	close $r->{socket};
	Fugu::Process->wait_exit( $r->{pid}, 5 );
};

subtest 'spawn_peer reports an exec failure with the reason' => sub {
	my $r = Fugu::Process->spawn_peer(
		cmd => ['/nonexistent/definitely-not-a-command'] );

	ok( !$r->{success}, 'an exec failure is a failure' );
	like(
		$r->{error},
		qr/Cannot exec .*definitely-not-a-command/,
		'and the error names the command'
	);
	ok( !exists $r->{socket}, 'no socket comes back' );
};

subtest 'spawn_peer dies on a bad fd' => sub {
	ok( !eval { Fugu::Process->spawn_peer( cmd => ['true'], fd => 2 ); 1 },
		'an fd below 3 dies' );
	like( $@, qr/fd must be a number of 3 or above/, 'and says why' );

	open my $null, '<', '/dev/null' or die "open: $!";
	ok( !eval {
		Fugu::Process->spawn_peer(
			cmd     => ['true'],
			fd      => fileno($null),
			inherit => [$null],
		);
		1;
	    },
		'a collision with an inherit descriptor dies' );
	like( $@, qr/collides with an inherit descriptor/, 'and says why' );
	close $null;
};

subtest 'a descriptor in inherit reaches the child' => sub {
	my $dir = tempdir( CLEANUP => 1 );

	open my $out, '>>', "$dir/inherit.txt" or die "open: $!";
	$out->autoflush(1);

	# The caller reads fileno before the call and puts the number
	# in cmd. That is the contract.
	my $result = Fugu::Process->spawn_command(
		cmd => [
			$^X, '-e',
			'open my $fh, q{>>&=}, $ARGV[0] or die "open: $!"; '
			    . 'print {$fh} "from the child"; close $fh',
			fileno($out),
		],
		inherit => [$out],
	);
	ok( $result->{success}, 'the child spawned' ) or diag $result->{error};
	Fugu::Process->wait_exit( $result->{pid}, 5 );
	close $out;

	open my $fh, '<', "$dir/inherit.txt" or die "read: $!";
	my $content = do { local $/; <$fh> };
	close $fh;
	is( $content, 'from the child', 'the descriptor survived the exec' );
};

subtest 'a descriptor outside inherit does not reach the child' => sub {

	# A write end that the caller made inheritable itself. The
	# sweep must close it anyway, because inherit does not name it.
	pipe my $r_end, my $w_end or die "pipe: $!";
	fcntl( $w_end, F_SETFD, 0 ) or die "fcntl: $!";
	my $fd = fileno $w_end;

	# The child end of spawn_peer lands on fd 3, so the probe must
	# sit above it, or the child would probe its own socket.
	plan skip_all => 'the pipe landed on fd 3' if $fd <= 3;

	my $r = Fugu::Process->spawn_peer(
		cmd => [
			$^X, '-e',
			'my $ok = open( my $fh, q{>>&=}, $ARGV[0] ) '
			    . '? q{open} : q{closed}; '
			    . 'open my $peer, q{+<&=}, 3 or die "open: $!"; '
			    . 'print {$peer} $ok; close $peer',
			$fd,
		],
	);
	ok( $r->{success}, 'the child spawned' ) or diag $r->{error};

	is( readline( $r->{socket} ), 'closed', 'the sweep closed the pipe' );

	close $r->{socket};
	close $r_end;
	close $w_end;
	Fugu::Process->wait_exit( $r->{pid}, 5 );
};

subtest 'a descriptor in inherit reaches a spawn_peer child' => sub {
	my $dir = tempdir( CLEANUP => 1 );

	open my $out, '>>', "$dir/peer-inherit.txt" or die "open: $!";
	$out->autoflush(1);

	# The inherit member rides beside the occupied peer number, so
	# the peer number must differ from the member.
	my $peerfd = fileno($out) == 3 ? 4 : 3;

	my $r = Fugu::Process->spawn_peer(
		cmd => [
			$^X, '-e',
			'open my $fh, q{>>&=}, $ARGV[0] or die "open: $!"; '
			    . 'print {$fh} "beside the peer"; close $fh; '
			    . 'open my $peer, q{+<&=}, $ARGV[1] '
			    . 'or die "open: $!"; '
			    . 'print {$peer} "done"; close $peer',
			fileno($out),
			$peerfd,
		],
		fd      => $peerfd,
		inherit => [$out],
	);
	ok( $r->{success}, 'the peer spawned' ) or diag $r->{error};

	is( readline( $r->{socket} ), 'done', 'the child answered' );
	close $r->{socket};
	Fugu::Process->wait_exit( $r->{pid}, 5 );
	close $out;

	open my $fh, '<', "$dir/peer-inherit.txt" or die "read: $!";
	my $content = do { local $/; <$fh> };
	close $fh;
	is( $content, 'beside the peer',
		'the inherit descriptor survived the exec' );
};

subtest 'a descriptor outside inherit does not reach spawn_command' => sub {
	my $dir = tempdir( CLEANUP => 1 );
	my $out = "$dir/probe.txt";

	pipe my $r_end, my $w_end or die "pipe: $!";
	fcntl( $w_end, F_SETFD, 0 ) or die "fcntl: $!";
	my $fd = fileno $w_end;

	my $result = Fugu::Process->spawn_command(
		cmd => [
			$^X, '-e',
			'print( open( my $fh, q{>>&=}, $ARGV[0] ) '
			    . '? q{open} : q{closed} )',
			$fd,
		],
		stdout => $out,
	);
	ok( $result->{success}, 'the child spawned' ) or diag $result->{error};
	Fugu::Process->wait_exit( $result->{pid}, 5 );
	close $r_end;
	close $w_end;

	open my $fh, '<', $out or die "read: $!";
	my $content = do { local $/; <$fh> };
	close $fh;
	is( $content, 'closed', 'the sweep closed the pipe' );
};

subtest 'spawn_peer carries env to the child' => sub {
	my $r = Fugu::Process->spawn_peer(
		cmd => [
			$^X, '-e',
			'open my $peer, q{+<&=}, 3 or die "open: $!"; '
			    . 'print {$peer} join( q{,}, '
			    . 'map { "$_=$ENV{$_}" } sort keys %ENV ); '
			    . 'close $peer'
		],
		env => { ONE => '1', TWO => '2' },
	);
	ok( $r->{success}, 'the peer spawned' ) or diag $r->{error};
	is( readline( $r->{socket} ), 'ONE=1,TWO=2',
		'the child holds the named variables and nothing else' );
	close $r->{socket};
	Fugu::Process->wait_exit( $r->{pid}, 5 );

	my $bad = Fugu::Process->spawn_peer(
		cmd => [ $^X, '-e', '1' ],
		env => 'not-a-hashref',
	);
	ok( !$bad->{success},    'a bad env starts nothing' );
	ok( !exists $bad->{pid}, 'and carries no pid' );
};

subtest 'spawn_peer survives an exec pipe on the requested number' => sub {

	# Predict the numbers: the socketpair takes the two lowest
	# free descriptors, and the exec pipe takes the next two. The
	# write end of the pipe is the fourth, so ask for exactly that
	# number, and the pipe must move out of the way. A missed
	# prediction still passes, and then only skips the branch.
	open my $probe, '<', '/dev/null' or die "open: $!";
	my $base = fileno $probe;
	close $probe;
	my $fd = $base + 3;

	my $r = Fugu::Process->spawn_peer(
		cmd => [
			$^X, '-e',
			'open my $peer, q{+<&=}, $ARGV[0] or die "open: $!"; '
			    . 'print {$peer} "collision"; close $peer',
			$fd,
		],
		fd => $fd,
	);
	ok( $r->{success}, 'the peer spawned' ) or diag $r->{error};
	is( readline( $r->{socket} ), 'collision',
		'the child end took the number' );
	close $r->{socket};
	Fugu::Process->wait_exit( $r->{pid}, 5 );

	# The moved pipe still reports an exec failure exactly.
	my $bad = Fugu::Process->spawn_peer(
		cmd => ['/nonexistent/definitely-not-a-command'],
		fd  => $fd,
	);
	ok( !$bad->{success}, 'an exec failure still reports' );
	like( $bad->{error}, qr/Cannot exec/, 'with the reason' );
};

subtest 'a bad inherit dies and starts nothing' => sub {
	for my $method (qw(spawn_command spawn_peer)) {
		ok( !eval {
			Fugu::Process->$method(
				cmd     => ['true'],
				inherit => 'not-an-arrayref',
			);
			1;
		    },
			"$method dies on a value that is not an arrayref" );
		like( $@, qr/inherit must be an array reference/,
			'and says why' );

		ok( !eval {
			Fugu::Process->$method(
				cmd     => ['true'],
				inherit => ['not-a-handle'],
			);
			1;
		    },
			"$method dies on a member with no descriptor" );
		like( $@, qr/no descriptor/, 'and says why' );
	}
};

subtest 'the module reads the Perl configuration at compile time' => sub {

	# A pledged caller of spawn_perl must open no file at call
	# time. The proof: Config.pm and Config_heavy.pl sit in %INC
	# directly after the compile, with no method call.
	my $code =
	      'use Fugu::Process; '
	    . 'print $INC{q{Config.pm}} ? q{y} : q{n}; '
	    . 'print $INC{q{Config_heavy.pl}} ? q{y} : q{n};';

	my $r = Fugu::Process->run(
		cmd => [ $^X, "-I$RealBin/../../lib", '-e', $code ],
	);
	ok( $r->{success}, 'the module compiles' ) or diag $r->{stderr};
	is( $r->{stdout}, 'yy',
		'%INC holds Config.pm and Config_heavy.pl after the compile'
	);
};

done_testing();
