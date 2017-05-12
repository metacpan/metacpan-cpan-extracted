use strict;
use Test::More tests => 5;

use Heap::Fibonacci::Fast;

my $t = new Heap::Fibonacci::Fast;

$t->key_insert(1, 2);
$t->key_insert(3, 4);
$t->key_insert(5, 6);
$t->key_insert(7, 8);

my @data;

@data = $t->extract_upto(-1);
is(scalar @data, 0);

@data = $t->extract_upto(1);
is_deeply(\@data, [2]);

$t->key_insert(11, 12);

@data = $t->extract_upto(7);
is_deeply(\@data, [4, 6, 8]);

is($t->extract_top(), 12);

@data = $t->extract_upto(-1);
is(scalar @data, 0);

