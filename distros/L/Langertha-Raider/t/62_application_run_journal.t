#!/usr/bin/env perl
# ABSTRACT: The application service records a run in the session journal and hands its events on, for any surface

use strict;
use warnings;
use utf8;
use Test2::V0;
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Test::Raider::SeqEngine;
use IO::Async::Loop;
use Langertha::Raider::Application;

clear_engine_env();

# The plain application -- no CLI class, no trace -- on the scripted engine.
package My::App {
  use Moose;
  extends 'Langertha::Raider::Application';
  sub _build_mcps { [] }
  sub _build_engine { Test::Raider::SeqEngine::Engine->new(mcp_servers => [ Test::Raider::SeqEngine::MCP->new ]) }
  around run => sub {
    my ( $orig, $self, $text ) = @_;
    die "kaputt\n" if $text eq 'fail';
    return $self->$orig($text);
  };
  __PACKAGE__->meta->make_immutable;
}

sub app { My::App->new(root => $_[0], engine => 'openai', api_key => 'test', model => 'seq-model', @_[1 .. $#_]) }

my $json = JSON::MaybeXS->new(utf8 => 1);
sub events { map { $json->decode($_) } path($_[0])->lines_raw({ chomp => 1 }) }

subtest 'a completed run: journal, consumer, outcome' => sub {
  my $root = tempdir(CLEANUP => 1);
  my $app = app($root);
  my $session = $app->create_session;
  my @got;
  my $end = $app->run_prompt('hi', session => $session, on_event => sub { push @got, [ @_ ] });

  is($end, {
    status   => 'completed',
    elapsed  => T(),
    result   => T(),
    response => 'Fertig ✓',
    metrics  => hash { field tool_calls => 2; etc() },
    session  => { id => $session->id, path => ''.$session->path },
  }, 'the outcome');
  ok(!$app->has_run, 'no run in progress afterwards');

  is([ map { $_->{type} } events($session->path) ], [qw( session.created run.started message tool.call tool.result
    tool.call tool.result message run.finished )], 'the journal');
  my @e = events($session->path);
  like($e[1], { run => 'r1', engine => 'openai', model => 'seq-model' }, 'run.started');
  like($e[-1], { run => 'r1', status => 'completed', metrics => { tool_calls => 2 }, elapsed => T() }, 'run.finished');

  is([ map { $_->[0] eq 'run.state' ? 'run.state '.{ @$_[1 .. $#$_] }->{state} : $_->[0] } @got ],
    [ 'run.started', 'run.state running', 'message', 'tool.call', 'tool.result', 'tool.call', 'tool.result',
      'message', 'run.state completed' ], 'the consumer gets every event of the run');
  ok(!(grep { $_->[0] eq 'run.finished' } @got), 'run.finished is the journal\'s');

  $app->run_prompt('again', session => $session);
  is([ map { $_->{run} } grep { $_->{type} eq 'run.finished' } events($session->path) ], [qw( r1 r2 )],
    'the next run of the session');
};

subtest 'a failed run, and a run without a session' => sub {
  my $root = tempdir(CLEANUP => 1);
  my $app = app($root);
  my $session = $app->create_session;
  my $end = $app->run_prompt('fail', session => $session);
  like($end, { status => 'failed', error => 'kaputt', session => { id => $session->id } }, 'failed outcome');
  like((events($session->path))[-1], { type => 'run.finished', status => 'failed', error => 'kaputt' }, 'journal');

  my @got;
  $end = app($root, on_event => sub { push @got, $_[0] })->run_prompt('hi');
  is($end->{status}, 'completed', 'no session needed');
  ok(!exists $end->{session}, 'none named');
  ok(scalar(grep { $_ eq 'tool.call' } @got), 'the application-wide on_event gets the events too');
  is(app($root)->run_prompt(''), undef, 'an empty prompt runs nothing');
};

subtest 'a run a surface ends itself' => sub {
  my $root = tempdir(CLEANUP => 1);
  my $app = app($root);
  my $session = $app->create_session;
  $app->begin_run(session => $session);
  my $end = $app->end_run(interrupted => signal => 'TERM');
  like($end, { status => 'interrupted', signal => 'TERM', session => { id => $session->id } }, 'ended');
  like((events($session->path))[-1], { type => 'run.finished', status => 'interrupted', signal => 'TERM' }, 'journal');
  is($app->end_run('interrupted'), undef, 'nothing to end outside a run');
};

package My::HangMCP {
  use Moose;
  has calls => (is => 'ro', default => sub { [] });
  sub list_tools { Future->done([ { name => 'bash' }, { name => 'broken' } ]) }
  sub call_tool {
    my ( $self, $name ) = @_;
    push @{ $self->calls }, $name;
    return IO::Async::Loop->new->new_future;   # never completes
  }
  __PACKAGE__->meta->make_immutable;
}

package My::HangApp {
  use Moose;
  extends 'My::App';
  has mcp => (is => 'ro', default => sub { My::HangMCP->new });
  sub _build_engine { Test::Raider::SeqEngine::Engine->new(mcp_servers => [ $_[0]->mcp ]) }
  __PACKAGE__->meta->make_immutable;
}

subtest 'cancel_run: the run ends cancelled, the tool call too' => sub {
  my $root = tempdir(CLEANUP => 1);
  my $app = My::HangApp->new(root => $root, engine => 'openai', api_key => 'test', model => 'seq-model');
  my $session = $app->create_session;
  ok(!$app->cancel_run, 'nothing to cancel outside a run');
  $app->loop->watch_time(after => 0.3, code => sub { ok($app->cancel_run, 'cancel_run during the run') });
  my @got;
  my $end = do {
    local $SIG{ALRM} = sub { die "TIMEOUT: run hung\n" };
    alarm 10;
    my $e = $app->run_prompt('hi', session => $session, on_event => sub { push @got, [ @_ ] });
    alarm 0;
    $e;
  };
  like($end, { status => 'cancelled', result => T(), session => { id => $session->id } }, 'the outcome');
  ok($end->{result}->is_cancelled, 'with the cancelled result');
  is($app->mcp->calls, [ 'bash' ], 'the second tool never ran');
  my @e = events($session->path);
  is([ map { $_->{type} } @e ], [qw( session.created run.started message tool.call tool.result run.finished )],
    'no answer in the journal');
  like($e[4], { name => 'bash', status => 'cancelled' }, 'tool.result cancelled');
  like($e[5], { run => 'r1', status => 'cancelled' }, 'run.finished cancelled');
  is(( map { { @$_[1 .. $#$_] }->{state} } grep { $_->[0] eq 'run.state' } @got )[-1], 'cancelled', 'run.state cancelled');
  ok(!$app->raider->cancel_requested, 'nothing left pending');
};

subtest 'cancel_run before the raider exists' => sub {
  my $root = tempdir(CLEANUP => 1);
  my $app = app($root);
  my $end = $app->run_prompt('hi', on_event => sub { $app->cancel_run if $_[0] eq 'run.started' });
  is($end->{status}, 'cancelled', 'cancelled');
  is(scalar @{ $app->raider->history }, 0, 'no history');
  is($app->run_prompt('hi')->{status}, 'completed', 'the next run is not cancelled');
};

subtest 'a journal that cannot be written: reported once per run' => sub {
  my $root = tempdir(CLEANUP => 1);
  my @errors;
  my $app = app($root, on_journal_error => sub { push @errors, [ $_[0]->id, $_[1] ] });
  my $session = $app->create_session;
  my $append = \&Langertha::Raider::Session::append;
  no warnings 'redefine';
  local *Langertha::Raider::Session::append = sub {
    Carp::croak('disk full') if $_[1] ne 'session.created';
    goto &$append;
  };
  is($app->run_prompt('hi', session => $session)->{status}, 'completed', 'the run goes on');
  is(scalar @errors, 1, 'one report');
  is($errors[0][0], $session->id, 'names the session');
  like($errors[0][1], qr/\Adisk full/, 'with the error');
  ok(!$app->record($session, 'history.cleared'), 'record says it failed');
  is(scalar @errors, 2, 'and reports it');
};

done_testing;
