#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

# Module is usable...
BEGIN {
    use_ok( 'Lingua::Diversity::VOCD' ) || print "Bail out!\n";
}

my $diversity;

$diversity = Lingua::Diversity::VOCD->new(
    'min_value'         => 2,
    'max_value'         => 6,
    'precision'         => 2,
    'num_subsamples'    => 10000,
);

# Created objects are of the right class...
cmp_ok(
    ref( $diversity ), 'eq', 'Lingua::Diversity::VOCD',
    'is a Lingua::Diversity::VOCD'
);

# Created object have all necessary methods defined...
can_ok( $diversity, qw(
    _measure
    _length_range_set
) );

my $unit_array_ref      = [ qw( a a b b c ) ];
my $category_array_ref  = [ qw( A A B B B ) ];

# Method measure() correctly croaks at array too small...
eval { $diversity->measure( $unit_array_ref ) };
is(
    ref( $@ ),
    'Lingua::Diversity::X::ValidateSizeArrayTooSmall',
    'Method _measure() correctly croaks at array too small'
);

# Method _measure() correctly computes average diversity...
$diversity->set_length_range( [ 2..4 ] );
my $result = $diversity->measure(
    $unit_array_ref,
);
is(
    $result->get_diversity(),
    4,
    'Method _measure() correctly computes average diversity'
);

# Method _measure() correctly computes variance of diversity...
is(
    $result->get_variance(),
    0,
    'Method _measure() correctly computes variance of diversity'
);

# Method _measure() correctly reports count...
is(
    $result->get_count(),
    3,
    'Method _measure() correctly reports count'
);






