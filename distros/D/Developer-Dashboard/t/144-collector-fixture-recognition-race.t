#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use File::Spec;
use File::Temp qw(tempdir);
use Test::More;
use Time::HiRes ();

use lib 'lib';
use lib 't/lib';
use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::GoRoutine ();
use Local::CollectorFixture qw(wait_for_managed_loop);

# The source guard below reads two suite files, so the repository root has to be
# captured before the hermetic chdir moves the process out of the checkout.
my $repo_root = File::Spec->rel2abs('.');

# Hermetic runtime: collector roots resolve from the deepest .developer-dashboard
# layer at or above the CWD, so the temp home must also be the working directory.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths  = Developer::Dashboard::PathRegistry->new( home => $home, app_name => 'dashboard-test' );
my $runner = Developer::Dashboard::CollectorRunner->new(
    collectors => Developer::Dashboard::Collector->new( paths => $paths ),
    files      => Developer::Dashboard::FileRegistry->new( paths => $paths ),
    indicators => Developer::Dashboard::IndicatorStore->new( paths => $paths ),
    paths      => $paths,
);

# _running_under_qemu()
# Reports whether this test process itself runs under qemu user-mode
# emulation, by reading the PARENT process's /proc cmdline: an emulated
# process shows as `/usr/bin/qemu-<arch> <real-binary> <args>`. The parent
# is read, not self: inside the guest a process's OWN /proc/self/cmdline
# shows the guest argv with no qemu prefix - the prefix is only visible
# when reading ANOTHER process's cmdline. (Reading self always answered
# false on the ARM64 box, so the qemu skips below were dead code.)
# Output: boolean true when the first argv token names a qemu emulator.
sub _running_under_qemu {
    # getppid() is unimplemented on Strawberry Perl (Windows), so it must
    # never be called where /proc does not exist: the parent path is built
    # only when /proc is a directory. On Windows only /proc/self/cmdline
    # is tried, which is unreadable, so this returns 0 without dying.
    my @paths = ('/proc/self/cmdline');
    unshift @paths, '/proc/' . getppid() . '/cmdline' if -d '/proc';
    for my $path (@paths) {
        next if !-r $path;
        open my $fh, '<', $path or next;
        local $/;
        my $cmdline = <$fh> // '';
        close $fh;
        my ($first) = split /\0/, $cmdline;
        return 1 if defined $first && $first =~ m{(?:^|/)qemu-[^/\s]+\z};
    }
    return 0;
}

# spawn_fixture_child($title_delay, $title[, $loop_name])
# Starts a stand-in collector loop process for one fixture.
# Input: seconds to wait before adopting the process title (0 for immediately),
#        the process title string, or undef to never adopt one, and the
#        optional loop name to pass as a pre-exec environment marker
#        (DEVELOPER_DASHBOARD_LOOP_NAME in the spawn environ), mirroring what
#        start_loop does for a real loop.
# Output: native process id of the spawned child process.
#
# The marker is what identifies the child where the title cannot be
# observed: a post-exec $ENV assignment is invisible to /proc readers on
# every platform, and under qemu user-mode emulation the $0 title is
# invisible too. Fixtures that must stay unrecognized (untitled, swept)
# pass no name, so they carry neither channel.
sub spawn_fixture_child {
    my ( $title_delay, $title, $loop_name ) = @_;
    my $script = q{
        my ($delay, $process_title) = @ARGV;
        Time::HiRes::sleep($delay) if $delay;
        $0 = $process_title if length $process_title;
        Time::HiRes::sleep(30);
        exit 0;
    };
    return Developer::Dashboard::GoRoutine::spawn(
        [ $^X, '-MTime::HiRes', '-e', $script, $title_delay, ( defined $title ? $title : '' ) ],
        defined $loop_name ? { env => { DEVELOPER_DASHBOARD_LOOP_NAME => $loop_name } } : {},
    );
}

# write_bare_pidfile($name, $pid)
# Records a collector pid the way the lifecycle fixtures do: a pidfile and
# nothing else, so no loop state exists to confirm the loop's identity.
# Input: collector name string and pid integer.
# Output: pidfile path string.
sub write_bare_pidfile {
    my ( $name, $pid ) = @_;
    my $pidfile = $runner->_pidfile($name);
    open my $fh, '>', $pidfile or die "Unable to write $pidfile: $!";
    print {$fh} "$pid\n";
    close $fh or die "Unable to close $pidfile: $!";
    return $pidfile;
}

