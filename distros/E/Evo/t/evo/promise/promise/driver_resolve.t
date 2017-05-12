package main;
use Evo '-Promise::Util *; Test::More';
use FindBin;

{

  package MyTestPromise;
  use Evo -Class;
  with 'Evo::Promise::Role';

  sub postpone ($self, $code) {
  }

  package My::Thenable;
  use Evo '-Class *';
  has 'then_fn';
  sub then { $_[0]->then_fn->(@_); }
}

sub p { MyTestPromise->new(@_) }

VALUE: {
  my $p = p();
  $p->d_resolve('VAL');
  ok is_fulfilled_with 'VAL', $p;
}

BLESSED_OBJ: {
  my $p = p();
  $p->d_resolve(my $obj = bless {}, 'My::Obj');
  ok is_fulfilled_with $obj, $p;
}

BLESSED_REF: {
  my $p = p();
  $p->d_resolve('VAL');
  ok is_fulfilled_with 'VAL', $p;
}

SAME_OBJ: {
  my $p = p();
  $p->d_resolve($p);
  ok is_rejected_with 'TypeError', $p;
}

# promise
FULFILLED: {
  my $p = p();
  my $f = p()->d_fulfill(0);
  $p->d_resolve($f);
  ok is_fulfilled_with 0 => $p;
}

REJECTED: {
  my $p = p();
  my $r = p()->d_reject(0);
  $p->d_resolve($r);
  ok is_rejected_with 0 => $p;
}

LOCKED: {
  my $p       = p();
  my $pending = p();
  $p->d_resolve($pending);
  ok is_locked_in $pending => $p;
}

# thenable
THENABLE_ASYNC: {
  my $th = My::Thenable->new(then_fn => sub { });
  my $p = p();
  $p->d_resolve($th);
  ok !$p->d_settled;

}

THENABLE_CALLS_REJECT: {
  my $th = My::Thenable->new(then_fn => sub { $_[2]->('R') });
  my $p = p();
  $p->d_resolve($th);
  ok is_rejected_with 'R', $p;
}

THENABLE_CALLS_RESOLVE_WITH_VALUE: {
  my $th = My::Thenable->new(then_fn => sub { $_[1]->('V') });
  my $p = p();
  $p->d_resolve($th);
  ok is_fulfilled_with 'V', $p;
}

THENABLE_CALLS_RESOLVE_WITH_THENABLE: {
  my $called;
  my $th2 = My::Thenable->new(then_fn => sub { $called++; $_[1]->('V') });
  my $th1 = My::Thenable->new(then_fn => sub { $called++; $_[1]->($th2) });
  my $p   = p();
  $p->d_resolve($th1);
  ok is_fulfilled_with 'V', $p;
  is $called, 2;
}

done_testing;
