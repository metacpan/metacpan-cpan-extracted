#!/usr/bin/env perl
# ABSTRACT: The task registry: agent IDs, entries, the notification queue and its text (ADR 0027 §1, §4, k161)
use strict;
use warnings;
use Test2::V0;
use Future;
use IO::Async::Loop;
use Langertha::Raider::Tasks;

subtest 'IDs: a counter per kind, skipping taken ones; explicit IDs move it' => sub {
  my $tasks = Langertha::Raider::Tasks->new;
  is( $tasks->next_id('agent'), 'agent_1', 'agent_1' );
  is( $tasks->next_id('agent'), 'agent_2', 'counts on' );
  is( $tasks->next_id('bash'),  'bash_1',  'every kind counts for itself' );
  is( $tasks->next_id( 'agent', taken => sub { $_[0] eq 'agent_3' || $_[0] eq 'agent_4' } ), 'agent_5',
    'skips what taken says is taken' );
  $tasks->add( id => 'agent_9', kind => 'agent' );
  is( $tasks->next_id('agent'), 'agent_10', 'an explicit ID moves the counter past it' );
  $tasks->add( id => 'agent_11', kind => 'agent' );
  is( $tasks->next_id('agent'), 'agent_12', 'and skips IDs in use' );
  like( dies { $tasks->add( id => 'agent_9', kind => 'agent' ) }, qr/task agent_9 exists/, 'an ID is registered once' );
  like( dies { $tasks->add( kind => 'agent' ) }, qr/needs an id and a kind/, 'id and kind required' );
};

subtest 'entries: running by default, found by ID or newest name, filtered, finished' => sub {
  my $tasks = Langertha::Raider::Tasks->new;
  my $a1 = $tasks->add( id => 'agent_1', kind => 'agent', name => 'rev', recipient => 'main', background => 1 );
  is( $a1->{status}, 'running', 'running by default' );
  $tasks->add( id => 'agent_2', kind => 'agent', name => 'rev', recipient => 'agent_1', background => 0 );
  $tasks->add( id => 'bash_1', kind => 'bash', recipient => 'main', background => 1 );
  is( $tasks->find('agent_1')->{id}, 'agent_1', 'by ID' );
  is( $tasks->find('rev')->{id}, 'agent_2', 'by name: the newest wins' );
  is( $tasks->find('nope'), undef, 'nothing' );
  is( [ map { $_->{id} } $tasks->running( recipient => 'main', background => 1 ) ], [qw( agent_1 bash_1 )], 'running, filtered' );
  is( [ map { $_->{id} } $tasks->running( background => 0 ) ], ['agent_2'], 'a false background matches an unset one too' );
  $tasks->finish( 'agent_1', 'completed', report => 'R' );
  like( $tasks->get('agent_1'), { status => 'completed', report => 'R' }, 'finish sets status and fields' );
  is( [ map { $_->{id} } $tasks->running( kind => 'agent' ) ], ['agent_2'], 'no longer running' );
  is( $tasks->find('agent_1')->{id}, 'agent_1', 'but still there' );
};

subtest 'stop: through the entry, only while running; stop_all returns the futures' => sub {
  my $tasks = Langertha::Raider::Tasks->new;
  my @stopped;
  my $f = Future->new;
  $tasks->add( id => 'agent_1', kind => 'agent', stop => sub { push @stopped, 1 }, future => $f );
  $tasks->add( id => 'agent_2', kind => 'agent', stop => sub { push @stopped, 2 }, status => 'completed' );
  ok( $tasks->stop('agent_1'), 'stops a running one' );
  ok( !$tasks->stop('agent_2'), 'not a finished one' );
  ok( !$tasks->stop('agent_3'), 'not an unknown one' );
  my @futures = $tasks->stop_all;
  is( \@stopped, [ 1, 1 ], 'stop_all asked the running one again' );
  is( scalar @futures, 1, 'its future' );
  ok( $tasks->get('agent_1')->{future}, 'held while not ready' );
  $f->done;
  ok( !$tasks->get('agent_1')->{future}, 'dropped once ready' );
};

