#!/usr/bin/perl -w

use lib qw(t/lib);
use strict;

# Meanwhile, in another piece of code!
package Bar;
use Test::More tests=>3;
use_ok('Math::HashSum',qw(hashsum));
my %hash1 = (a=>.1, b=>.4); 
my %hash2 = (a=>.2, b=>.5);
my %sum = hashsum(%hash1,%hash2);

is($sum{a},.3);
is($sum{b},.9);
