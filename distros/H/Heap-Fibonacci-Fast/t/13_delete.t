#!/usr/bin/perl

use Heap::Fibonacci::Fast;
use Test::More tests => 3;

my $t = Heap::Fibonacci::Fast->new();
$t->key_insert(6, 5);
my $e = $t->key_insert(2, 1);

is($t->top(), 1);
$t->remove($e);
is($t->top(), 5);
is($t->count(), 1);
