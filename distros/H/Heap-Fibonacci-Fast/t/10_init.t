use strict;
use Test::More tests => 15;

use Heap::Fibonacci::Fast;
my $t;

$t = Heap::Fibonacci::Fast->new();
ok($t);
is(ref $t, 'Heap::Fibonacci::Fast');
is($t->get_type(), 'min');

$t = Heap::Fibonacci::Fast->new('min');
ok($t);
is(ref $t, 'Heap::Fibonacci::Fast');
is($t->get_type(), 'min');

$t = Heap::Fibonacci::Fast->new('max');
ok($t);
is(ref $t, 'Heap::Fibonacci::Fast');
is($t->get_type(), 'max');

$t = Heap::Fibonacci::Fast->new('code', sub {});
ok($t);
is(ref $t, 'Heap::Fibonacci::Fast');
is($t->get_type(), 'code');

sub z{}

$t = Heap::Fibonacci::Fast->new('code', \&z);
ok($t);
is(ref $t, 'Heap::Fibonacci::Fast');
is($t->get_type(), 'code');

