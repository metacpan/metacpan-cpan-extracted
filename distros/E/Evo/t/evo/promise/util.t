package main;
use Evo '-Promise::Util *;';
use Test::More;

{

  package MyTestPromise;
  use Evo -Class;
  with 'Evo::Promise::Role';

  sub postpone ($self, $code) {
  }
}

sub p { MyTestPromise->new(@_) }

# is_fulfilled
ok is_fulfilled_with(0,     p()->d_fulfill(0));
ok is_fulfilled_with(undef, p()->d_fulfill(undef));
ok !is_fulfilled_with(0, p()->d_reject(0));
ok !is_fulfilled_with(1, p()->d_fulfill(0));

# is_rejected
ok is_rejected_with(0,     p()->d_reject(0));
ok is_rejected_with(undef, p()->d_reject(undef));
ok !is_rejected_with(0, p()->d_fulfill(0));
ok !is_rejected_with(1, p()->d_fulfill(0));

# is_locked_on
my $par = p();
my $ch  = p();
unshift $par->d_children->@*, $ch;
ok is_locked_in($par, $ch);
ok !is_locked_in(p(), $ch);

done_testing;

1;
