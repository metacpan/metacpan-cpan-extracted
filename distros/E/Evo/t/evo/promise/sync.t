package main;
use Evo '-Promise::Sync';
use Test::More;

my @calls;
{

  package My::P;
  use Evo '-Class *';
  has calls => sub { [] };

  sub d_resolve_continue { push shift->calls->@*, [resnb => @_]; }
  sub d_reject_continue  { push shift->calls->@*, [rejnb => @_]; }
  sub d_reject           { push shift->calls->@*, [rej   => @_]; }


  package My::Thenable;
  use Evo '-Class *';
  has 'then_fn';
  sub then { $_[0]->then_fn->(@_); }
}

sub gen() { Evo::Promise::Sync->new(promise => My::P->new()) }

ONCE: {
  my $d = gen;
  $d->called(1);
  $d->reject('BAD');
  $d->resolve('BAD');
  is $d->promise->calls->@*, 0;
  ok !$d->should_resolve;
}


THENABLE_RES_NB: {
  my $d = gen;
  my ($res, $rej);
  my $thenable = My::Thenable->new(then_fn => sub { shift; ($res, $rej) = @_ });
  is $d->try_thenable($thenable), $d;
  ok !$d->should_resolve;
  ok !$d->called;
  $res->(0);
  $res->(33) for 1 .. 2;
  $rej->(44) for 1 .. 2;
  ok $d->called;
  is_deeply $d->promise->calls, [[qw(resnb 0)]];
}

THENABLE_RES_BL: {
  my $d = gen;

  my $thenable = My::Thenable->new(
    then_fn => sub {
      shift;
      my ($res, $rej) = @_;
      $res->(0);
      $res->(33) for 1 .. 2;
      $rej->(44) for 1 .. 2;
    }
  );
  $d->try_thenable($thenable);
  ok $d->should_resolve;
  ok $d->called;
  is $d->v, 0;
  ok !$d->promise->calls->@*;

}


THENABLE_REJ_NB: {
  my $d = gen;
  my ($res, $rej);
  my $thenable = My::Thenable->new(then_fn => sub { shift; ($res, $rej) = @_ });
  $d->try_thenable($thenable);
  ok !$d->should_resolve;
  ok !$d->called;
  $rej->(0);
  $res->(33) for 1 .. 2;
  $rej->(44) for 1 .. 2;
  ok $d->called;
  is_deeply $d->promise->calls, [[qw(rejnb 0)]];
}

THENABLE_RES_BL: {
  my $d        = gen;
  my $thenable = My::Thenable->new(
    then_fn => sub {
      shift;
      my ($res, $rej) = @_;
      $rej->(0);
      $res->(33) for 1 .. 2;
      $rej->(44) for 1 .. 2;
    }
  );

  $d->try_thenable($thenable);
  ok !$d->should_resolve;
  ok $d->called;
  is_deeply $d->promise->calls, [[qw(rej 0)]];
}

CATCH: {
  my $thenable = My::Thenable->new(then_fn => sub { die "Foo\n" });
  my $d = gen;
  $d->try_thenable($thenable);
  ok $d->called;
  is_deeply $d->promise->calls, [[rej => "Foo\n"]];
}

done_testing;
