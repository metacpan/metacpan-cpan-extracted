package main;
use Evo '-Promise::Util *; Evo::Promise::Deferred';
use Test::More;

{

  package MyTestPromise;
  use Evo -Class;
  with 'Evo::Promise::Role';

  sub postpone ($self, $code) {
  }
}

sub p { MyTestPromise->new(@_) }

# resolved/rejected

ok is_fulfilled_with 33, MyTestPromise->resolve(33);
ok is_rejected_with 44,  MyTestPromise->reject(44);

# resolve will follow, reject not
my $p = p();
ok is_locked_in $p,     MyTestPromise->resolve($p);
ok is_rejected_with $p, MyTestPromise->reject($p);

done_testing;

1;
