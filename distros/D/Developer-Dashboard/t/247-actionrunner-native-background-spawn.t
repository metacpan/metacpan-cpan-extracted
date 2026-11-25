#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::ActionRunner;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::GoRoutine ();
use Developer::Dashboard::JSON qw(json_decode);
use Developer::Dashboard::PathRegistry;

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to '$home': $!";

my $paths = Developer::Dashboard::PathRegistry->new(
    home            => $home,
    workspace_roots => [ File::Spec->catdir( $home, 'projects' ) ],
);
my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $runner = Developer::Dashboard::ActionRunner->new( files => $files, paths => $paths );

my ( $spawn_calls, $spawn_argv, $spawn_options ) = ( 0, undef, undef );
{
    no warnings 'redefine';
    local *Developer::Dashboard::GoRoutine::spawn = sub {
        ( $spawn_argv, $spawn_options ) = @_;
        $spawn_calls++;
        return 7319;
    };
    my $result = $runner->run_command_action(
        command    => 'echo background-action',
        cwd        => $home,
        env        => { DASHBOARD_BACKGROUND_TEST => 'present' },
        timeout_ms => 2500,
        background => 1,
    );

    is( $result->{pid}, 7319, 'background action returns the native spawned supervisor pid' );
    is( $result->{background}, 1, 'background action keeps its public background marker' );
}

is( $spawn_calls, 1, 'background action uses GoRoutine native process spawn exactly once' );
ok( ref($spawn_argv) eq 'ARRAY', 'native process spawn receives an argv array' );
ok( ref($spawn_options) eq 'HASH', 'native process spawn receives an options hash' );
is( $spawn_options->{cwd}, $home, 'native supervisor starts in the validated action cwd' );
is( $spawn_options->{process_group}, 1, 'native supervisor gets an isolated process group' );
is( $spawn_options->{stdin}, File::Spec->devnull(), 'native supervisor has no inherited stdin' );
is( $spawn_options->{stdout}, $files->dashboard_log, 'native supervisor stdout is recorded in the d2 log' );
is( $spawn_options->{stderr}, $files->dashboard_log, 'native supervisor stderr is recorded in the d2 log' );
is( $spawn_options->{env}{DASHBOARD_BACKGROUND_TEST}, 'present', 'action environment is passed to the native supervisor' );
my $supervisor_payload = json_decode( $spawn_argv->[-1] );
ok( ref($supervisor_payload) eq 'HASH', 'native supervisor receives a structured JSON payload' );
ok( !exists $supervisor_payload->{env}, 'private environment values are not exposed in the supervisor command line' );

done_testing;

__END__

=head1 NAME

t/247-actionrunner-native-background-spawn.t - specify native background process launch

=head1 DESCRIPTION

This Docker test specifies how Developer::Dashboard::ActionRunner launches a
trusted background command through Developer::Dashboard::GoRoutine's native
process API. It keeps the public result contract while ensuring the supervisor
is launched by an argv-based native process operation rather than a Perl fork.

=head1 PURPOSE

The background action implementation previously used a two-fork daemonization
path. This test records the replacement boundary: a process-group supervisor
must receive the already validated cwd, environment, log destinations, and
closed stdin behavior, then its process identifier is returned to the caller.

=head1 WHY IT EXISTS

GoRoutine's native process API supports Windows as well as POSIX systems, while
Perl fork is not portable to the requested Windows workflow. Verifying the
ActionRunner call contract prevents a future refactor from silently returning
to fork or dropping the background action's execution context.

=head1 WHEN TO USE

Run this test when changing ActionRunner background execution, GoRoutine
process spawning, process-group setup, or action environment propagation.

=head1 HOW TO USE

  d2 docker compose exec dev prove -lv t/247-actionrunner-native-background-spawn.t

The test creates a temporary dashboard home, substitutes the native spawn XSUB
to capture its exact arguments, and checks the process id and launch options.
No background process is launched by the test double.

=head1 WHAT USES IT

The distribution test harness runs this contract alongside the ActionRunner
and GoRoutine process suites. ActionRunner is the consumer of the public
background-action behavior specified here.

=head1 EXAMPLES

  my $result = $runner->run_command_action(
      command => 'echo hello', cwd => $workspace,
      background => 1, timeout_ms => 5000,
  );
  print $result->{pid};

The native process API receives the resolved command/supervisor argument list
and explicit working directory, environment, and output log paths.

=cut
