#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Cwd qw(abs_path getcwd);
use Errno ();
use File::Spec;
use Test::More;

use lib 't/lib';

use Local::DockerGuard;

my $ROOT = abs_path( getcwd() );

# A fixed "now" and a fixed staleness window keep every decision below a pure
# function of its inputs, so this file never depends on a docker daemon, on the
# host clock, or on which pids happen to exist while it runs.
my $NOW         = 1_786_000_000;
my $STALE_AFTER = 3600;

my $OWN = 'dd-smart-router-two-stage-4242-1785999900';

# Purpose: build the pid-liveness probe the decision function consults, from an
#          explicit set of pids the caller wants to pretend are still running.
# Input:   a list of pids to report as alive.
# Output:  a coderef taking one pid and returning true only for those pids.
sub alive_only {
    my (@alive) = @_;
    my %alive = map { $_ => 1 } @alive;
    return sub {
        my ($pid) = @_;
        return $alive{$pid} ? 1 : 0;
    };
}

subtest 'the reclaim decision only ever targets this guard\'s own container names' => sub {
    my @names = (
        'dd-smart-router-two-stage-111-1785000000',    # a real leak
        'dd-smart-router-two-stage',                   # prefix without the pid/epoch tail
        'dd-smart-router-two-stage-111',               # pid but no epoch
        'dd-smart-router-two-stage-abc-1785000000',    # non-numeric pid
        'dd-smart-router-two-stage-111-xyz',           # non-numeric epoch
        'my-dd-smart-router-two-stage-111-1785000000', # merely contains the prefix
        'dd-blank-env-integration-111-1785000000',     # another dashboard container
        'postgres',                                    # somebody else's container entirely
    );

    my @stale = Local::DockerGuard::stale_guard_containers(
        names       => \@names,
        own         => $OWN,
        now         => $NOW,
        stale_after => $STALE_AFTER,
        pid_alive   => alive_only(),
    );

    is_deeply(
        \@stale,
        ['dd-smart-router-two-stage-111-1785000000'],
        'only names matching the guard\'s own dd-smart-router-two-stage-<pid>-<epoch> shape are reclaimed',
    );
};

subtest 'the container this run owns is never reclaimed' => sub {
    my @stale = Local::DockerGuard::stale_guard_containers(
        names       => [ $OWN, 'dd-smart-router-two-stage-111-1785000000' ],
        own         => $OWN,
        now         => $NOW,
        stale_after => $STALE_AFTER,
        pid_alive   => alive_only(),
    );

    is_deeply(
        \@stale,
        ['dd-smart-router-two-stage-111-1785000000'],
        'the running guard\'s own container is excluded even though its pid probe is not consulted',
    );
};

subtest 'a container whose owning process is gone is reclaimed immediately' => sub {
    # The leak this ticket exists for: the run was SIGKILLed, so its END block
    # never ran, and its pid is long gone. It must not have to age out first.
    my $fresh_leak = sprintf 'dd-smart-router-two-stage-%d-%d', 777, $NOW - 5;

    my @stale = Local::DockerGuard::stale_guard_containers(
        names       => [$fresh_leak],
        own         => $OWN,
        now         => $NOW,
        stale_after => $STALE_AFTER,
        pid_alive   => alive_only(),
    );

    is_deeply(
        \@stale,
        [$fresh_leak],
        'a seconds-old container whose embedded pid is dead is reclaimed without waiting for the age window',
    );
};

subtest 'a concurrently running guard is left alone' => sub {
    my $concurrent = sprintf 'dd-smart-router-two-stage-%d-%d', 888, $NOW - 60;

    my @stale = Local::DockerGuard::stale_guard_containers(
        names       => [$concurrent],
        own         => $OWN,
        now         => $NOW,
        stale_after => $STALE_AFTER,
        pid_alive   => alive_only(888),
    );

    is_deeply( \@stale, [], 'a recent container whose owning pid is still alive is never removed underneath it' );
};

