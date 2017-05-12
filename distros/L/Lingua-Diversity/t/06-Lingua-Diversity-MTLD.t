#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;

# Module is usable...
BEGIN {
    use_ok( 'Lingua::Diversity::MTLD' ) || print "Bail out!\n";
}

my $diversity;

$diversity = Lingua::Diversity::MTLD->new();

# Created objects are of the right class...
cmp_ok(
    ref( $diversity ), 'eq', 'Lingua::Diversity::MTLD',
    'is a Lingua::Diversity::MTLD'
);

# Created object have all necessary methods defined...
can_ok( $diversity, qw(
    _measure
    _get_factor_length_average
) );

my $unit_array_ref          = [ qw( a  b  a  b  a  b  a  b  c  b  ) ];
my $category_array_ref      = [ qw( A  A  B  B  B  A  A  A  A  B  ) ];
my $recoded_unit_array_ref  = [ qw( Aa Ab Ba Bb Ba Ab Aa Ab Ac Bb ) ];

my ( $average, $variance, $count ) = $diversity->_get_factor_length_average(
    $unit_array_ref,
);

# Method _get_factor_length_average() correctly computes average (1 array)...
is(
    sprintf( "%.3f", $average ),
    3.457,
    'Method _get_factor_length_average() correctly computes average (1 array)'
);

# Method _get_factor_length_average() correctly computes variance (1 array)...
is(
    sprintf( "%.3f", $variance ),
    0.467,
    'Method _get_factor_length_average() correctly computes variance '
  . '(1 array)'
);

# Method _get_factor_length_average() correctly computes count (1 array)...
is(
    sprintf( "%.3f", $count ),
    2.893,
    'Method _get_factor_length_average() correctly computes count (1 array)'
);

( $average, $variance, $count ) = $diversity->_get_factor_length_average(
    $recoded_unit_array_ref,
    $category_array_ref,
);

# Method _get_factor_length_average() correctly computes average (2 arrays)...
is(
    sprintf( "%.3f", $average ),
    3.333,
    'Method _get_factor_length_average() correctly computes average '
  . '(2 arrays)'
);

# Method _get_factor_length_average() correctly computes variance (2 arrays)..
is(
    sprintf( "%.3f", $variance ),
    0.222,
    'Method _get_factor_length_average() correctly computes variance '
  . '(2 arrays)'
);

# Method _get_factor_length_average() correctly computes count (2 arrays)...
is(
    $count,
    3,
    'Method _get_factor_length_average() correctly computes count (2 arrays)'
);

# Method _get_factor_length_average(): fixed single partial factor bug...
my @AVC = $diversity->_get_factor_length_average(
    [ qw( a b c ) ],
);
ok(
    _compare_arrays(
        \@AVC,
        [ ( 0, 0, 1 ) ]
    ),
    'Method _get_factor_length_average(): fixed single partial factor bug'
);

my $result = $diversity->_measure( $unit_array_ref );

# Method _measure() correctly computes average...
is(
    sprintf( "%.3f", $result->get_diversity() ),
    3.228,
    'Method _measure() correctly computes average'
);

# Method _measure() correctly computes variance...
is(
    sprintf( "%.3f", $result->get_variance() ),
    0.234,
    'Method _measure() correctly computes variance'
);

# Method _measure() correctly computes count...
is(
    sprintf( "%.3f", $result->get_count() ),
    2.946,
    'Method _measure() correctly computes count'
);

$diversity->set_weighting_mode( 'within_and_between' );
$result = $diversity->_measure( $unit_array_ref );

# Method _measure() correctly computes weighted average...
is(
    sprintf( "%.3f", $result->get_diversity() ),
    3.224,
    'Method _measure() correctly computes weighted average'
);

# Method _measure() correctly computes weighted variance...
is(
    sprintf( "%.3f", $result->get_variance() ),
    0.229,
    'Method _measure() correctly computes weighted variance'
);

# Method _measure() correctly computes weighted count...
is(
    sprintf( "%.3f", $result->get_count() ),
    2.947,
    'Method _measure() correctly computes weighted count'
);



#-----------------------------------------------------------------------------
# Subroutine _compare_arrays
#-----------------------------------------------------------------------------
# Synopsis:      Compare two arrays and return 1 if they're identical or
#                0 otherwise.
# Arguments:     - two array references
# Return values: - 0 or 1.
#-----------------------------------------------------------------------------

sub _compare_arrays {
    my ( $first_array_ref, $second_array_ref ) = @_;
    return 0 if @$first_array_ref != @$second_array_ref;
    foreach my $index ( 0..@$first_array_ref-1 ) {
        return 0 if    $first_array_ref->[$index]
                    ne $second_array_ref->[$index];
    }
    return 1;
}


