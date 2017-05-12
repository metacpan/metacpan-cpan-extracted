#!perl

use strict;
use warnings;

use Test::Most;    # plan is down at bottom
my $deeply = \&eq_or_diff;

BEGIN {
  use_ok('Math::SlideRule') || print "Bail out!\n";
}
diag("Testing Math::SlideRule $Math::SlideRule::VERSION, Perl $], $^X");

my $sr = Math::SlideRule->new;
isa_ok( $sr, 'Math::SlideRule' );

########################################################################
#
# Public attributes

# Back! Though are lookup tables now, so uh yeah.

########################################################################
#
# Internal Stuff - do not use

#               0 1 2  3  4  5   6   7
my @values = qw(1 3 7 15 31 63 127 255);

is( $sr->_rank( 1,   \@values ), 0 );
is( $sr->_rank( 3,   \@values ), 1 );
is( $sr->_rank( 255, \@values ), 7 );
# nearest if not present in list
is( $sr->_rank( 6, \@values ), 2 );
is( $sr->_rank( 4, \@values ), 1 );
# exactly between might be tricky, given floating point math, etc.

########################################################################
#
# Public methods

# subclasses shouldn't normally override this, so tested only here
$deeply->( [ $sr->standard_form(.0055) ], [ 5.5,  -3, 0 ], 'norm-3' );
$deeply->( [ $sr->standard_form(.055) ],  [ 5.5,  -2, 0 ], 'norm-2' );
$deeply->( [ $sr->standard_form(.55) ],   [ 5.5,  -1, 0 ], 'norm-1' );
$deeply->( [ $sr->standard_form(5.55) ],  [ 5.55, 0,  0 ], 'norm0' );
$deeply->( [ $sr->standard_form(55.5) ],  [ 5.55, 1,  0 ], 'norm1' );
$deeply->( [ $sr->standard_form(555) ],   [ 5.55, 2,  0 ], 'norm2' );
$deeply->( [ $sr->standard_form(5550) ],  [ 5.55, 3,  0 ], 'norm3' );
$deeply->( [ $sr->standard_form(-640) ],  [ 6.40, 2,  1 ], 'norm4' );
# edge conditions are fun! (also, floating point math can easily throw
# off the exponent, e.g. 0.01 * 10 == 0.099999994, whoops!)
$deeply->( [ $sr->standard_form(10) ],   [ 1.0, 1, 0 ], 'norm-10' );
$deeply->( [ $sr->standard_form(-10) ],  [ 1.0, 1, 1 ], 'norm--10' );
$deeply->( [ $sr->standard_form(100) ],  [ 1.0, 2, 0 ], 'norm-100' );
$deeply->( [ $sr->standard_form(1000) ], [ 1.0, 3, 0 ], 'norm-1000' );
# skip these, given how inaccurate computers are at multiplying numbers
# (RT #110765) TODO consider better faking things with sprintf or
# Math::Round based on how precise the slide rule being emulated is?
#$deeply->( [ $sr->standard_form(0.1) ],   [ 1.0, -1, 0 ], 'norm-0.1' );
#$deeply->( [ $sr->standard_form(0.01) ],  [ 1.0, -2, 0 ], 'norm-0.01' );
#$deeply->( [ $sr->standard_form(0.001) ], [ 1.0, -3, 0 ], 'norm-0.001' );

# do need to check these...
is( sprintf( "%.2f", $sr->divide( 75, 92 ) ), 0.82, 'simple divide' );
is( sprintf( "%.2f", $sr->divide( 14, 92, 3 ) ), 0.05, 'chain divide' );

is( sprintf( "%.2f", $sr->multiply( 1.1, 2.2 ) ), 2.42, 'simple multiply' );
is( sprintf( "%.2f", $sr->multiply( 4.1, 3.7 ) ),
  15.17, 'multiply across bounds' );

is( sprintf( "%.1f", $sr->sqrt(.04) ), 0.2,  'sqrt(.04)' );
is( sprintf( "%.2f", $sr->sqrt(.4) ),  0.63, 'sqrt(.4)' );
is( sprintf( "%.0f", $sr->sqrt(4) ),   2,    'sqrt(4)' );
is( sprintf( "%.2f", $sr->sqrt(40) ),  6.32, 'sqrt(40)' );
# and also outside the 1..100 bounds of the A/B scale, which must be
# adjusted to fit, then the exponent properly handled
is( sprintf( "%.0f", $sr->sqrt(400) ), 20, 'sqrt(400)' );
# NOTE should be 63.25, really do need to investigate magnitude of the errors
# of these calculations.
is( sprintf( "%.2f", $sr->sqrt(4000) ), 63.24, 'sqrt(4000)' );

# actual answer precisely 4.00e-4; similar calculations without so nice
# numbers would require rounding...
is( sprintf( "%.4f", $sr->multiply( 0.02, 0.02 ) ), 0.0004, 'small multiply' );

# this is probably near a worst case for accuracy, given the infrequent
# ticks at the high end of the scale; 9799.41 vs. expected 9801, so
# really do need to round things
is( sprintf( "%.2f", $sr->multiply( 99, 99 ) ), 9799.41, 'big multiply' );

# I try not to be negative, but these things happen.
is( sprintf( "%.2f", $sr->multiply( 1.1,  -2.2 ) ), -2.42, 'negative' );
is( sprintf( "%.2f", $sr->multiply( -1.1, -2.2 ) ), 2.42,  'not negative' );

# These really do accumulate error without rounding! (TODO investigate
# the error...)
is( sprintf( "%.2f", $sr->multiply( 42, 31, 28, 215 ) ),
  7837905.09, 'chain multiply' );
is( sprintf( "%.2f", $sr->multiply( 42, -31, -28, -215 ) ),
  -7837905.09, 'chain multiply neg' );

plan tests => 35;
