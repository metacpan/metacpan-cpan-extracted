#!/usr/bin/env perl
# ABSTRACT: The task tools (task_create, task_update, task_list, task_get), Claude Code's answers, and the family the application mounts
use strict;
use warnings;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use File::Temp qw( tempdir );
use Langertha::Raider::TodoTools;
use Langertha::Raider::CLI;

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY RAIDER_HALL_SOCKET RAIDER_PACK_DIRS RAIDER_ENABLE_TASKS )};

sub invoke {
  my ( $server, $name, $args ) = @_;
  my ($tool) = grep { $_->name eq $name } @{ $server->tools };
  return $tool->code->( $tool, $args );
}
sub text { $_[0]{content}[0]{text} }

subtest 'task_create: the next id, pending, Claude Code\'s answer' => sub {
  my @seen;
  my $t = Langertha::Raider::TodoTools->new( on_update => sub { push @seen, $_[0] } );
  my $r = invoke( $t->task_server, task_create => { subject => 'Run the tests', description => 'prove t/', activeForm => 'Running the tests' } );
  ok( !$r->{isError}, 'accepted' );
  is( text($r), 'Task #1 created successfully: Run the tests', 'the answer' );
  is( text( invoke( $t->task_server, task_create => { subject => 'Fix it', description => 'x' } ) ),
    'Task #2 created successfully: Fix it', 'ids count on' );
  is( $seen[-1], [
    { id => '1', content => 'Run the tests', status => 'pending', activeForm => 'Running the tests',
      description => 'prove t/', blocks => [], blockedBy => [] },
    { id => '2', content => 'Fix it', status => 'pending', activeForm => 'Fix it',
      description => 'x', blocks => [], blockedBy => [] },
  ], 'on_update gets the whole list: content is the subject, activeForm defaults to it' );

  for my $bad ( {}, { subject => 'a' }, { description => 'b' }, { subject => [], description => 'b' } ) {
    my $e = invoke( $t->task_server, task_create => $bad );
    ok( $e->{isError}, 'missing or wrong subject/description is an error' );
    like( text($e), qr/\AError: (?:subject|description) is required and must be a string\z/, 'and says which' );
  }
  is( scalar @{ $t->tasks }, 2, 'a refused create adds nothing' );
};

subtest 'task_update: fields in Claude Code\'s order, not found, deleted' => sub {
  my $t = Langertha::Raider::TodoTools->new;
  $t->create_task( { subject => "S$_", description => "D$_" } ) for 1 .. 3;
  is( [ $t->update_task( { taskId => '1', status => 'in_progress' } ) ], [ 'Updated task #1 status', 0 ], 'status' );
  is( [ $t->update_task( { taskId => '1', status => 'in_progress' } ) ], [ 'Updated task #1 ', 0 ],
    'nothing changed: no field (Claude Code\'s answer keeps its space)' );
  is( [ $t->update_task( { taskId => '1', status => 'completed', subject => 'S1b', owner => 'me', metadata => { a => 1 } } ) ],
    [ 'Updated task #1 subject, owner, metadata, status', 0 ], 'several fields, in order' );
  is( [ $t->update_task( { taskId => '1', metadata => { a => undef, b => 2 } } ) ],
    [ 'Updated task #1 metadata', 0 ], 'metadata always counts' );
  is( $t->tasks->[0]{metadata}, { b => 2 }, 'merged; null removes a key' );
  is( [ $t->update_task( { taskId => '7', status => 'completed' } ) ], [ 'Task not found', 0 ],
    'an unknown id: Claude Code\'s text, no error' );
  is( [ $t->update_task( { taskId => '2', addBlocks => ['3'] } ) ], [ 'Updated task #2 blocks', 0 ], 'addBlocks' );
  is( [ $t->update_task( { taskId => '2', addBlocks => ['3'] } ) ], [ 'Updated task #2 ', 0 ], 'a link twice is no change' );
  is( $t->get_task('3'), "Task #3: S3\nStatus: pending\nDescription: D3\nBlocked by: #2", 'the link has both ends' );
  is( [ $t->update_task( { taskId => '2', status => 'deleted', subject => 'ignored' } ) ], [ 'Updated task #2 deleted', 0 ],
    'deleted: removed, other fields not applied' );
  is( $t->get_task('2'), 'Task not found', 'gone' );
  is( $t->get_task('3'), "Task #3: S3\nStatus: pending\nDescription: D3", 'and no task links to it any more' );
  is( [ $t->create_task( { subject => 'S4', description => 'D4' } ) ], [ 'Task #4 created successfully: S4', 0 ],
    'a deleted id is not used again' );

  my ( $msg, $err ) = $t->update_task( { taskId => '3', status => 'doing' } );
  ok( $err, 'an unknown status is an error' );
  is( $msg, 'Error: status must be one of pending, in_progress, completed, deleted', 'naming the statuses' );
  ok( ( $t->update_task( {} ) )[1], 'no taskId: an error' );
  ok( ( $t->update_task( { taskId => '3', addBlockedBy => 'x' } ) )[1], 'addBlockedBy not a list: an error' );
};

