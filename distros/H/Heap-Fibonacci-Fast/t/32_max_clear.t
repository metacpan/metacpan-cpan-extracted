use strict;
use Heap::Fibonacci::Fast;

my $count = 100;
use Test::More tests => (7);

my $t = Heap::Fibonacci::Fast->new('max');

is($t->count(), 0);
is($t->top(), undef);
is($t->top_key(), undef);

$t->key_insert($_, $_) for (map { int(rand() * 10 * $count) } (1..$count));
is($t->count(), $count);

$t->clear();

is($t->count(), 0);
is($t->top(), undef);
is($t->top_key(), undef);
