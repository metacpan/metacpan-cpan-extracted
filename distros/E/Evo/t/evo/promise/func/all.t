package main;
use Evo 'Test::More; -Promise::Deferred';

my @POSTPONE;
sub loop_start { (shift @POSTPONE)->() while @POSTPONE; }
sub deferred { Evo::Promise::Deferred->new(promise => MyTestPromise->new) }
sub promise_all     { MyTestPromise->all(@_) }
sub promise_resolve { MyTestPromise->resolve(@_) }
sub promise_reject  { MyTestPromise->reject(@_) }

{

  package MyTestPromise;
  use Evo -Class;
  with 'Evo::Promise::Role';

  sub postpone ($self, $code) {
    push @POSTPONE, $code;
  }
}


EMPTY: {
  my ($called, $result);
  my $p = promise_all()->then(sub { $called++; $result = shift; });
  loop_start();
  is $called, 1;
  is_deeply $result, [];
}

WITH_SPREAD: {
  my ($called, %result);
  my $p = promise_all(one => promise_resolve(1), two => 2)
    ->spread(sub(%res) { $called++; %result = %res; });
  loop_start();
  is $called, 1;
  is_deeply \%result, {one => 1, two => 2};
}

RESOLVE_ORDER: {
  my ($d1, $d2, $d3) = (deferred, deferred, deferred);
  my ($result, $called);
  no warnings 'once';
  local *My::Thenable::then = sub ($th, $res, $rej) {
    $res->('5th');
  };
  promise_all($d1->promise, $d2->promise, $d3->promise, 4, bless {}, 'My::Thenable')
    ->then(sub { $called++; $result = shift; });

  loop_start;

  # too early
  ok !$called;

  # only 2 of 3
  $d3->resolve(3);
  $d1->resolve(1);
  loop_start;
  ok !$called;

  # resolve 2 argument by pending promise - wait
  my $dres = deferred;
  $d2->resolve($dres->promise);
  loop_start;
  ok !$called;

  # resolve that pending promise
  $dres->resolve('2p');
  ok !$called;
  loop_start;

  is_deeply $result, [1, '2p', 3, 4, '5th'];
  is $called, 1;
}

REJECT_BY_PROMISE: {
  my ($d1, $d2, $d3, $d4) = (deferred, deferred, deferred, deferred);
  my ($reason, $called);
  promise_all($d1->promise, $d2->promise, $d3->promise, $d4->promise)
    ->then(sub {fail}, sub { $called++; $reason = shift; });

  $d1->resolve('v');
  $d2->reject('myreason');
  loop_start;
  is $called, 1;
  is $reason , 'myreason';

  ## already reejcted, still 1
  $d3->resolve('bad');
  $d4->reject('bad');
  loop_start;
  is $called, 1;
}

REJECT_BY_THENABLE: {
  no warnings 'once';
  my $reject;
  local *My::Thenable::then = sub ($th, $res, $rej) {
    $reject = $rej;
  };
  my ($d1, $d2, $d3) = (deferred, deferred, deferred, deferred);
  my ($reason, $called);

  promise_all($d1->promise, $d2->promise, $d3->promise, bless {}, 'My::Thenable')
    ->then(sub {fail}, sub { $called++; $reason = shift; });

  $d1->resolve('v');
  $reject->('myreason');
  loop_start;
  is $called, 1;
  is $reason , 'myreason';

  # already reejcted, still 1
  $d2->resolve('bad');
  $d3->reject('bad');
  loop_start;
  is $called, 1;
}

REJECT_BY_DIED_THENABLE: {
  no warnings 'once';
  my $reject;
  local *My::Thenable::then = sub { die "MyErr\n" };
  my ($d1, $d2) = (deferred, deferred);
  my ($reason, $called);

  promise_all($d1->promise, $d2->promise, bless {}, 'My::Thenable')
    ->then(sub {fail}, sub { $called++; $reason = shift; });

  loop_start;
  is $called, 1;
  is $reason , "MyErr\n";

  # already reejcted, still 1

  $d1->resolve('bad');
  $d2->reject('bad');
  loop_start;
  is $called, 1;
}

done_testing;