subtest 'task_list and task_get read like Claude Code' => sub {
  my $t = Langertha::Raider::TodoTools->new;
  is( text( invoke( $t->task_server, task_list => {} ) ), 'No tasks found', 'empty' );
  is( text( invoke( $t->task_server, task_get => { taskId => '1' } ) ), 'Task not found', 'unknown id' );
  $t->create_task( { subject => 'Build', description => 'make' } );
  $t->create_task( { subject => 'Test', description => 'make test' } );
  $t->create_task( { subject => 'Ship', description => 'upload' } );
  $t->create_task( { subject => 'Hidden', description => 'x', metadata => { _internal => 1 } } );
  $t->update_task( { taskId => '3', addBlockedBy => [ '1', '2' ] } );
  $t->update_task( { taskId => '1', status => 'completed' } );
  $t->update_task( { taskId => '2', status => 'in_progress', owner => 'worker' } );
  is( text( invoke( $t->task_server, task_list => {} ) ),
    "#1 [completed] Build\n#2 [in_progress] Test (worker)\n#3 [pending] Ship [blocked by #2]",
    'one line per task; only open blockers; owner; _internal tasks left out' );
  is( text( invoke( $t->task_server, task_get => { taskId => '3' } ) ),
    "Task #3: Ship\nStatus: pending\nDescription: upload\nBlocked by: #1, #2", 'task_get shows every blocker' );
  is( text( invoke( $t->task_server, task_get => { taskId => '1' } ) ),
    "Task #1: Build\nStatus: completed\nDescription: make\nBlocks: #3", 'and what it blocks' );
  $t->clear_tasks;
  is( $t->list_tasks, 'No tasks found', 'clear_tasks empties the list' );
  is( ( $t->create_task( { subject => 'Again', description => 'x' } ) )[0], 'Task #5 created successfully: Again',
    'ids go on counting after a clear' );
};

sub cli {
  my ( %arg ) = @_;
  return Langertha::Raider::CLI->new(
    root => tempdir( CLEANUP => 1 ), engine => 'openai', api_key => 'test', model => 'gpt-4o-mini', trace => 0, detect => 0,
    %arg,
  );
}

subtest 'the application mounts one family: the task tools by default' => sub {
  my $app = cli();
  ok( $app->task_tools, 'task_tools by default' );
  my %have = map { $_->name => 1 } $app->_mounted_tools;
  ok( $have{$_}, "$_ mounted" ) for qw( task_create task_update task_list task_get );
  ok( !$have{todo_write}, 'todo_write is not' );

  my $legacy = cli( task_tools => 0 );
  my %old = map { $_->name => 1 } $legacy->_mounted_tools;
  ok( $old{todo_write}, 'task_tools => 0: todo_write' );
  ok( !$old{$_}, "and no $_" ) for qw( task_create task_update task_list task_get );

  for my $v ( '0', 'false', 'off' ) {
    local $ENV{RAIDER_ENABLE_TASKS} = $v;
    ok( !cli()->task_tools, "RAIDER_ENABLE_TASKS=$v turns them off" );
  }
  local $ENV{RAIDER_ENABLE_TASKS} = '1';
  ok( cli()->task_tools, 'RAIDER_ENABLE_TASKS=1 keeps them' );
};

subtest 'the task list lasts across runs, /clear empties it, every change is todo.updated' => sub {
  my $app = cli();
  my @events;
  $app->begin_run( on_event => sub { push @events, [@_] } );
  my ($create) = grep { $_->name eq 'task_create' } $app->_mounted_tools;
  $create->code->( $create, { subject => 'a', description => 'b' } );
  is( [ map { $_->{id}.'/'.$_->{content}.'/'.$_->{status} } @{ $app->todos } ], ['1/a/pending'], 'todos holds the tasks' );
  my ($ev) = grep { $_->[0] eq 'todo.updated' } @events;
  is( { @{$ev}[ 1 .. $#$ev ] }->{todos}[0]{content}, 'a', 'todo.updated with the list' );
  $app->end_run('completed');
  $app->begin_run;
  is( scalar @{ $app->todos }, 1, 'the next run goes on with the list (unlike todo_write)' );
  my ($update) = grep { $_->name eq 'task_update' } $app->_mounted_tools;
  is( $update->code->( $update, { taskId => '1', status => 'completed' } )->{content}[0]{text}, 'Updated task #1 status',
    'and finds the task by its id' );
  $app->end_run('completed');
  $app->note_history_cleared;
  is( $app->todos, [], '/clear empties it' );
  my ($list) = grep { $_->name eq 'task_list' } $app->_mounted_tools;
  is( $list->code->( $list, {} )->{content}[0]{text}, 'No tasks found', 'in the tools too' );
};

done_testing;
