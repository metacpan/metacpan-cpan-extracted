#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(getcwd);
use File::Spec;
use Test::More;

use lib 'lib';

use Developer::Dashboard::RuntimeManager;
use Developer::Dashboard::CollectorRunner;

my $inc_base = getcwd();
my @expected_inc_args = map { '-I' . File::Spec->rel2abs($_, $inc_base) } grep { defined && !ref && length } @INC;

{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_current_perl_command = sub { return '/active/perl' };
    local *Developer::Dashboard::RuntimeManager::_dashboard_core_helper_path = sub { return '/active/_dashboard-core' };

    my $manager = bless {}, 'Developer::Dashboard::RuntimeManager';
    my @command = $manager->_background_collector_supervisor_command;
    is_deeply(
        \@command,
        [ '/active/perl', @expected_inc_args, '/active/_dashboard-core', 'collector-supervisor-foreground' ],
        'collector supervisor command preserves the active Perl module search path',
    );

    my @web = $manager->_windows_background_web_command( host => '127.0.0.1', port => 7890, workers => 2 );
    is_deeply(
        \@web,
        [ '/active/perl', @expected_inc_args, '/active/_dashboard-core', 'web-foreground', '--host', '127.0.0.1', '--port', 7890, '--workers', 2 ],
        'detached web command preserves the active Perl module search path',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_current_perl_command = sub { return '/active/perl' };
    local *Developer::Dashboard::CollectorRunner::_dashboard_core_helper_path = sub { return '/active/_dashboard-core' };
    # The runner here is a bare bless with no paths, so the runtime key it
    # would resolve from its state root is stubbed to a fixed 32-hex value.
    local *Developer::Dashboard::CollectorRunner::_runtime_state_key = sub { return '0123456789abcdef0123456789abcdef' };

    my $runner = bless {}, 'Developer::Dashboard::CollectorRunner';
    my @command = $runner->_windows_background_loop_command('sample.loop');
    is_deeply(
        \@command,
        [ '/active/perl', @expected_inc_args, '/active/_dashboard-core', 'collector-loop-foreground', '--name', 'sample.loop', '--runtime', '0123456789abcdef0123456789abcdef' ],
        'collector loop command preserves the active Perl module search path',
    );

    my @worker = $runner->_windows_background_worker_command('sample.loop', 4242);
    is_deeply(
        \@worker,
        [ '/active/perl', @expected_inc_args, '/active/_dashboard-core', 'collector-worker-foreground', '--name', 'sample.loop', '--loop-pid', 4242 ],
        'collector worker command preserves the active Perl module search path',
    );
}

done_testing;

__END__

=head1 NAME

t/236-process-library-path-propagation.t - child process Perl library path contract

=head1 PURPOSE

Verifies that detached collector supervisor, loop, and worker commands preserve
the module search paths of the Perl interpreter that created them.

=head1 WHY IT EXISTS

A native child process does not inherit Perl's in-memory C<@INC> the way a forked
interpreter does. If the helper is launched without those paths, it may load an
older installed Developer Dashboard or fail to load the active build's modules.
This regression contract makes the runtime's child command carry the active
interpreter paths explicitly.

=head1 WHEN TO USE

Run when changing the process launch helpers, Perl module path setup, or the
GoRoutine native process API. It is also part of the distribution test suite.

=head1 HOW TO USE

  d2 docker compose exec dev prove -lv t/236-process-library-path-propagation.t

The test supplies a known Perl executable and helper path, then compares each
collector command with the active test interpreter's string-valued C<@INC>
entries. Reference entries are intentionally not converted to command-line
paths.

=head1 WHAT USES IT

The distribution test harness runs this contract with the collector lifecycle
tests. RuntimeManager and CollectorRunner use the same process path helper when
launching detached collector commands.

=head1 EXAMPLES

Run just this regression test:

  d2 docker compose exec dev prove -lv t/236-process-library-path-propagation.t

Run it with the related process migration contracts:

  d2 docker compose exec dev prove -lv t/234-collector-goroutine-worker.t t/235-runtime-manager-goroutine-supervisor.t t/236-process-library-path-propagation.t

=cut
