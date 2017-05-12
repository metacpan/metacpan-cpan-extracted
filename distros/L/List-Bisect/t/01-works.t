#!/usr/bin/perl 

use strict;
use warnings;

use Test::More qw{no_plan};
BEGIN{ print qq{\n} for 1..10};

#-----------------------------------------------------------------
BEGIN {

   use_ok 'List::Bisect';
   can_ok 'main', qw{ bisect trisect};

};
#---------------------------------------------------------------------------
{
   my ($a,$b) = bisect {$_ <= 5} 1..10;
   is_deeply $a, [1..5],  q{a is 1..5};
   is_deeply $b, [6..10], q{b is 6..10};
}

#---------------------------------------------------------------------------
{
   my ($a,$b,$c) = trisect {$_ <=> 5} 1..10;
   is_deeply $a, [1..4],  q{a is 1..4};
   is_deeply $b, [5],     q{b is 5};
   is_deeply $c, [6..10], q{c is 6..10};
}


{
   my ($x,$y,$z) = trisect { $_ < 5 ? -1 
                           : $_ > 5 ? 1
                           : 'foo' 
                           } 1..10;
   is_deeply $x, [1..4],  q{x is 1..4};
   is_deeply $y, [],      q{y is empty};
   is_deeply $z, [5..10], q{z is 5..10};
}


