use Evo;
use Test::More;

{

  package MyTestPromise;    ## no critic
  use Evo -Class;
  with 'Evo::Promise::Role';

  my @POSTPONE;

  sub postpone ($self, $code) {
    push @POSTPONE, $code;
  }

  sub loop_start { (shift @POSTPONE)->() while @POSTPONE; }
}


my ($v, $r);

# promise
my $p = MyTestPromise::->promise(
  sub ($resolve, $reject) {
    $resolve->('hello');
  }
)->then(sub { $v = shift; die "Foo\n" })->catch(sub { $r = shift });

ok !$v;
ok !$r;

MyTestPromise::->loop_start;

is $v, 'hello';
is $r, "Foo\n";


# deferred
($v, $r) = @_;
my $d = MyTestPromise::->deferred;
$d->promise->then(sub { $v = shift; die "Foo\n" })->catch(sub { $r = shift });
$d->resolve('hello');

ok !$v;
ok !$r;

MyTestPromise::->loop_start;

is $v, 'hello';
is $r, "Foo\n";

done_testing;