subtest 'the age window backstops pid recycling' => sub {
    # A dead run's pid can be handed to an unrelated live process, which would
    # make the liveness probe vouch for a container nobody owns. No guard run
    # lasts an hour, so age settles it.
    my $recycled = sprintf 'dd-smart-router-two-stage-%d-%d', 999, $NOW - $STALE_AFTER;

    my @stale = Local::DockerGuard::stale_guard_containers(
        names       => [$recycled],
        own         => $OWN,
        now         => $NOW,
        stale_after => $STALE_AFTER,
        pid_alive   => alive_only(999),
    );

    is_deeply(
        \@stale,
        [$recycled],
        'a container older than the staleness window is reclaimed even when its embedded pid resolves to a live process',
    );

    my $just_inside = sprintf 'dd-smart-router-two-stage-%d-%d', 999, $NOW - $STALE_AFTER + 1;

    my @kept = Local::DockerGuard::stale_guard_containers(
        names       => [$just_inside],
        own         => $OWN,
        now         => $NOW,
        stale_after => $STALE_AFTER,
        pid_alive   => alive_only(999),
    );

    is_deeply( \@kept, [], 'a live-owned container one second inside the window is still left alone' );
};

subtest 'a container stamped in the future is judged by its owner, not by its clock' => sub {
    my $skewed = sprintf 'dd-smart-router-two-stage-%d-%d', 555, $NOW + 120;

    my @alive_owner = Local::DockerGuard::stale_guard_containers(
        names       => [$skewed],
        own         => $OWN,
        now         => $NOW,
        stale_after => $STALE_AFTER,
        pid_alive   => alive_only(555),
    );

    is_deeply( \@alive_owner, [], 'a future-stamped container with a live owner is kept' );

    my @dead_owner = Local::DockerGuard::stale_guard_containers(
        names       => [$skewed],
        own         => $OWN,
        now         => $NOW,
        stale_after => $STALE_AFTER,
        pid_alive   => alive_only(),
    );

    is_deeply( \@dead_owner, [$skewed], 'a future-stamped container with a dead owner is still reclaimed' );
};

subtest 'reclaim_guard_containers lists, removes, and verifies through one injected runner' => sub {
    my $leak_one = 'dd-smart-router-two-stage-111-1785000000';
    my $leak_two = 'dd-smart-router-two-stage-222-1785000001';
    my @calls;
    my @listings = (
        join( "\n", $leak_one, $OWN, 'postgres', $leak_two ) . "\n",
        "$OWN\npostgres\n",
    );

    my @removed = Local::DockerGuard::reclaim_guard_containers(
        own         => $OWN,
        now         => $NOW,
        stale_after => $STALE_AFTER,
        pid_alive   => alive_only(),
        runner      => sub {
            my (@argv) = @_;
            push @calls, [@argv];
            return ( shift(@listings), q{}, 0 ) if $argv[1] eq 'ps';
            return ( q{}, q{}, 0 );
        },
    );

    is_deeply( [ sort @removed ], [ sort $leak_one, $leak_two ], 'both leaked containers are reported as reclaimed' );

    is_deeply(
        $calls[0],
        [ 'docker', 'ps', '-a', '--format', '{{.Names}}' ],
        'the container inventory comes from docker ps -a over names only',
    );
    is_deeply( $calls[1], [ 'docker', 'rm', '-f', $leak_one ], 'the first leak is force-removed by name' );
    is_deeply( $calls[2], [ 'docker', 'rm', '-f', $leak_two ], 'the second leak is force-removed by name' );
    is_deeply(
        $calls[3],
        [ 'docker', 'ps', '-a', '--format', '{{.Names}}' ],
        'removal is verified by re-reading the inventory instead of trusting the exit status',
    );
    is( scalar @calls, 4, 'no other docker command is issued' );
};

subtest 'nothing is removed and no verification pass runs when there is no leak' => sub {
    my @calls;

    my @removed = Local::DockerGuard::reclaim_guard_containers(
        own         => $OWN,
        now         => $NOW,
        stale_after => $STALE_AFTER,
        pid_alive   => alive_only(),
        runner      => sub {
            my (@argv) = @_;
            push @calls, [@argv];
            return ( "$OWN\npostgres\n", q{}, 0 );
        },
    );

    is_deeply( \@removed, [], 'a clean host reclaims nothing' );
    is( scalar @calls, 1, 'a clean host issues exactly one docker ps and no docker rm' );
};

