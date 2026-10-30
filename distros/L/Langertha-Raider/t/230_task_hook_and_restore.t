#!/usr/bin/env perl
# ABSTRACT: TodoTools before_task (TaskCreated/TaskCompleted) and restore_tasks; Journal->tasks (ADR 0022 addendum, ADR 0025)
use strict;
use warnings;
use Test2::V0;
use Langertha::Raider::TodoTools;
use Langertha::Raider::Session::Journal;

sub journal { Langertha::Raider::Session::Journal->new( events => [@_] ) }

subtest 'before_task sees a new task before it exists; a text blocks the creation' => sub {
  my ( @seen, $block );
  my $t;
  $t = Langertha::Raider::TodoTools->new( before_task => sub {
    my ( $event, $item ) = @_;
    push @seen, [ $event, $item->{id}, $item->{content}, $item->{description}, scalar @{ $t->tasks } ];
    return $block;
  } );
  is( [ $t->create_task( { subject => 'Run', description => 'prove' } ) ], [ 'Task #1 created successfully: Run', 0 ], 'goes on' );
  is( $seen[0], [ 'TaskCreated', '1', 'Run', 'prove', 0 ], 'event, id, subject, description; the list is still empty' );

  $block = 'TaskCreated hook error: no vague tasks';
  is( [ $t->create_task( { subject => 'Do it', description => 'x' } ) ], [ $block, 1 ], 'blocked: the text, as an error' );
  is( [ map { $_->{content} } @{ $t->tasks } ], ['Run'], 'nothing was added' );
  $block = undef;
  is( [ $t->create_task( { subject => 'Do it', description => 'x' } ) ], [ 'Task #2 created successfully: Do it', 0 ],
    'a blocked creation does not use up its id' );
};

subtest 'before_task runs when a task becomes completed, once' => sub {
  my ( @seen, $block );
  my $t = Langertha::Raider::TodoTools->new( before_task => sub { push @seen, [ $_[0], $_[1]{id}, $_[1]{status} ]; return $block if $_[0] eq 'TaskCompleted'; return } );
  $t->create_task( { subject => 'A', description => 'a' } );
  @seen = ();
  $t->update_task( { taskId => '1', status => 'in_progress' } );
  is( \@seen, [], 'in_progress is no TaskCompleted' );
  $block = 'TaskCompleted hook error: tests are not green';
  is( [ $t->update_task( { taskId => '1', status => 'completed', subject => 'A2' } ) ], [ $block, 1 ], 'blocked' );
  is( \@seen, [ [ 'TaskCompleted', '1', 'completed' ] ], 'the hook got the task as completed' );
  is( $t->tasks->[0]{status}, 'in_progress', 'the status stays' );
  is( $t->tasks->[0]{content}, 'A', 'and no other field of the same call applies' );
  $block = undef;
  is( [ $t->update_task( { taskId => '1', status => 'completed' } ) ], [ 'Updated task #1 status', 0 ], 'allowed' );
  @seen = ();
  $t->update_task( { taskId => '1', status => 'completed' } );
  is( \@seen, [], 'already completed: no second TaskCompleted' );
  $t->update_task( { taskId => '1', status => 'deleted' } );
  is( \@seen, [], 'deleting is no TaskCompleted' );
};

subtest 'todo_write fires no task hook' => sub {
  my $called = 0;
  my $t = Langertha::Raider::TodoTools->new( before_task => sub { $called++; 'x' } );
  my ($tool) = grep { $_->name eq 'todo_write' } @{ $t->server->tools };
  my $r = $tool->code->( $tool, { todos => [ { content => 'a', status => 'completed' } ] } );
  ok( !$r->{isError}, 'accepted' );
  is( $called, 0, 'no hook' );
};

subtest 'restore_tasks takes a list over, silently, and goes on counting' => sub {
  my @updates;
  my $t = Langertha::Raider::TodoTools->new( on_update => sub { push @updates, $_[0] }, before_task => sub { die 'no hook on restore' } );
  my $list = [
    { id => '2', content => 'Two', description => 'second', status => 'completed', activeForm => 'Two', blocks => ['5'], blockedBy => [] },
    { id => '5', content => 'Five', description => 'fifth', status => 'in_progress', activeForm => 'Fiving', blocks => [], blockedBy => ['2'],
      owner => 'me', metadata => { k => 'v' } },
    { content => 'no id: skipped', status => 'pending' },
  ];
  $t->restore_tasks($list);
  is( \@updates, [], 'on_update is not called' );
  is( $t->tasks, [ $list->[0], $list->[1] ], 'the list as it was (activeForm equal to the subject is the default)' );
  is( $t->list_tasks, "#2 [completed] Two\n#5 [in_progress] Five (me)", 'the tools see it' );
  my $t2 = Langertha::Raider::TodoTools->new( on_update => sub { push @updates, $_[0] } );
  $t2->restore_tasks($list);
  is( [ $t2->create_task( { subject => 'Six', description => 's' } ) ], [ 'Task #6 created successfully: Six', 0 ], 'the next id follows the highest' );
  $t2->restore_tasks([]);
  is( $t2->tasks, [], 'an empty list empties it' );
  is( [ $t2->create_task( { subject => 'Seven', description => 's' } ) ], [ 'Task #7 created successfully: Seven', 0 ], 'ids still never come back' );
};

subtest 'Journal->tasks: the last todo.updated since the last /clear, tasks only' => sub {
  my $a = { id => '1', content => 'A', status => 'pending' };
  my $b = { id => '2', content => 'B', status => 'pending' };
  is( journal()->tasks, [], 'no events, no tasks' );
  is( journal( { type => 'todo.updated', todos => [$a] }, { type => 'todo.updated', todos => [ $a, $b ] } )->tasks, [ $a, $b ], 'the last one' );
  is( journal( { type => 'todo.updated', todos => [$a] }, { type => 'history.cleared' } )->tasks, [], '/clear empties' );
  is( journal( { type => 'history.cleared' }, { type => 'todo.updated', todos => [$b] } )->tasks, [$b], 'later ones count again' );
  is( journal( { type => 'todo.updated', todos => [$a] }, { type => 'todo.updated', todos => [] } )->tasks, [], 'the last one may be empty' );
  is( journal( { type => 'todo.updated', todos => [ { content => 'x', status => 'pending', activeForm => 'x' } ] } )->tasks, [],
    'a todo_write list has no ids and restores nothing' );
  my $copy = journal( { type => 'todo.updated', todos => [$a] } )->tasks;
  $copy->[0]{content} = 'changed';
  is( $a->{content}, 'A', 'a copy' );
};

done_testing;