# reap_fixture_child($pid)
# Removes a fixture child unconditionally so no stray collector stand-in
# survives the test file.
# Input: child pid integer.
# Output: true value once the child process has been terminated and reaped.
sub reap_fixture_child {
    my ($pid) = @_;
    Developer::Dashboard::GoRoutine::terminate_process( $pid, 'KILL' );
    Developer::Dashboard::GoRoutine::wait_process($pid);
    return 1;
}

# A hand-written pidfile carries no loop state, so the only thing that marks the
# child as a managed loop is the process title it adopts after startup. Until
# then the runner correctly refuses to claim it - and that refusal, not a slow
# shutdown, is what a CPU-starved host turns into a test failure.
my $untitled = spawn_fixture_child( 0, undef );
write_bare_pidfile( 'fixture.untitled', $untitled );
ok(
    !$runner->_is_managed_loop( $untitled, 'fixture.untitled' ),
    'a bare pidfile whose child has not adopted the managed process title is not recognized as a managed loop',
);
is(
    wait_for_managed_loop( $runner, $untitled, 'fixture.untitled', timeout => 0.2 ),
    0,
    'wait_for_managed_loop gives up on its wall-clock budget instead of blocking for ever',
);

# The exact CI reading this file exists to explain. stop_loop takes its
# unmanaged branch, never signals the child, and returns the recorded pid, so
# The old waitpid assertion reported 0 - "the child is still there" - where the
# fixture expected -1.
is( $runner->stop_loop('fixture.untitled'), $untitled, 'stop_loop returns the recorded pid even for a loop it does not recognize' );
is( Developer::Dashboard::GoRoutine::process_running($untitled), 1, 'an unrecognized loop child is left running, which is the "got 0, expected -1" failure' );
ok( Developer::Dashboard::GoRoutine::process_running($untitled), 'the unrecognized loop child really is still alive rather than exited-but-unreaped' );
reap_fixture_child($untitled);

# running_loops is worse than a missed probe: it deletes the pidfile of any
# same-namespace pid it cannot recognize. A fixture that polls running_loops
# before its child is recognizable therefore destroys its own fixture on the
# first iteration, and no number of further iterations can recover it.
my $swept = spawn_fixture_child( 0, undef );
my $swept_pidfile = write_bare_pidfile( 'fixture.swept', $swept );
my @swept_rows = $runner->running_loops;
is( scalar( grep { $_->{name} eq 'fixture.swept' } @swept_rows ), 0, 'running_loops does not list a loop whose child has not adopted the managed title' );
ok( !-e $swept_pidfile, 'running_loops deletes the unrecognized pidfile, so a later poll iteration can never see the loop' );
reap_fixture_child($swept);

# Waiting on the runner's own predicate first makes both behaviours
# deterministic without weakening either assertion: the child is identified
# by its pre-exec marker where its title cannot be observed (qemu) and by
# its title where it can, and the shutdown still has to reap the child.
my $titled = spawn_fixture_child( 0, $runner->_process_title('fixture.titled'), 'fixture.titled' );
write_bare_pidfile( 'fixture.titled', $titled );
ok( wait_for_managed_loop( $runner, $titled, 'fixture.titled' ), 'wait_for_managed_loop reports success once the runner recognizes the child' );
is_deeply(
    [ map { $_->{name} } grep { $_->{name} eq 'fixture.titled' } $runner->running_loops ],
    ['fixture.titled'],
    'running_loops lists the loop once recognition has actually happened',
);
is( $runner->stop_loop('fixture.titled'), $titled, 'stop_loop terminates a recognized managed loop' );
is( Developer::Dashboard::GoRoutine::process_running($titled), 0, 'stop_loop terminates a recognized managed loop child' );

# The helper has to wait rather than probe once, which is what makes it a fix
# for a starved host instead of a restatement of the race. The child cannot be
# recognized before it adopts its title, so the elapsed time proves the wait.
#
# This case is skipped where the title is not observable at all: under qemu
# user-mode emulation the guest's $0 write never reaches the host's /proc,
# so no wait could ever observe the adoption and the elapsed-time assertion
# cannot be measured there. The titled case above still covers recognition
# on such a host, through the pre-exec marker.
SKIP: {
    skip 'a late-adopted process title is not observable under qemu user-mode emulation, so title-adoption timing cannot be measured there', 2
      if _running_under_qemu();
    my $late_delay = 3;
    # Start the clock before the spawn, so the measured time covers the spawn itself.
    my $started = Time::HiRes::time();
    my $late = spawn_fixture_child( $late_delay, $runner->_process_title('fixture.late') );
    write_bare_pidfile( 'fixture.late', $late );
    ok( wait_for_managed_loop( $runner, $late, 'fixture.late' ), 'wait_for_managed_loop recognizes a child that adopts its title late' );
    cmp_ok(
        Time::HiRes::time() - $started,
        '>=',
        $late_delay - 0.5,
        'the wait elapsed alongside the late title instead of succeeding on its first probe',
    );
    reap_fixture_child($late);
}

