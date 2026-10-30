#!/usr/bin/env perl
# ABSTRACT: One monitor: stdout lines become batched notifications, the end and the limits notify once (ADR 0031, k169)
use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Path::Tiny;
use Langertha::Raider::Monitor;
use Langertha::Raider::Tasks;

my $loop = IO::Async::Loop->new;
my $dir  = Path::Tiny->tempdir;
my $count = 0;

# Starts a monitor and runs the loop until it has ended.
sub watch {
  my ( $command, %o ) = @_;
  my $tasks = $o{tasks} // Langertha::Raider::Tasks->new( loop => $loop );
  my $done  = $loop->new_future;
  my $n     = ++$count;
  my $monitor = Langertha::Raider::Monitor->new(
    id            => $tasks->next_id('monitor'),
    loop          => $loop,
    tasks         => $tasks,
    command       => $command,
    description   => $o{description} // 'test watch',
    tool_use_id   => 'c1',
    timeout       => 20,
    batch_window  => 0.05,
    stderr_file   => $dir->child( 'err'.$n.'-'.$$ ),
    on_end        => sub { $done->done unless $done->is_ready },
    %{ $o{args} // {} },
  );
  my $error = $monitor->start;
  die $error if $error;
  $o{before}->( $monitor, $tasks ) if $o{before};
  $loop->await( Future->wait_any( $done, $loop->delay_future( after => 15 )->then_fail('the monitor did not end') ) );
  return ( $monitor, $tasks, [ map { $_->{text} } $tasks->take('main') ] );
}

sub event_of { my ( $text ) = @_; $text =~ m{<event>(.*?)</event>}s ? $1 : undef }

subtest 'each line is an event; lines close together are one notification' => sub {
  my ( $monitor, $tasks, $notes ) = watch( q{printf 'a\nb\n'; sleep 0.4; printf 'c\n'} );
  is( scalar @$notes, 3, 'two events and the end' );
  is( $notes->[0], "<task-notification>\n<task-id>monitor_1</task-id>\n<tool-use-id>c1</tool-use-id>\n"
    ."<summary>Monitor event: \"test watch\"</summary>\n<event>a\nb</event>\n</task-notification>",
    'the first two lines are one event, in Claude Code\'s form' );
  is( event_of( $notes->[1] ), 'c', 'the later line is another' );
  is( $notes->[2], "<task-notification>\n<task-id>monitor_1</task-id>\n<tool-use-id>c1</tool-use-id>\n<status>completed</status>\n"
    ."<summary>Monitor \"test watch\" ended (exit code 0)</summary>\n</task-notification>", 'the end' );
  is( $tasks->get('monitor_1')->{status}, 'completed', 'the entry is complete' );
  is( $tasks->get('monitor_1')->{kind}, 'monitor', 'of kind monitor' );
  is( $monitor->events, 2, 'two events counted' );
};

subtest 'the last line needs no newline; text is escaped; UTF-8 survives' => sub {
  my ( undef, undef, $notes ) = watch( q{printf 'a < b & c > d\n\xc3\xa4\xc3\xb6 tail'} );
  is( event_of( $notes->[0] ), "a &lt; b &amp; c &gt; d\n\x{e4}\x{f6} tail", 'escaped, decoded, the partial line kept' );
};

subtest 'stderr is no event; a failure carries its tail' => sub {
  my ( undef, $tasks, $notes ) = watch( q{echo out; echo oops >&2; echo second >&2; exit 3} );
  is( scalar @$notes, 2, 'the event and the end' );
  is( event_of( $notes->[0] ), 'out', 'only stdout' );
  like( $notes->[1], qr{<status>failed</status>\n<summary>Monitor "test watch" failed with exit code 3</summary>\n<result>oops\nsecond</result>},
    'failed with the exit code and the stderr tail' );
  is( $tasks->get('monitor_1')->{status}, 'failed', 'the entry failed' );
  is( $tasks->get('monitor_1')->{exit_code}, 3, 'with its exit code' );
};

subtest 'the deadline stops the command and says so once' => sub {
  my ( $monitor, $tasks, $notes ) = watch( q{echo up; sleep 30}, args => { timeout => 0.3 } );
  is( scalar @$notes, 2, 'the event and one notice' );
  like( $notes->[1], qr{<status>killed</status>\n<summary>Monitor "test watch" timed out after 0\.3s</summary>\n<result>The watch ended at its deadline\. Start it again with monitor if you still need it\.</result>},
    'timed out, with the hint to start it again' );
  ok( !kill( 0 => $monitor->pid ), 'the command is gone' );
  is( $tasks->get('monitor_1')->{status}, 'killed', 'the entry ends killed' );
};

subtest 'too many events stop the stream' => sub {
  my ( $monitor, $tasks, $notes ) = watch( q{for i in $(seq 1 200); do echo line$i; sleep 0.01; done},
    args => { batch_window => 0.001, burst_limit => 4, burst_window => 30 } );
  my @events = grep { /Monitor event/ } @$notes;
  is( scalar @events, 4, 'the limit of events came through' );
  like( $notes->[-1], qr{<status>killed</status>\n<summary>Monitor "test watch" was stopped: too many events</summary>\n<result>It sent more than 4 notifications within 30 seconds\. Start it again with a command that prints less},
    'then it was stopped, with advice' );
  ok( !kill( 0 => $monitor->pid ), 'the command is gone' );
  my $after = scalar @{ [ $tasks->take('main') ] };
  is( $after, 0, 'and nothing comes after' );
};

subtest 'the total number of events is limited too' => sub {
  my ( undef, undef, $notes ) = watch( q{for i in 1 2 3 4 5 6 7 8; do echo l$i; sleep 0.05; done},
    args => { batch_window => 0.001, event_limit => 3, burst_limit => 100 } );
  is( scalar( grep { /Monitor event/ } @$notes ), 3, 'three events' );
  like( $notes->[-1], qr{too many events.*more than 3 notifications\.}s, 'then the stop' );
};

subtest 'stopped from outside' => sub {
  my ( $monitor, $tasks, $notes ) = watch( q{echo hi; sleep 30}, before => sub {
    my ( $m, $t ) = @_;
    $loop->await( $loop->delay_future( after => 0.3 ) );
    ok( $t->stop($m->id), 'the registry asks it to stop' );
  } );
  is( scalar @$notes, 2, 'the event and one notice' );
  like( $notes->[1], qr{<status>killed</status>\n<summary>Monitor "test watch" was stopped</summary>}, 'was stopped' );
  ok( !kill( 0 => $monitor->pid ), 'the command is gone' );
  ok( !$tasks->stop( $monitor->id ), 'it can be stopped once' );
};

subtest 'a long line and a long batch are cut' => sub {
  my ( undef, undef, $notes ) = watch( q{head -c 300 /dev/zero | tr '\0' x; echo},
    args => { line_limit => 50 } );
  like( event_of( $notes->[0] ), qr/\Ax{50} \.\.\. \[line truncated\]\z/, 'the line is cut' );
  ( undef, undef, $notes ) = watch( q{for i in 1 2 3 4 5 6; do echo 0123456789; done},
    args => { batch_limit => 25, batch_window => 0.2 } );
  like( event_of( $notes->[0] ), qr/\A(?:0123456789\n){2}012\n\.\.\. \[\d+ more characters not shown\]\z/, 'the batch is cut' );
};

subtest 'a subagent that has ended hears nothing' => sub {
  my $tasks = Langertha::Raider::Tasks->new( loop => $loop );
  $tasks->add( id => 'agent_1', kind => 'agent' );
  my ( undef, undef, $notes ) = watch( q{echo one; sleep 0.2; echo two}, tasks => $tasks, args => { recipient => 'agent_1' },
    before => sub { $tasks->finish( 'agent_1', 'completed' ) } );
  is( $notes, [], 'nothing for main' );
  is( [ $tasks->take('agent_1') ], [], 'and nothing for the finished agent' );

  $tasks = Langertha::Raider::Tasks->new( loop => $loop );
  $tasks->add( id => 'agent_1', kind => 'agent' );
  watch( q{echo one}, tasks => $tasks, args => { recipient => 'agent_1' } );
  my @for_agent = $tasks->take('agent_1');
  is( scalar @for_agent, 2, 'a running agent gets the event and the end' );
};

subtest 'the working directory, and no standard input' => sub {
  my ( undef, undef, $notes ) = watch( q{pwd; cat; echo eof-seen}, args => { working_directory => ''.$dir->realpath } );
  like( event_of( $notes->[0] ), qr/\A\Q$dir\E\neof-seen\z/, 'runs where it is told, with stdin from /dev/null' );
};

subtest 'a command that cannot start in its directory ends failed' => sub {
  my ( undef, undef, $notes ) = watch( q{echo never}, args => { working_directory => '/no/such/dir/here' } );
  like( $notes->[-1], qr/<status>failed<\/status>.*exit code 1.*cannot change to \/no\/such\/dir\/here/s, 'failed with the reason' );
};

done_testing;