subtest 'a container that survives its removal is a loud failure, not a silent one' => sub {
    my $leak = 'dd-smart-router-two-stage-111-1785000000';

    my $error = do {
        local $@;
        eval {
            Local::DockerGuard::reclaim_guard_containers(
                own         => $OWN,
                now         => $NOW,
                stale_after => $STALE_AFTER,
                pid_alive   => alive_only(),
                runner      => sub {
                    my (@argv) = @_;
                    return ( "$leak\n", q{}, 0 ) if $argv[1] eq 'ps';
                    return ( q{}, "permission denied while removing $leak\n", 1 );
                },
            );
            1;
        };
        $@;
    };

    like( $error, qr/\Q$leak\E/, 'the surviving container is named in the failure' );
    like( $error, qr/permission denied/, 'the docker error text is surfaced rather than swallowed' );
};

subtest 'a removal that races to success is not reported as a failure' => sub {
    # docker rm -f can exit non-zero because the container had already gone.
    # The outcome is what matters, so a non-zero exit with the container
    # actually absent afterwards must not fail the guard.
    my $leak = 'dd-smart-router-two-stage-111-1785000000';
    my @listings = ( "$leak\n", q{} );

    my @removed = Local::DockerGuard::reclaim_guard_containers(
        own         => $OWN,
        now         => $NOW,
        stale_after => $STALE_AFTER,
        pid_alive   => alive_only(),
        runner      => sub {
            my (@argv) = @_;
            return ( shift(@listings), q{}, 0 ) if $argv[1] eq 'ps';
            return ( q{}, "Error: No such container: $leak\n", 1 );
        },
    );

    is_deeply( \@removed, [$leak], 'a container that is gone afterwards counts as reclaimed whatever docker rm exited with' );
};

subtest 'an unreadable container inventory stops the guard instead of pretending the host is clean' => sub {
    my $error = do {
        local $@;
        eval {
            Local::DockerGuard::reclaim_guard_containers(
                own         => $OWN,
                now         => $NOW,
                stale_after => $STALE_AFTER,
                pid_alive   => alive_only(),
                runner      => sub { return ( q{}, "cannot connect to the docker daemon\n", 1 ) },
            );
            1;
        };
        $@;
    };

    like( $error, qr/docker ps/, 'the failing command is named' );
    like( $error, qr/cannot connect to the docker daemon/, 'the daemon error text is surfaced' );
};

subtest 'the default pid probe distinguishes a missing process from an unkillable one' => sub {
    ok( Local::DockerGuard::pid_alive($$), 'this test process is reported alive' );
    ok( Local::DockerGuard::pid_alive(1),  'pid 1 is reported alive even though this uid may not signal it' );
    ok( !Local::DockerGuard::pid_alive(0), 'pid 0 is never treated as an owner' );
    ok( !Local::DockerGuard::pid_alive(-1), 'a negative pid is never treated as an owner' );
    ok( !Local::DockerGuard::pid_alive(undef), 'an undefined pid is never treated as an owner' );

    my $unused = _unused_pid();
  SKIP: {
        skip 'no unused pid could be found on this host', 1 if !$unused;
        ok( !Local::DockerGuard::pid_alive($unused), 'a pid with no process behind it is reported dead' );
    }
};

