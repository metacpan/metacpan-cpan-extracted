#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use List::Keywords 'reduce';

# Short cornercases
{
   is( ( reduce { die "ARGH" } () ), undef, 'reduce on empty list yields undef' );

   is( ( reduce { die "ARGH" } 123 ), 123, 'reduce on singletone list yields value directly' );
}

# basic sum
is( ( reduce { $a + $b } 1 .. 5 ), 15, 'sum of 1..5 is 15' );

# reduce is definitely a left-fold
is( ( reduce { "($a+$b)" } "a" .. "d" ), "(((a+b)+c)+d)", 'reduce is a left-fold' );

done_testing;
