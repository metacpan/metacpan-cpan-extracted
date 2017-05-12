use strict;
no warnings;
use Heap::Fibonacci::Fast;

my $count = 100;
use Test::More tests => (5);

sub compare { $a <=> $b }
my $t = Heap::Fibonacci::Fast->new('code', \&compare);

is($t->count(), 0);
is($t->top(), undef);

$t->insert(map { int(rand() * 10 * $count) } (1..$count));
is($t->count(), $count);

$t->clear();

is($t->count(), 0);
is($t->top(), undef);
