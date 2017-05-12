use strict;
use Test::More tests => 12;

use Heap::Fibonacci::Fast;

my $t = new Heap::Fibonacci::Fast;

is($t->count(), 0);

ok($t->key_insert(6, 5));
ok($t->key_insert(2, 1));
ok($t->key_insert(4, 3));

is($t->top(), 1);
is($t->count(), 3);
is($t->top_key(), 2);

is($t->extract_top(), 1);
is($t->top_key(), 4);
is($t->extract_top(), 3);
is($t->extract_top(), 5);

is($t->count(), 0);
