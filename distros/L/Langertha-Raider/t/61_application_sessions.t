#!/usr/bin/env perl
# ABSTRACT: The application service opens, creates and replays sessions (ADR 0015)

use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Langertha::Raider::Application;

clear_engine_env();

# An application whose raider needs no tool servers.
package My::App {
  use Moose;
  extends 'Langertha::Raider::Application';
  sub _build_mcps { [] }
  __PACKAGE__->meta->make_immutable;
}

sub app { My::App->new(root => $_[0], engine => 'openai', api_key => 'test') }

my $root = tempdir(CLEANUP => 1);

subtest 'the store is the project store of the root' => sub {
  my $store = app($root)->session_store;
  isa_ok($store, 'Langertha::Raider::SessionStore');
  is($store->scope, 'project', 'project scope');
  is(path($store->dir)->stringify, path($root, '.raider', 'sessions')->stringify, 'under the root');
};

subtest 'create, open, replay' => sub {
  my $first = app($root);
  my $s = $first->create_session;
  $s->append('run.started', run => 'r1', engine => 'openai');
  $s->append('message', run => 'r1', role => 'user', content => 'hi');
  $s->append('message', run => 'r1', role => 'assistant', content => 'hello');
  $s->append('run.finished', run => 'r1', status => 'completed');

  like(dies { $first->open_session($s->id) }, qr/is in use/, 'one writer');
  $s->release;

  my $app = app($root);
  my $opened = $app->open_session($s->id);
  is($opened->id, $s->id, 'opened');
  my $journal = $app->replay_session($opened);
  isa_ok($journal, 'Langertha::Raider::Session::Journal');
  is([ map { [ $_->{role}, $_->{content} ] } @{ $app->raider->history } ],
    [ [ user => 'hi' ], [ assistant => 'hello' ] ], 'history replayed into the raider');
  ok(scalar @{ $app->raider->session_history }, 'session history replayed');
  $opened->release;
};

subtest 'fork and remove' => sub {
  my $root = tempdir(CLEANUP => 1);
  my $app = app($root);
  my $s = $app->create_session;
  $s->append('message', run => 'r1', role => 'user', content => 'hi');
  $s->append('message', run => 'r1', role => 'assistant', content => 'hello');
  $s->append('run.finished', run => 'r1', status => 'completed');

  my $fork = $app->fork_session($s->id);
  isnt($fork->{id}, $s->id, 'a new session');
  is($fork, { id => T(), path => ''.$app->session_store->path_of($fork->{id}), forked_from => $s->id, messages => 2 },
    'what the fork took over');
  my $journal = $app->session_store->read($fork->{id});
  is($journal->events->[0]{forked_from}, $s->id, 'session.created names the original');
  is($journal->history_messages, [ { role => 'user', content => 'hi' }, { role => 'assistant', content => 'hello' } ],
    'the history, outside any run');
  ok(lives { $app->open_session($fork->{id})->release }, 'the fork is not left locked');

  like(dies { $app->remove_session($s->id) }, qr/is in use/, 'no removal while open');
  $s->release;
  my $path = ''.$app->session_store->path_of($s->id);
  is($app->remove_session($s->id), $path, 'removed, path returned');
  ok(!-e $path, 'the journal is gone');
};

done_testing;
