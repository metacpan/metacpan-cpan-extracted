#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 18;

# Module is usable...
BEGIN {
    use_ok( 'Lingua::Diversity::Internals', qw( :all ) );
}

# Subroutine _get_average() correctly croaks at empty array ref...
eval {
    _get_average( [] );
};
is(
    ref $@,
    'Lingua::Diversity::X::Internals::GetAverageEmptyArray',
    'Subroutine _get_average() correctly croaks at empty array ref'
);

# Subroutine _get_average() correctly croaks at arrays of different size...
eval {
    _get_average( [ 1..10 ], [] );
};
is(
    ref $@,
    'Lingua::Diversity::X::Internals::GetAverageArraysOfDifferentSize',
    'Subroutine _get_average() correctly croaks at arrays of different size'
);

my @numbers = ( 2..4 );
my ( $average, $variance, $num_observations ) = _get_average(
    \@numbers,
);

# Subroutine _get_average() correctly computes unweighted average.
is(
    $average,
    3,
    'Subroutine _get_average() correctly computes unweighted average'
);

# Subroutine _get_average() correctly computes unweighted variance.
is(
    sprintf( "%.2f", $variance ),
    0.67,
    'Subroutine _get_average() correctly computes unweighted variance'
);

my @weights = ( 2, 1, 1 );
( $average, $variance, $num_observations ) = _get_average(
    \@numbers,
    \@weights,
);

# Subroutine _get_average() correctly computes weighted average.
is(
    $average,
    2.75,
    'Subroutine _get_average() correctly computes weighted average'
);

# Subroutine _get_average() correctly computes weighted variance.
is(
    sprintf( "%.2f", $variance ),
    0.69,
    'Subroutine _get_average() correctly computes weighted variance'
);

# Subroutine _get_average() correctly returns number of observations.
is(
    $num_observations,
    4,
    'Subroutine _get_average() correctly returns number of observations'
);

# Subroutine _sample_indices() correctly croaks at sample size too large...
eval {
    _sample_indices( 10, 11 );
};
is(
    ref $@,
    'Lingua::Diversity::X::Internals::SampleIndicesSampleSizeTooLarge',
    'Subroutine _sample_indices() correctly croaks at sample size too large'
);

# Subroutine _sample_indices() SEEMS to work (hard to test!)...
my $num_samples = 10000;
my $sum_indices = 0;
foreach ( 1..$num_samples ) {
    my $sampled_indices_ref = _sample_indices( 2, 1 );
    $sum_indices            += shift @$sampled_indices_ref;
}
is(
    sprintf( "%.1f", ( $sum_indices / $num_samples ) ),
    0.5,
    'Subroutine _sample_indices() SEEMS to work (hard to test!)'
);

# Subroutine _count_types() correctly counts types...
is(
    _count_types( [ qw( a b b c d d d e ) ] ),
    5,
    'Subroutine _count_types() correctly counts types'
);

# Subroutine _count_frequency() correctly counts frequency...
ok(
    _compare_hashes(
        _count_frequency( [ qw( a b b c d d d e ) ] ),
        {
            'a' => 1,
            'b' => 2,
            'c' => 1,
            'd' => 3,
            'e' => 1,
        }
    ),
    'Subroutine _count_frequency() correctly counts frequency'
);

# Subroutine _get_units_per_category() works fine...
my $units_in_category_ref = _get_units_per_category(
    [ qw( a b b ) ],
    [ qw( A A B ) ],
);
ok(
    _compare_arrays(
        $units_in_category_ref->{'A'},
        [ qw ( a b ) ]
    )
    &&
    _compare_arrays(
        $units_in_category_ref->{'B'},
        [ qw ( b ) ]
    ),
    'Subroutine _count_frequency() correctly counts frequency per category'
);

# Subroutine _shannon_entropy() correctly computes entropy...
is(
    _shannon_entropy( [ qw( a b ) ], 2 ),
    1,
    'Subroutine _shannon_entropy() correctly computes entropy'
);

# Subroutine _perplexity() correctly computes perplexity...
is(
    _perplexity( [ qw( a b ) ] ),
    2,
    'Subroutine _perplexity() correctly computes perplexity'
);

# Subroutine _renyi_entropy() correctly computes Renyi's entropy...
is(
    sprintf( "%.3f", _renyi_entropy(
        'array_ref' => [ qw( a a b ) ],
        'exponent'  => 0.5,
    ) ),
    .664,
    q{Subroutine _renyi_entropy() correctly computes Renyi's entropy}
);

# Subroutine _renyi_entropy() correctly falls back on log number of types...
is(
    _renyi_entropy(
        'array_ref' => [ qw( a a b ) ],
        'exponent'  => 0,
    ),
    log _count_types( [ qw( a a b ) ] ),
    q{Subroutine _renyi_entropy() correctly falls back on log number of types}
);

# Subroutine _renyi_entropy() correctly falls back on Shannon's entropy...
is(
    _renyi_entropy(
        'array_ref' => [ qw( a a b ) ],
        'exponent'  => 1,
    ),
    _shannon_entropy( [ qw( a a b ) ] ),
    q{Subroutine _renyi_entropy() correctly falls back on Shannon's entropy}
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

#-----------------------------------------------------------------------------
# Subroutine _compare_hashes
#-----------------------------------------------------------------------------
# Synopsis:      Compare two hashes and return 1 if they're identical or
#                0 otherwise.
# Arguments:     - two hash reference
# Return values: - 0 or 1.
#-----------------------------------------------------------------------------

sub _compare_hashes {
    my ( $first_hash_ref, $second_hash_ref ) = @_;
    my @first_hash_keys  = sort keys %$first_hash_ref;
    my @second_hash_keys = sort keys %$second_hash_ref;
    return 0 if ! _compare_arrays( \@first_hash_keys, \@second_hash_keys );
    foreach my $key ( @first_hash_keys ) {
        if (
                ref $first_hash_ref->{$key}  eq 'HASH'
            &&  ref $second_hash_ref->{$key} eq 'HASH'
            &&  $first_hash_ref ne $second_hash_ref
        ) {
            return 0 if ! _compare_hashes(
                $first_hash_ref->{$key},
                $second_hash_ref->{$key},
            );
        }
        else {
            return 0 if    $first_hash_ref->{$key}
                        ne $second_hash_ref->{$key};
        }
    }
    return 1;
}

