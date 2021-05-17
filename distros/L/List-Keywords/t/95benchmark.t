#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

# This "test" never fails, but prints a benchmark comparison between these
# util functions and the ones provided by List::Util

use Time::HiRes qw( gettimeofday tv_interval );
sub measure(&)
{
   my ( $code ) = @_;
   my $start = [ gettimeofday ];
   $code->();
   return tv_interval $start;
}

my @nums = ( 1 .. 100 );

my $COUNT = 10_000;

my $LK_elapsed = 0;
my $LU_elapsed = 0;

# To reduce the influence of bursts of timing noise, interleave many small runs
# of each type.

foreach ( 1 .. 20 ) {
   my $overhead = measure {};

   $LK_elapsed += -$overhead + measure {
      use List::Keywords 'first';
      my $ret;
      ( $ret = first { $_ > 50 } @nums ) for 1 .. $COUNT;
   };
   $LU_elapsed += -$overhead + measure {
      use List::Util 'first';
      my $ret;
      ( $ret = first { $_ > 50 } @nums ) for 1 .. $COUNT;
   };
}

pass( "Benchmarked" );

if( $LK_elapsed > $LU_elapsed ) {
   diag( sprintf "List::Util took %.3fsec, ** this was SLOWER at %.3fsec **",
      $LU_elapsed, $LK_elapsed );
}
else {
   my $speedup = ( $LU_elapsed - $LK_elapsed ) / $LU_elapsed;
   diag( sprintf "List::Util took %.3fsec, this was %d%% faster at %.3fsec",
      $LU_elapsed, $speedup * 100, $LK_elapsed );
}

done_testing;
