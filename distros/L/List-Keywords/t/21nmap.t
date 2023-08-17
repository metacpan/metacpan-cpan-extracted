#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0 0.000148;  # is_refcount

use List::Keywords 'nmap';

# 2-at-a-time, no growth
{
   is( [nmap my ($k, $v) { } ()], [], 'nmap empty in list context');
   is( scalar(nmap my ($k, $v) { } ()), 0, 'nmap empty in scalar context');

   my @values;
   is( [nmap my ($k, $v) { @values = ($k, $v); (uc $k, $v + 1) } ( one => 1, two => 2, three => 3 )],
       [ONE => 2, TWO => 3, THREE => 4],
       'nmap in list context' );
   is( \@values, [ three => 3 ], 'nmap code block saw correct values' );

   is( scalar(nmap my ($k, $v) { ($k, $v) } ( one => 1, two => 2, three => 3 )), 6,
       'nmap in scalar context' );
}

# 3-at-a-time, shorter output
{
   is( [nmap my ($x, $y, $z) { $x + $y + $z } (1, 2, 3, 4, 5, 6)],
       [6, 15],
       'nmap with shorter output' );
}

# result stack can grow
{
   is( [nmap my ($x, $y) { ($x, "$x$y", $y) } qw(a b c d)],
       [qw(a ab b c cd d)],
       'nmap with longer output can grow' );
}

# stack discipline
{
   is( [1, (nmap my ($x) { $x } 2), 3], [1, 2, 3],
      'nmap behaves correctly as list operator' );
}

# refcounts
{
   my $arr = [];
   is_oneref( $arr, '$arr has one reference before test' );

   my $result;

   ( $result ) = nmap my ($x) { $x } $arr;
   is_refcount( $arr, 2, '$arr has two references after nmap my ($x) BLOCK' );

   undef $result;
   is_oneref( $arr, '$arr has one reference at end of test' );
}

done_testing;
