# -*- perl -*-

use strict;
use warnings;
use Test::Simple tests => 52;
use Math::Palindrome ':all';


my @a = increasing_sequence(25, 111);
ok(is_palindrome($_)) foreach @a;
my @b = decreasing_sequence(25, 10000);
ok(is_palindrome($_)) foreach @b;
ok(palindrome_after(5) == 5);
ok(palindrome_before(5) == 55);