subtest 'the queue: per recipient, notifications merged, plain messages apart, waiters woken' => sub {
  my $tasks = Langertha::Raider::Tasks->new;
  my $w = $tasks->wait_f('main');
  ok( !$w->is_ready, 'nothing waits yet' );
  $tasks->notify( main => 'N1', id => 'agent_1', label => 'background agent agent_1 finished' );
  ok( $w->is_done, 'the waiter is woken (no loop: at once)' );
  ok( $tasks->wait_f('main')->is_done, 'a new wait is done at once while something waits' );
  $tasks->notify( main => 'N2' );
  $tasks->post( main => 'plain' );
  $tasks->notify( main => 'N3' );
  $tasks->post( agent_1 => 'for the agent' );
  is( $tasks->pending('main'), 4, 'four for main' );
  is( [ map { $_->{label} } $tasks->peek('main') ], [ 'background agent agent_1 finished', undef, undef, undef ], 'peek' );
  my @messages = $tasks->take_messages('main');
  is( [ map { [ $_->{content}, $_->{notification} ] } @messages ],
    [ [ "N1\nN2", 1 ], [ 'plain', undef ], [ 'N3', 1 ] ], 'notifications due together form one message, in order' );
  is( $tasks->pending('main'), 0, 'taken' );
  is( $tasks->pending('agent_1'), 1, 'the other recipient keeps its own' );
  my $w2 = $tasks->wait_f('agent_2');
  $tasks->discard('agent_1');
  is( $tasks->pending('agent_1'), 0, 'discard drops' );
  ok( !$w2->is_ready, 'and wakes only its own waiters' );
};

subtest 'with a loop the waiters wake on its next turn' => sub {
  my $loop = IO::Async::Loop->new;
  my $tasks = Langertha::Raider::Tasks->new( loop => $loop );
  my $w = $tasks->wait_f('main');
  $tasks->notify( main => 'N' );
  ok( !$w->is_ready, 'not inside notify' );
  $loop->await($w);
  ok( $w->is_done, 'on the loop' );
};

subtest 'the notification text: Claude Code\'s form, escaped, only what is given' => sub {
  my $tasks = Langertha::Raider::Tasks->new;
  is( $tasks->notification_text(
    task_id     => 'agent_1',
    tool_use_id => 'c3',
    status      => 'completed',
    summary     => 'Agent "Find <it>" finished',
    result      => "a < b && c > d\nline 2",
    usage       => [ subagent_tokens => 1200, tool_uses => 4, duration_ms => 5300 ],
  ), join( "\n",
    '<task-notification>',
    '<task-id>agent_1</task-id>',
    '<tool-use-id>c3</tool-use-id>',
    '<status>completed</status>',
    '<summary>Agent "Find &lt;it&gt;" finished</summary>',
    "<result>a &lt; b &amp;&amp; c &gt; d\nline 2</result>",
    '<usage><subagent_tokens>1200</subagent_tokens><tool_uses>4</tool_uses><duration_ms>5300</duration_ms></usage>',
    '</task-notification>',
  ), 'completed' );
  is( $tasks->notification_text( task_id => 'bash_1', status => 'failed', summary => 'Background command "x" completed (exit code 1)' ),
    "<task-notification>\n<task-id>bash_1</task-id>\n<status>failed</status>\n"
    ."<summary>Background command \"x\" completed (exit code 1)</summary>\n</task-notification>",
    'kind-agnostic: no result, no usage when not given' );
  like( $tasks->notification_text( task_id => 'agent_1', status => 'completed', summary => 's',
    worktree => { path => '/w/agent_1', branch => 'worktree-agent_1' } ),
    qr{^<worktree><worktreePath>/w/agent_1</worktreePath><worktreeBranch>worktree-agent_1</worktreeBranch></worktree>$}m,
    'a worktree element when given' );
  is( $tasks->escape('&<>'), '&amp;&lt;&gt;', 'escape' );
};

subtest 'the reminder: Claude Code\'s wrapper for a notification next to a genuine message' => sub {
  my $text = Langertha::Raider::Tasks->new->reminder_text("<task-notification>\nX\n</task-notification>");
  like( $text, qr/\A<system-reminder>\n\[SYSTEM NOTIFICATION - NOT USER INPUT\]\n/, 'opens as Claude Code\'s' );
  like( $text, qr/It is delivered in the same turn as a genuine message from the user/, 'the same-turn wording' );
  like( $text, qr/\n\n<task-notification>\nX\n<\/task-notification>\n<\/system-reminder>\z/, 'the notification last' );
};

done_testing;
