package main;
use Evo '-Promise::Util *; Test::More';
{

  package MyTestPromise;
  use Evo -Class;
  with 'Evo::Promise::Role';

  sub postpone ($self, $code) {
  }
}

sub p { MyTestPromise->new(@_) }

SETTLED: {
  ok !p()->d_settled;
  ok p->d_fulfill(0)->d_settled;
  ok p->d_reject(0)->d_settled;
  my $p = p();
  $p->d_lock_in(p());
  ok !$p->d_settled;
}

LOCK_IN: {
  my ($ch, $p) = (p(), p());
  $ch->d_lock_in($p);
  ok is_locked_in($p, $ch);
  ok $ch->d_locked;
}

REJECT: {
  my $p = p();
  $p->d_reject(0);
  ok is_rejected_with(0, $p);
}

FULFILL: {
  my $p = p();
  $p->d_fulfill(0);
  ok is_fulfilled_with(0, $p);
}

no warnings 'once', 'redefine';
CONTINUE: {

  my $called;
  local *MyTestPromise::d_traverse = sub { $called++; };

REJECT_CONTINUE: {
    $called = 0;
    my $p = p();
    $p->d_reject_continue('REASON');
    ok is_rejected_with('REASON', $p);
    is $called, 1;
  }

RESOLVE_CONTINUE_SETTLED: {
    $called = 0;
    local *MyTestPromise::d_resolve = sub { };
    local *MyTestPromise::d_settled = sub {1};
    my $p = p();
    $p->d_resolve_continue('V');
    is $called, 1;
  }

RESOLVE_CONTINUE_PENDING: {
    $called = 0;
    local *MyTestPromise::d_resolve = sub { };
    local *MyTestPromise::d_settled = sub { };
    my $p = p();
    $p->d_resolve_continue('V');
    is $called, 0;
  }

}

done_testing;
