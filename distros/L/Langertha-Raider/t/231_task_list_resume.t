#!/usr/bin/env perl
# ABSTRACT: A resumed or forked session gets its task list back from the journal (ADR 0025 addendum)
use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Langertha::Raider::Application;

clear_engine_env();
delete $ENV{RAIDER_ENABLE_TASKS};

package My::App {
  use Moose;
  extends 'Langertha::Raider::Application';
  sub _build_mcps { [] }
  __PACKAGE__->meta->make_immutable;
}

sub app { My::App->new( root => $_[0], engine => 'openai', api_key => 'test', @_[ 1 .. $#_ ] ) }

my @tasks = (
  { id => '1', content => 'Write it', status => 'completed', activeForm => 'Writing it', description => 'the code', blocks => ['2'], blockedBy => [] },
  { id => '2', content => 'Test it', status => 'in_progress', activeForm => 'Testing it', description => 'prove', blocks => [], blockedBy => ['1'] },
);

sub session_with {
  my ( $app, @events ) = @_;
  my $s = $app->create_session;
  $s->append( 'message', run => 'r1', role => 'user', content => 'hi' );
  $s->append( 'message', run => 'r1', role => 'assistant', content => 'hello' );
  $s->append( @$_ ) for @events;
  $s->append( 'run.finished', run => 'r1', status => 'completed' );
  return $s;
}

subtest 'resume: the task tools carry on with the list and its ids' => sub {
  my $root = tempdir( CLEANUP => 1 );
  my $first = app($root);
  my $s = session_with( $first, [ 'todo.updated', run => 'r1', todos => [ $tasks[0] ] ], [ 'todo.updated', run => 'r1', todos => \@tasks ] );
  $s->release;

  my $app = app($root);
  $app->replay_session( $app->open_session( $s->id ) );
  is( $app->todos, \@tasks, 'the application reports the list' );
  my $tools = $app->_todo_tools;
  is( $tools->list_tasks, "#1 [completed] Write it\n#2 [in_progress] Test it",'the tools list it (#1 is done: not blocking)' );
  is( [ $tools->create_task( { subject => 'Ship it', description => 'release' } ) ], [ 'Task #3 created successfully: Ship it', 0 ], 'ids go on' );
  is( $tools->get_task('2'), "Task #2: Test it\nStatus: in_progress\nDescription: prove\nBlocked by: #1", 'dependencies survived' );
};

subtest 'resume after /clear, with an empty list, or with todo_write: nothing comes back' => sub {
  my $root = tempdir( CLEANUP => 1 );
  my $first = app($root);
  my $cleared = session_with( $first, [ 'todo.updated', run => 'r1', todos => \@tasks ], [ 'history.cleared' ] );
  $cleared->release;
  my $empty = session_with( $first, [ 'todo.updated', run => 'r1', todos => \@tasks ], [ 'todo.updated', run => 'r1', todos => [] ] );
  $empty->release;
  my $legacy = session_with( $first, [ 'todo.updated', run => 'r1', todos => [ { content => 'x', status => 'pending', activeForm => 'x' } ] ] );
  $legacy->release;
  for my $s ( $cleared, $empty, $legacy ) {
    my $app = app($root);
    $app->replay_session( $app->open_session( $s->id ) );
    is( $app->todos, [], 'no tasks' );
    is( $app->_todo_tools->list_tasks, 'No tasks found', '... in the tools either' );
  }
};

subtest 'todo_write mode restores nothing' => sub {
  my $root = tempdir( CLEANUP => 1 );
  my $first = app( $root, task_tools => 0 );
  my $s = session_with( $first, [ 'todo.updated', run => 'r1', todos => \@tasks ] );
  $s->release;
  my $app = app( $root, task_tools => 0 );
  $app->replay_session( $app->open_session( $s->id ) );
  is( $app->todos, [], 'the list of todo_write is state of a run' );
};

subtest 'fork takes the list over' => sub {
  my $root = tempdir( CLEANUP => 1 );
  my $app = app($root);
  my $s = session_with( $app, [ 'todo.updated', run => 'r1', todos => \@tasks ] );
  my $fork = $app->fork_session( $s->id );
  $s->release;
  is( $app->session_store->read( $fork->{id} )->tasks, \@tasks, 'the fork holds the list' );
  my $other = app($root);
  $other->replay_session( $other->open_session( $fork->{id} ) );
  is( $other->todos, \@tasks, 'and resumes with it' );

  my $plain = $app->create_session;
  $plain->append( 'message', run => 'r1', role => 'user', content => 'hi' );
  $plain->append( 'run.finished', run => 'r1', status => 'completed' );
  my $f2 = $app->fork_session( $plain->id );
  $plain->release;
  is( [ grep { $_->{type} eq 'todo.updated' } @{ $app->session_store->read( $f2->{id} )->events } ], [], 'no list, no event' );
};

done_testing;
