#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Test::Refcount;

use List::Keywords 'ngrep';

# 2-at-a-time
{
   is( [ngrep my ($k, $v) { } ()], [], 'ngrep empty in list context');
   is( scalar(ngrep my ($k, $v) { } ()), 0, 'ngrep empty in scalar context');

   my @values;
   is( [ngrep my ($k, $v) { @values = ($k, $v); length $k == 3 } ( one => 1, two => 2, three => 3 )],
       [one => 1, two => 2],
       'ngrep in list context' );
   is( \@values, [ three => 3 ], 'ngrep code block saw correct values' );

   is( scalar(ngrep my ($k, $v) { length $k == 3 } ( one => 1, two => 2, three => 3 )), 4,
       'ngrep in scalar context' );

   is( [ngrep my ($k, $v) { @values = ($k, $v) } ( one => 1, missing => )],
       [one => 1, missing => ],
       'ngrep with short list does not invent undef' );
   is( \@values, [ missing => undef ],
       'ngrep code block still saw missing value as undef' );
}

# stack discipline
{
   is( [1, (ngrep my ($x) { 1 } 2), 3], [1, 2, 3],
      'ngrep behaves correctly as list operator' );
}

done_testing;
