use Evo 'Test::More';

BEGIN {
  eval { require AE; 1 } or plan skip_all => 'Install AnyEvent to run this test';
}

use Evo::Promise::AE '*';
my $cv = AE::cv;

my ($v, $r, $f);

# promise
my $p = promise(
  sub ($resolve, $reject) {
    $resolve->('hello');
  }
  )->then(sub { $v = shift; die "Foo\n" })->catch(sub { $r = shift })
  ->finally(sub { $f++; $cv->send });

ok !$v;
ok !$r;

$cv->recv;

is $v, 'hello';
is $r, "Foo\n";
is $f, 1;


# deferred
$cv = AE::cv;
($v, $r) = @_;
my $d = deferred;
$d->promise->then(sub { $v = shift; die "Foo\n" })->catch(sub { $r = shift })
  ->finally(sub { $cv->send });
$d->resolve('hello');

ok !$v;
ok !$r;

$cv->recv;

is $v, 'hello';
is $r, "Foo\n";

# functions

ok(main::->can($_), $_) for qw(resolve reject race all);
ok resolve(2);

done_testing;
