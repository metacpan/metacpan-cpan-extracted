#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Developer::Dashboard;

{
    package Local::DashboardExplicitImport;
    use Developer::Dashboard qw(d2 channel);
    ::ok( defined &d2, 'explicit facade import can select d2' );
    ::ok( defined &channel, 'explicit facade import can select a GoRoutine API' );
    ::ok( !defined &go, 'explicit facade import does not add unrequested GoRoutine APIs' );
}

package main;

my @api = qw(
    go wait_all share channel spawn process_running process_exited
    wait_process terminate_process
);

ok( defined &d2, 'use Developer::Dashboard continues to import d2' );
is_deeply(
    [ sort @Developer::Dashboard::GoRoutine::EXPORT ],
    [ sort @api ],
    'the facade export contract includes every GoRoutine public function',
);

for my $name (@api) {
    ok( Developer::Dashboard->can($name), "Developer::Dashboard defines $name" );
    ok( defined &{$name}, "use Developer::Dashboard imports $name" );
}

share my $count = 0;
my $worker = go sub { $count++ };
isa_ok( $worker, 'Developer::Dashboard::GoRoutine::Routine', 'go returns a routine handle' );
wait_all();
is( $count, 1, 'shared scalar is visible after waiting for the worker' );

our $named_call_count = 0;
share $named_call_count;
sub _increment_dashboard_export_count { $named_call_count++ }
go _increment_dashboard_export_count();
wait_all();
is( $named_call_count, 1, 'GoRoutine named-call shorthand is installed by the facade import' );

my $channel = channel(1);
$channel->send('ready');
is( $channel->receive, 'ready', 'imported channel creates a working channel' );

my $pid = spawn( [ $^X, '-e', 'exit 0' ], {} );
ok( process_running($pid), 'spawn returns a process id recognized by process_running' );
is( wait_process($pid), 0, 'wait_process reaps the spawned process' );
ok( process_exited($pid), 'process_exited reports the reaped process as exited' );
ok( !terminate_process($pid, 'TERM'), 'terminate_process reports an already exited process' );

done_testing();

__END__

=pod

=head1 NAME

t/248-dashboard-goroutine-exports.t - verify GoRoutine APIs are exported by Developer::Dashboard

=head1 PURPOSE

This test verifies the public convenience import from C<Developer::Dashboard>
includes the existing native GoRoutine callback, shared-value, channel, and
process APIs.

=head1 WHY IT EXISTS

GoRoutine began as a separate namespaced module. The Dashboard facade is also
expected to provide those functions beside C<d2>, without requiring consumers
to change their existing C<use Developer::Dashboard> statement. This test
protects both symbol availability and representative runtime behavior.

=head1 WHEN TO USE

Run this test when changing the Dashboard import/export surface, the GoRoutine
API, or the XS bundle that implements its native operations.

=head1 HOW TO USE

Run it through the project's dev Docker service:

  d2 docker compose exec -T dev prove -lv t/248-dashboard-goroutine-exports.t

It checks that every public GoRoutine API is callable after importing the
Dashboard facade, runs a small shared-state worker, exchanges a channel value,
and starts and reaps a short child process.

=head1 WHAT USES IT

The test uses C<Developer::Dashboard>, C<Developer::Dashboard::GoRoutine>,
the distribution XS extension, and Perl's C<Test::More> harness. It is part of
the standard distribution test suite.

=head1 EXAMPLES

The import contract exercised here is:

  use Developer::Dashboard;
  my $worker = go sub { ... };
  wait_all();

The same import also provides C<share>, C<channel>, and the native child
process functions such as C<spawn> and C<wait_process>.

=cut
