package main;
use Evo '-Promise::Deferred';
use Test::More;

my @calls;
{

  package My::P;
  use Evo '-Class *';
  has calls => sub { [] };

  sub d_resolve_continue { push shift->calls->@*, [resnb => @_]; }
  sub d_reject_continue  { push shift->calls->@*, [rejnb => @_]; }


}

sub gen() { Evo::Promise::Deferred->new(promise => My::P->new()) }

ONCE: {
  my $d = gen;
  $d->called(1);
  $d->reject('BAD');
  $d->resolve('BAD');
  $d->resolve();
  $d->reject();
  is $d->promise->calls->@*, 0;
}

RESOLVE: {
  my $d = gen;
  $d->resolve('V')  for 1 .. 2;
  $d->reject('BAD') for 1 .. 2;
  is_deeply $d->promise->calls, [[resnb => 'V']];
}

REJECT: {
  my $d = gen;
  $d->reject('R')    for 1 .. 2;
  $d->resolve('BAD') for 1 .. 2;
  is_deeply $d->promise->calls, [[rejnb => 'R']];
}

done_testing;