subtest 'the smart-router guard actually reclaims before it creates its own container' => sub {
    my $guard = _slurp( File::Spec->catfile( $ROOT, 't', '44-smart-router-two-stage.t' ) );

    like(
        $guard,
        qr/unshift \s+ \@INC, \s* File::Spec->catdir\( \s* \$ROOT, \s* 't', \s* 'lib' \s* \);/mx,
        'the guard puts the repository test library on @INC by absolute path, not relative to the caller\'s cwd',
    );
    like( $guard, qr/^use \s+ Local::DockerGuard;/mx, 'the guard loads the reclaim helper' );
    like(
        $guard,
        qr/Local::DockerGuard::reclaim_guard_containers\(/,
        'the guard calls the reclaim helper',
    );

    my ($reclaim_at) = $guard =~ /(.*?)Local::DockerGuard::reclaim_guard_containers\(/s;
    my ($run_at)     = $guard =~ /(.*?)'docker',\s*'run',\s*'-d',/s;
    ok(
        defined $reclaim_at && defined $run_at && length($reclaim_at) < length($run_at),
        'the reclaim runs before this run creates its own container, so a leak is collected by the next run',
    );

    like(
        $guard,
        qr/^END \s* \{/mx,
        'the END-block teardown is kept as well, because reclaiming on start does not excuse leaking on a clean exit',
    );
};

done_testing();

# Purpose: read a repository file in full so the guard's own source can be
#          asserted against.
# Input:   an absolute path to a readable file.
# Output:  the file's contents as one string; dies when the file cannot be read.
sub _slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    local $/;
    my $contents = <$fh>;
    close $fh or die "Unable to close $path: $!";
    return $contents;
}

# Purpose: find a pid that has no process behind it, so the dead-owner branch of
#          the default liveness probe can be exercised for real.
# Input:   none.
# Output:  an unused pid, or undef when every probed pid is in use.
sub _unused_pid {
    for my $candidate ( 4_000_000 .. 4_000_200 ) {
        next if kill 0, $candidate;
        next if $! != Errno::ESRCH();
        return $candidate;
    }
    return undef;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

t/141-smart-router-guard-container-reclaim.t - the post-build docker guard collects its own leaked containers

=head1 PURPOSE

This test pins the reclaim contract that keeps the post-build smart-router
guard from leaking docker containers forever. That guard names its container
after the pid and epoch of the process that created it and removes it from an
C<END> block. An C<END> block does not run under C<SIGKILL>, and every
automation round in this repository runs under a C<timeout> that kills the
process tree when its budget expires, so a killed run leaves a container whose
name no later run recognises as its own. Nothing ever reclaims it. This file
asserts the replacement rule: before a run creates its container it removes
every guard container whose owning process is gone, or which is older than any
guard run can plausibly be, and it verifies the removal actually happened
instead of trusting an exit status.

=head1 WHY IT EXISTS

DD-448 found eight C<dd-smart-router-two-stage-*> containers still running on
the build host, the oldest three weeks old, each holding a bound loopback port
and a full dashboard process tree whose in-container processes are root-owned
and therefore invisible to the documented host-side stray-collector cleanup.
The guard is not skipped in ordinary runs — it skips only when the release
tarball is absent — so every full suite run on a host that has built a tarball
can add another one. A growing set of long-lived loopback port holders is
exactly the input that turns the guard's free-port search into an intermittent
failure that would be misread as flakiness.

The fix cannot be better teardown: C<SIGKILL> cannot be trapped and the
container is long-lived and exec'd into, so C<docker run --rm> does not apply
either. It has to be reclaim-on-next-start, which makes the reclaim decision
itself the thing worth testing — removing too much would destroy a concurrent
run's container, and removing too little leaves the leak.

=head1 WHEN TO USE

Use this file when changing how the post-build guard names, creates, or tears
down its container, when changing the staleness rule, or when adding another
docker-driven gate that creates a long-lived named container.

=head1 HOW TO USE

Run C<prove -lv t/141-smart-router-guard-container-reclaim.t> while iterating.
It needs no docker daemon: every decision is exercised through an injected
command runner and an injected pid probe, so it runs on any host.

=head1 WHAT USES IT

The repository test suite and developers changing C<t/44-smart-router-two-stage.t>
or C<t/lib/Local/DockerGuard.pm> use this file to keep the guard self-cleaning.

=head1 EXAMPLES

Example 1:

  prove -lv t/141-smart-router-guard-container-reclaim.t

Example 2:

  prove -lr t

=cut
