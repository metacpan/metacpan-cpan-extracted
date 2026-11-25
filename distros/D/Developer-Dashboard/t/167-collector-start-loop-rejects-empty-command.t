#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::PathRegistry;

# Hermetic runtime in a throwaway HOME, with its own state root - the same
# isolation t/153 uses and for the same reason: without a distinct state root
# this collides with any other collector test's shared /tmp state tree.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
# Every collector loop this file starts is detached, and only the matching
# stop further down ends it. A run that is killed part-way never reaches
# that stop, and the loops then live on for days. Tie them to this test
# process: each loop ends itself once this pid is gone.
local $ENV{DEVELOPER_DASHBOARD_LIFETIME_PID} = $$;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
chdir $home or die "Unable to chdir to $home: $!";

my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
my $runner = Developer::Dashboard::CollectorRunner->new(
    collectors => Developer::Dashboard::Collector->new( paths => $paths ),
    files      => Developer::Dashboard::FileRegistry->new( paths => $paths ),
    indicators => Developer::Dashboard::IndicatorStore->new( paths => $paths ),
    paths      => $paths,
);

# DD-737: a collector config with neither 'command' nor 'code' used to be
# forked into a loop worker anyway, which then died on its very first tick
# inside _collector_source ("missing command or code") and every tick after
# that, forever - never disabling itself. Reproduced live in
# developer-dashboard:latest: a real config shaped exactly like this one
# ({interval:60, name:"docker"}, no command) left the collector retrying
# every 60 seconds indefinitely, and each time its loop-worker process died
# (from this error, or from a `d2 restart` cycle) it became an
# unreaped zombie under a PID 1 that does not auto-reap orphans - observed
# as hundreds of accumulated defunct "d2 collector: docker" entries
# on a real machine.
#
# The fix moves the validation _collector_source already performs on every
# tick to BEFORE start_loop forks anything at all, so a permanently
# misconfigured collector like this refuses to start with a clear,
# immediate, user-facing error instead of silently forking a doomed loop.

# AC-1/AC-2: a job with neither command nor code dies immediately, before
# any fork - no pid returned, no pidfile or loop state written.
{
    my $name = "no-command-probe-$$";
    my $job  = { name => $name, interval => 3600, mode => 'singleton' };

    my $died = eval { $runner->start_loop($job); 1 };
    ok( !$died, 'start_loop dies rather than forking a doomed loop' );
    like( $@, qr/Collector '\Q$name\E' missing command or code/,
        'and the die message is the same one _collector_source already produces on every failed tick' );

    my $pidfile = $runner->_pidfile($name);
    ok( !-f $pidfile, 'no pidfile was written - the rejection happened before any fork' );

    my $state = eval { $runner->loop_state($name) };
    ok( !$state || !%{ $state || {} }, 'no loop state was written either' );
}

# AC-1/AC-2, second shape: 'code' absent AND 'command' present-but-empty
# must be rejected the same way - an empty string is not a command.
{
    my $name = "empty-command-probe-$$";
    my $job  = { name => $name, interval => 3600, mode => 'singleton', command => '' };

    my $died = eval { $runner->start_loop($job); 1 };
    ok( !$died, 'start_loop rejects an empty-string command the same as a missing one' );
    like( $@, qr/Collector '\Q$name\E' missing command or code/, 'same die message' );
}

# AC-3: a normally-configured collector (real command) is completely
# unaffected - starts and loops exactly as it did before this change.
{
    my $name = "valid-command-probe-$$";
    my $job  = { name => $name, interval => 3600, mode => 'singleton', command => 'true' };

    my $pid = eval { $runner->start_loop($job) };
    ok( $pid, 'a normally-configured collector still starts' ) or diag($@);
    ok( kill( 0, $pid ), 'and a real loop-worker process exists' ) if $pid;

    $runner->stop_loop($name) if $pid;
}

done_testing;

__END__

=head1 NAME

t/167-collector-start-loop-rejects-empty-command.t - spec for DD-737's pre-fork validation

=head1 PURPOSE

Assert that C<start_loop> refuses a collector with neither C<command> nor
C<code> before forking anything, rather than forking a loop worker that
dies on every tick forever.

=head1 WHY IT EXISTS

DD-737: the owner reported hundreds of unreaped zombie
"d2 collector: docker" processes on a real machine, traced to a
collector config with no command that was silently forked into a loop
anyway, retrying and failing every interval without ever disabling itself.

=head1 WHEN TO USE

Whenever C<CollectorRunner::start_loop> or C<_collector_source> changes.

=head1 HOW TO USE

    PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/167-collector-start-loop-rejects-empty-command.t

=head1 WHAT USES IT

Nothing outside this spec directly; it protects C<CollectorRunner::start_loop>,
which C<d2 collector start> and C<d2 restart> both call.

=head1 EXAMPLES

The assertion that matters reads as the property it protects:

    a collector with no command dies before anything is forked, not after

=cut
