#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

# This "test" never fails, but prints a benchmark comparison between two
# mathematically-identical functions, one with Faster::Maths and one without

use Time::HiRes qw( gettimeofday tv_interval );
sub measure(&)
{
   my ( $code ) = @_;
   my $start = [ gettimeofday ];
   $code->();
   return tv_interval $start;
}

my $MAXCOUNT = 1000;

my $C  = [-0.8, 0.156];
my $Z0 = [0.125, 0.125];
my $ESCAPE_VAL = 824;

sub julia_standard
{
   my ($zr, $zi) = @_;
   my ($cr, $ci) = @$C;

   my $count = $MAXCOUNT;
   while( $count and $zr*$zr + $zi*$zi < 2*2 ) {
      ($zr, $zi) = ( ($zr*$zr - $zi*$zi + $cr), 2*($zr*$zi) + $ci );
      --$count or return undef;
   }

   return $count;
}

sub julia_faster
{
   use Faster::Maths;

   my ($zr, $zi) = @_;
   my ($cr, $ci) = @$C;

   my $count = $MAXCOUNT;
   while( $count and $zr*$zr + $zi*$zi < 2*2 ) {
      ($zr, $zi) = ( ($zr*$zr - $zi*$zi + $cr), 2*($zr*$zi) + $ci );
      --$count or return undef;
   }

   return $count;
}

my $standard_elapsed = 0;
my $faster_elapsed   = 0;

# To reduce the influence of bursts of timing noise, interleave many small runs
# of each type.

my $COUNT = 300;

foreach ( 1 .. 20 ) {
   $standard_elapsed += measure {
      my $ret;
      $ret = julia_standard( @$Z0 ) for 1 .. $COUNT;
      $ret == $ESCAPE_VAL or die "Expected $ESCAPE_VAL from standard\n";
   };
   $faster_elapsed += measure {
      my $ret;
      $ret = julia_faster( @$Z0 ) for 1 .. $COUNT;
      $ret == $ESCAPE_VAL or die "Expected $ESCAPE_VAL from faster\n";
   };
}

pass( "Benchmarked" );

if( $faster_elapsed > $standard_elapsed ) {
   diag( sprintf "Standard took %.3fsec, ** this was SLOWER at %.3fsec **",
      $standard_elapsed, $faster_elapsed );
}
else {
   my $speedup = ( $standard_elapsed - $faster_elapsed ) / $standard_elapsed;
   diag( sprintf "Standard took %.3fsec, this was %d%% faster at %.3fsec",
      $standard_elapsed, $speedup * 100, $faster_elapsed );
}

done_testing;