# Structural guard, and it is only structural: no behavioural test can inspect
# the ordering inside another suite file. Each fixture below hand-writes a
# collector pidfile and depends on title recognition, so each must wait before
# it probes. Every anchor is a method CALL rather than a bare method name,
# because a name also matches the prose in a comment explaining the rule - which
# is precisely what the first draft of this guard measured.
my @guards = (
    {
        file    => File::Spec->catfile( $repo_root, 't', '07-core-units.t' ),
        label   => q{t/07's manual collector shutdown fixture},
        between => qr/'manual\.pid'(.*?)\$runner->stop_loop\('manual'\)/s,
    },
    {
        file    => File::Spec->catfile( $repo_root, 't', '14-coverage-closure-extra.t' ),
        label   => q{t/14's managed-loop listing fixture},
        between => qr/my \$loop_name = 'coverage\.loop';(.*?)\$runner->running_loops/s,
    },
    {
        file    => File::Spec->catfile( $repo_root, 't', '14-coverage-closure-extra.t' ),
        label   => q{t/14's loop-name sorting fixture},
        between => qr/coverage\.sort-b coverage\.sort-a\)(.*?)\$runner->running_loops/s,
    },
);

for my $guard (@guards) {
    open my $fh, '<', $guard->{file} or die "Unable to read $guard->{file}: $!";
    my $content = do { local $/; <$fh> };
    close $fh or die "Unable to close $guard->{file}: $!";

    my ($region) = $content =~ $guard->{between};
    ok( defined $region, "$guard->{label} is locatable for the ordering guard" );
    like(
        defined $region ? $region : '',
        qr/wait_for_managed_loop/,
        "$guard->{label} waits for the runner to recognize its child before probing it",
    );
}

done_testing;

__END__

=pod

=head1 NAME

t/144-collector-fixture-recognition-race.t - collector lifecycle fixtures must wait for loop recognition

=head1 PURPOSE

This test is the executable contract behind a fix to three collector lifecycle
fixtures. It reproduces, deterministically, the two ways a hand-built collector
fixture fails when its child process has not yet adopted the managed process
title: C<stop_loop> takes its unmanaged branch and leaves the child running, and
C<running_loops> deletes the unrecognized pidfile outright. It then shows that
waiting on the runner's own identity predicate makes both paths deterministic,
and guards the ordering inside the two suite files that hold those fixtures.

=head1 WHY IT EXISTS

Two lifecycle assertions failed only when the host was CPU-constrained, which is
the shape of every CI runner: a reap check reported C<got 0, expected -1>, and a
loop-name sort found no rows. Both were traced to the same cause. A hand-written
pidfile carries no loop state, so the only evidence that the child is a managed
loop is the process title it adopts after startup, or the identity marker it is
spawned with; a starved host lets the
parent probe first. Production never hits this, because C<start_loop> writes loop
state alongside the pidfile and the state fallback confirms the loop regardless
of the title. The polling fix that looks obvious does not work either: the first
C<running_loops> call deletes the pidfile, so every later iteration is probing a
fixture that no longer exists. Waiting on the runner's predicate before the first
probe is the only order that holds, and this file keeps that order enforced.

=head1 WHEN TO USE

Use this file when changing collector loop identity resolution, C<stop_loop>,
C<running_loops>, the loop-state fallback, or any suite fixture that hand-writes
a collector pidfile and then asks the runner about it.

=head1 HOW TO USE

Run C<d2 docker compose exec dev prove -blv
t/144-collector-fixture-recognition-race.t> while iterating on collector
lifecycle behaviour, and keep it green under the Docker full suite and coverage
gate before release.

=head1 WHAT USES IT

Developers during TDD, the repository test suite, and the coverage gate use this
file to keep the collector lifecycle fixtures race-free.

=head1 EXAMPLES

Example 1:

  d2 docker compose exec dev prove -blv t/144-collector-fixture-recognition-race.t

Run the fixture recognition contract by itself.

Example 2:

  d2 docker compose exec dev prove -blr t

Run it inside the full repository suite before release.

Example 3:

  d2 docker compose exec dev prove -blv t/144-collector-fixture-recognition-race.t

Run the same race-sensitive contract in its supported Docker test environment.

=cut
