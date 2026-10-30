#!/usr/bin/env perl
# ABSTRACT: The monitor tool of the shell tools: gates, limits, the registry, kill_shell, teardown (ADR 0031, k169)
use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Langertha::Raider::BashTools;
use Langertha::Raider::Tasks;

my $loop = IO::Async::Loop->new;

sub shell {
  my ( %o ) = @_;
  my $tasks = Langertha::Raider::Tasks->new( loop => $loop );
  my $shell = Langertha::Raider::BashTools->new( loop => $loop, tasks => $tasks, kill_grace => 0.5, %o );
  return ( $shell, $tasks );
}

sub await_status {
  my ( $tasks, $id, $seconds ) = @_;
  my $deadline = Time::HiRes::time() + ( $seconds // 10 );
  $loop->await( $loop->delay_future( after => 0.02 ) ) while $tasks->get($id)->{status} eq 'running' && Time::HiRes::time() < $deadline;
  return $tasks->get($id)->{status};
}

use Time::HiRes ();

subtest 'the tool, its schema and where it is mounted' => sub {
  my ( $shell ) = shell();
  my %tool = map { $_->name => $_ } @{ $shell->server->tools };
  ok( $tool{monitor}, 'a tool of the shell server' );
  my $schema = $tool{monitor}->input_schema;
  is( [ sort keys %{ $schema->{properties} } ], [qw( command description timeout_ms )], 'description, timeout_ms, command' );
  is( $schema->{required}, [qw( description command )], 'description and command are required' );
  is( $schema->{properties}{timeout_ms}{default}, 300000, 'five minutes by default' );
  like( $tool{monitor}->description, qr/Each line the command writes to stdout is an event/, 'the text says what an event is' );
  like( $tool{monitor}->description, qr/default 300000, at most 1800000; at most 600000 in a run with a single prompt/, 'and the deadline' );

  my $bare = Langertha::Raider::BashTools->new( loop => $loop );
  ok( !( grep { $_->name eq 'monitor' } @{ $bare->server->tools } ), 'without a registry there is no monitor to notify' );
  my ( $text, $err ) = $bare->monitor({ description => 'd', command => 'true' });
  is( $err, 1, 'and calling it is an error' );
};

subtest 'input errors and the gates of bash' => sub {
  my ( $shell, $tasks ) = shell( allowed_commands => ['echo'] );
  my ( $text, $err ) = $shell->monitor({ description => 'd' });
  is( [ $text, $err ], [ 'No command given: the command parameter must be a non-empty string', 1 ], 'no command' );
  ( $text, $err ) = $shell->monitor({ command => 'echo hi' });
  is( [ $text, $err ], [ 'No description given: the description parameter must be a non-empty string', 1 ], 'no description' );
  ( $text, $err ) = $shell->monitor({ description => 'd', command => 'ls' });
  is( [ $text, $err ], [ 'Command not allowed: ls', 1 ], 'allowed_commands holds for a monitor too' );
  is( [ $tasks->entries( kind => 'monitor' ) ], [], 'nothing started' );

  ( $shell, $tasks ) = shell( validator => sub { $_[0] =~ /prove/ ? 'refused by loadguard: heavy' : 1 } );
  ( $text, $err ) = $shell->monitor({ description => 'd', command => 'prove -l t' });
  is( [ $text, $err ], [ 'Command refused by loadguard: heavy', 1 ], 'so does the loadguard validator' );
  ( $text, $err ) = $shell->monitor({ description => 'd', command => 'echo ok' });
  is( $err, 0, 'a command it passes starts' );
  await_status( $tasks, 'monitor_1' );
};

subtest 'the answer, the registry, and the deadlines' => sub {
  my ( $shell, $tasks ) = shell( monitor_min_timeout => 0.2 );
  my ( $text, $err ) = $shell->monitor({ description => 'a watch', command => 'sleep 30' }, { recipient => 'agent_3', call => 'c9' });
  is( $err, 0, 'started' );
  is( $text, "Monitor started (task monitor_1, expires in 5m unless the source ends first; you get one notice at expiry \x{2014} re-arm if you still need the watch). "
    ."You will be notified on each event. Keep working \x{2014} do not poll or sleep. Events may arrive while you are waiting for the user \x{2014} an event is not their reply. "
    .'Stop it with kill_shell (shell_id: monitor_1).', 'Claude Code\'s words, with the way to stop it' );
  my $entry = $tasks->get('monitor_1');
  like( $entry, { kind => 'monitor', status => 'running', description => 'a watch', recipient => 'agent_3', tool_use_id => 'c9', timeout => 300, background => T() }, 'the entry' );
  $tasks->stop('monitor_1');

  my %seconds;
  for my $case ( [ default => undef ], [ capped => 5_000_000 ], [ small => 50 ], [ 'string' => 'soon' ], [ zero => 0 ], [ minutes => 90_000 ] ) {
    my ( $name, $ms ) = @$case;
    my ( $s, $t ) = shell( monitor_min_timeout => 0.2 );
    $s->monitor({ description => $name, command => 'sleep 30', ( defined $ms ? ( timeout_ms => $ms ) : () ) });
    $seconds{$name} = $t->get('monitor_1')->{timeout};
    $t->stop('monitor_1');
  }
  is( \%seconds, { default => 300, capped => 1800, small => 0.2, string => 300, zero => 300, minutes => 90 },
    'the default, the cap of 30 minutes, the floor, nonsense falls back, milliseconds are seconds' );

  my ( $quiet, $t ) = shell( unattended => sub { 1 } );
  $quiet->monitor({ description => 'one prompt', command => 'sleep 30', timeout_ms => 1_800_000 });
  is( $t->get('monitor_1')->{timeout}, 600, 'a run nobody can answer watches at most 10 minutes' );
  $t->stop('monitor_1');
  my ( $attended, $t2 ) = shell( unattended => sub { 0 } );
  $attended->monitor({ description => 'a person', command => 'sleep 30', timeout_ms => 1_800_000 });
  is( $t2->get('monitor_1')->{timeout}, 1800, 'with a person the cap is 30 minutes' );
  $t2->stop('monitor_1');
};

subtest 'bash_output and kill_shell reach a monitor through the registry' => sub {
  my ( $shell, $tasks ) = shell();
  $shell->monitor({ description => 'the log', command => 'echo up; sleep 30' });
  my ( $text, $err ) = $shell->bash_output({ bash_id => 'monitor_1' });
  is( [ $text, $err ], [ '<status>running</status>', 0 ], 'bash_output tells the status' );
  ( $text, $err ) = $shell->kill_shell({ shell_id => 'monitor_1' });
  is( [ $text, $err ], [ 'Successfully stopped task: monitor_1 (the log)', 0 ], 'kill_shell stops it' );
  is( $tasks->get('monitor_1')->{status}, 'killed', 'the entry is killed' );
  ( $text, $err ) = $shell->kill_shell({ shell_id => 'monitor_1' });
  is( [ $text, $err ], [ 'Task monitor_1 is not running (status: killed)', 1 ], 'not twice' );
  my @notes = map { $_->{text} } $tasks->take('main');
  like( $notes[-1], qr{<status>killed</status>\n<summary>Monitor "the log" was stopped</summary>}, 'and the model is told' );
};

subtest 'background_pids keeps monitors across Ctrl-C; stop_all and teardown end them' => sub {
  my ( $shell, $tasks ) = shell();
  $shell->monitor({ description => 'one', command => 'sleep 30' });
  $shell->monitor({ description => 'two', command => 'sleep 30' });
  my @pids = $shell->background_pids;
  is( scalar @pids, 2, 'both pids are the session\'s' );
  ok( kill( 0 => $_ ), "alive: $_" ) for @pids;
  $shell->stop_all;
  ok( !kill( 0 => $_ ), "gone: $_" ) for @pids;
  is( [ map { $_->{status} } $tasks->entries( kind => 'monitor' ) ], [qw( killed killed )], 'both entries end' );
  is( [ $shell->background_pids ], [], 'nothing left' );

  my ( $s2, $t2 ) = shell();
  $s2->monitor({ description => 'three', command => 'sleep 30' });
  my ( $pid ) = $s2->background_pids;
  undef $s2;
  ok( !kill( 0 => $pid ), 'the application going away stops the monitor' );
  is( $t2->pending('main'), 0, 'and tells nobody' );
};

subtest 'async_tools: the caller is the recipient' => sub {
  my ( $shell, $tasks ) = shell();
  my $tools = $shell->async_tools( recipient => sub { 'agent_7' } );
  ok( $tools->{monitor}, 'the monitor is an asynchronous tool' );
  my $r = $tools->{monitor}{code}->( { description => 'x', command => 'echo hi' }, call => 'c3' )->get;
  like( $r->{content}[0]{text}, qr/\AMonitor started \(task monitor_1/, 'it ran' );
  like( $tasks->get('monitor_1'), { recipient => 'agent_7', tool_use_id => 'c3' }, 'for that caller and call' );
  await_status( $tasks, 'monitor_1' );
  is( scalar( () = $tasks->peek('agent_7') ), 0, 'nothing for a caller that is no entry (it is gone)' );
};

done_testing;
