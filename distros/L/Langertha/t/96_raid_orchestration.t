#!/usr/bin/env perl
# ABSTRACT: Unit tests for Raid orchestration primitives

use strict;
use warnings;

use Test2::Bundle::More;
use Future::AsyncAwait;

use Langertha::Raid;
use Langertha::Raid::Sequential;
use Langertha::Raid::Parallel;
use Langertha::Raid::Loop;
use Langertha::Raider;
use Langertha::Result;
use Langertha::RunContext;

{
  package Test::DummyEngine;
  use Moose;
  __PACKAGE__->meta->make_immutable;
}

{
  package Test::CompatRaider;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Raider';

  has prefix => (is => 'ro', isa => 'Str', default => '');

  async sub raid_f {
    my ( $self, @messages ) = @_;
    my $input = join('', map {
      ref($_) eq 'HASH' ? ($_->{content} // '') : $_
    } @messages);
    return Langertha::Raider::Result->new(
      type => 'final',
      text => $self->prefix . $input,
    );
  }

  __PACKAGE__->meta->make_immutable;
}

{
  package Test::Runnable::Step;
  use Moose;
  use Future::AsyncAwait;
  with 'Langertha::Role::Runnable';

  has name => (
    is      => 'ro',
    isa     => 'Str',
    default => 'step',
  );

  has type => (
    is      => 'ro',
    isa     => 'Str',
    default => 'final',
  );

  has text => (
    is        => 'ro',
    predicate => 'has_text',
  );

  has content => (
    is        => 'ro',
    predicate => 'has_content',
  );

  has die_message => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_die_message',
  );

  has on_run => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => 'has_on_run',
  );

  has result_cb => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => 'has_result_cb',
  );

  async sub run_f {
    my ( $self, $ctx ) = @_;
    die $self->die_message if $self->has_die_message;
    $self->on_run->($ctx, $self) if $self->has_on_run;

    if ($self->has_result_cb) {
      return $self->result_cb->($ctx, $self);
    }

    if ($self->type eq 'final') {
      my $text = $self->has_text ? $self->text : ($ctx->input // '');
      return Langertha::Result->final($text);
    }
    if ($self->type eq 'question') {
      return Langertha::Result->question($self->content // 'question?');
    }
    if ($self->type eq 'pause') {
      return Langertha::Result->pause($self->content // 'pause');
    }
    if ($self->type eq 'abort') {
      return Langertha::Result->abort($self->content // 'abort');
    }
    die "Unknown test result type: ".$self->type;
  }

  __PACKAGE__->meta->make_immutable;
}

subtest 'Raider implements Runnable via run_f' => sub {
  my $raider = Test::CompatRaider->new(
    engine => Test::DummyEngine->new,
    prefix => 'raider:',
  );

  ok($raider->does('Langertha::Role::Runnable'), 'Raider composes Runnable role');

  my $ctx = Langertha::RunContext->new(input => 'hello');
  my $result = $raider->run_f($ctx)->get;

  isa_ok($result, 'Langertha::Raider::Result');
  ok($result->is_final, 'result is final');
  is($result->text, 'raider:hello', 'run_f forwards input into raid_f');
  is($ctx->input, 'raider:hello', 'context input updated with final output');
  is($ctx->state->{last_result_type}, 'final', 'context tracks final result type');
};

subtest 'Sequential with multiple Raider steps' => sub {
  my $r1 = Test::CompatRaider->new(engine => Test::DummyEngine->new, prefix => 'one:');
  my $r2 = Test::CompatRaider->new(engine => Test::DummyEngine->new, prefix => 'two:');
  my $raid = Langertha::Raid::Sequential->new(steps => [$r1, $r2]);
  my $ctx = Langertha::RunContext->new(input => 'x');

  my $result = $raid->run_f($ctx)->get;
  ok($result->is_final, 'sequential result is final');
  is($result->text, 'two:one:x', 'output is pipelined through both Raiders');
  is($ctx->input, 'two:one:x', 'context carries last output');
};

subtest 'Sequential propagation and error path' => sub {
  my $ran = 0;
  my $seq = Langertha::Raid::Sequential->new(steps => [
    Test::Runnable::Step->new(name => 'a', type => 'final', text => 'ok', on_run => sub { $ran++ }),
    Test::Runnable::Step->new(name => 'q', type => 'question', content => 'need input', on_run => sub { $ran++ }),
    Test::Runnable::Step->new(name => 'never', type => 'final', text => 'never', on_run => sub { $ran++ }),
  ]);
  my $result = $seq->run_f(Langertha::RunContext->new(input => 'start'))->get;
  ok($result->is_question, 'question propagates out of sequential raid');
  is($ran, 2, 'steps after question are not executed');

  my $seq_err = Langertha::Raid::Sequential->new(steps => [
    Test::Runnable::Step->new(name => 'boom', die_message => 'boom'),
  ]);
  my $err_result = $seq_err->run_f(Langertha::RunContext->new(input => 'x'))->get;
  ok($err_result->is_abort, 'step exception is converted to abort');
  like($err_result->content, qr/boom/, 'abort includes original error');
};

subtest 'Sequential context forwarding between steps' => sub {
  my $seq = Langertha::Raid::Sequential->new(steps => [
    Test::Runnable::Step->new(
      name   => 'writer',
      result_cb => sub {
        my ( $ctx ) = @_;
        $ctx->state->{shared} = 'yes';
        return Langertha::Result->final('stage1');
      },
    ),
    Test::Runnable::Step->new(
      name => 'reader',
      result_cb => sub {
        my ( $ctx ) = @_;
        return Langertha::Result->final('stage2:' . ($ctx->state->{shared} // 'no'));
      },
    ),
  ]);

  my $result = $seq->run_f(Langertha::RunContext->new(input => 'init'))->get;
  is($result->text, 'stage2:yes', 'second step reads state written by first step');
};

subtest 'Parallel context isolation and merge behavior' => sub {
  my $parallel = Langertha::Raid::Parallel->new(steps => [
    Test::Runnable::Step->new(
      name => 'left',
      result_cb => sub {
        my ( $ctx ) = @_;
        $ctx->state->{counter}++;
        $ctx->artifacts->{branch} = 'left';
        return Langertha::Result->final('L');
      },
    ),
    Test::Runnable::Step->new(
      name => 'right',
      result_cb => sub {
        my ( $ctx ) = @_;
        $ctx->state->{counter}++;
        $ctx->artifacts->{branch} = 'right';
        return Langertha::Result->final('R');
      },
    ),
  ]);

  my $ctx = Langertha::RunContext->new(
    input => 'seed',
    state => { counter => 0 },
  );
  my $result = $parallel->run_f($ctx)->get;

  ok($result->is_final, 'parallel returns final when all branches are final');
  is($ctx->state->{counter}, 0, 'parent state was not mutated by branch internals');
  is($result->text, "L\nR", 'branch final texts are aggregated in stable order');
  is(scalar keys %{$ctx->artifacts->{parallel_branches}}, 2, 'both branch contexts merged');
};

subtest 'Parallel propagation and error path' => sub {
  my $aborting = Langertha::Raid::Parallel->new(steps => [
    Test::Runnable::Step->new(name => 'ok', type => 'final', text => 'ok'),
    Test::Runnable::Step->new(name => 'bad', type => 'abort', content => 'stop'),
  ]);
  my $abort_result = $aborting->run_f(Langertha::RunContext->new(input => 'x'))->get;
  ok($abort_result->is_abort, 'abort from a branch aborts the whole parallel raid');

  my $questioning = Langertha::Raid::Parallel->new(steps => [
    Test::Runnable::Step->new(name => 'q', type => 'question', content => 'which one?'),
    Test::Runnable::Step->new(name => 'ok', type => 'final', text => 'ok'),
  ]);
  my $question_result = $questioning->run_f(Langertha::RunContext->new(input => 'x'))->get;
  ok($question_result->is_question, 'question propagates when no abort exists');

  my $dying = Langertha::Raid::Parallel->new(steps => [
    Test::Runnable::Step->new(name => 'explode', die_message => 'parallel boom'),
  ]);
  my $dying_result = $dying->run_f(Langertha::RunContext->new(input => 'x'))->get;
  ok($dying_result->is_abort, 'branch exception becomes abort');
  like($dying_result->content, qr/parallel boom/, 'abort keeps branch failure reason');
};

subtest 'Loop max iterations and stop callback' => sub {
  my $step = Test::Runnable::Step->new(
    name => 'counter',
    result_cb => sub {
      my ( $ctx ) = @_;
      $ctx->state->{n} = ($ctx->state->{n} // 0) + 1;
      return Langertha::Result->final('n=' . $ctx->state->{n});
    },
  );

  my $loop = Langertha::Raid::Loop->new(
    steps     => [$step],
    max_loops => 3,
  );
  my $ctx = Langertha::RunContext->new(input => 'start');
  my $result = $loop->run_f($ctx)->get;
  ok($result->is_final, 'loop finalizes after max_loops');
  is($result->text, 'n=3', 'loop ran exactly three iterations');
  is($ctx->metadata->{loop_iterations}, 3, 'loop stores total iterations');

  my $loop_cb = Langertha::Raid::Loop->new(
    steps          => [$step],
    max_loops      => 10,
    continue_while => sub {
      my ( $ctx, $iteration ) = @_;
      return $iteration < 2;
    },
  );
  my $ctx2 = Langertha::RunContext->new(input => 'start');
  my $result2 = $loop_cb->run_f($ctx2)->get;
  is($result2->text, 'n=2', 'continue_while can stop before max_loops');
  is($ctx2->metadata->{loop_iterations}, 2, 'iteration metadata reflects early stop');
};

subtest 'Loop propagation and error path' => sub {
  my $loop_pause = Langertha::Raid::Loop->new(
    steps     => [Test::Runnable::Step->new(name => 'pause', type => 'pause', content => 'wait')],
    max_loops => 5,
  );
  my $pause_result = $loop_pause->run_f(Langertha::RunContext->new(input => 'x'))->get;
  ok($pause_result->is_pause, 'pause propagates out of loop');

  my $loop_error = Langertha::Raid::Loop->new(
    steps     => [Test::Runnable::Step->new(name => 'boom', die_message => 'loop failed')],
    max_loops => 2,
  );
  my $error_result = $loop_error->run_f(Langertha::RunContext->new(input => 'x'))->get;
  ok($error_result->is_abort, 'loop step exception returns abort');
  like($error_result->content, qr/loop failed/, 'loop abort includes exception');
};

subtest 'Nested raid compositions are supported' => sub {
  my $raider = Test::CompatRaider->new(engine => Test::DummyEngine->new, prefix => 'R:');
  my $parallel = Langertha::Raid::Parallel->new(steps => [
    Test::Runnable::Step->new(name => 'p1', type => 'final', text => 'P1'),
    $raider,
  ]);
  my $loop_with_seq = Langertha::Raid::Loop->new(
    max_loops => 2,
    steps     => [
      Langertha::Raid::Sequential->new(steps => [
        Test::Runnable::Step->new(
          name => 'dot',
          result_cb => sub {
            my ( $ctx ) = @_;
            return Langertha::Result->final(($ctx->input // '') . '.');
          },
        ),
      ]),
    ],
  );

  my $top = Langertha::Raid::Sequential->new(steps => [
    Test::Runnable::Step->new(name => 'start', type => 'final', text => 'S'),
    $parallel,
    $loop_with_seq,
  ]);

  my $result = $top->run_f(Langertha::RunContext->new(input => 'seed'))->get;
  ok($result->is_final, 'nested orchestration returns final');
  like($result->text, qr/\.\.$/, 'loop-with-sequential runs within nested tree');
};

done_testing;
