#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 27;

# Module is usable...
BEGIN {
    use_ok( 'Lingua::Diversity::Variety' ) || print "Bail out!\n";
}

my $diversity;

$diversity = Lingua::Diversity::Variety->new();

# Created objects are of the right class...
cmp_ok(
    ref( $diversity ), 'eq', 'Lingua::Diversity::Variety',
    'is a Lingua::Diversity::Variety'
);

# Created object have all necessary methods defined...
can_ok( $diversity, qw(
    _measure
    _compute_variety_average
    _compute_variety
) );

# Transform 'type_token_ratio' is correctly defined...
is(
    sprintf(
        "%.3f",
        $Lingua::Diversity::Variety::builtin_transform{'type_token_ratio'}->( 2, 3 ),
    ),
    0.667,
    q{Transform 'type_token_ratio' is correctly defined}
);

# Transform 'mean_frequency' is correctly defined...
is(
    $Lingua::Diversity::Variety::builtin_transform{'mean_frequency'}->( 2, 3 ),
    1.5,
    q{Transform 'mean_frequency' is correctly defined}
);

# Transform 'guiraud' is correctly defined...
is(
    sprintf(
        "%.3f",
        $Lingua::Diversity::Variety::builtin_transform{'guiraud'}->( 2, 3 ),
    ),
    1.155,
    q{Transform 'guiraud' is correctly defined}
);

# Transform 'herdan' is correctly defined...
is(
    sprintf(
        "%.3f",
        $Lingua::Diversity::Variety::builtin_transform{'herdan'}->( 2, 3 ),
    ),
    0.631,
    q{Transform 'herdan' is correctly defined}
);

# Transform 'rubet' is correctly defined...
is(
    sprintf(
        "%.2f",
        $Lingua::Diversity::Variety::builtin_transform{'rubet'}->( 2, 3 ),
    ),
    7.37,
    q{Transform 'rubet' is correctly defined}
);

# Transform 'maas' is correctly defined...
is(
    sprintf(
        "%.3f",
        $Lingua::Diversity::Variety::builtin_transform{'maas'}->( 2, 3 ),
    ),
    0.336,
    q{Transform 'maas' is correctly defined}
);

# Transform 'dugast' is correctly defined...
is(
    sprintf(
        "%.3f",
        $Lingua::Diversity::Variety::builtin_transform{'dugast'}->( 2, 3 ),
    ),
    2.977,
    q{Transform 'dugast' is correctly defined}
);

# Transform 'lukjanenkov_nesitoj' is correctly defined...
is(
    sprintf(
        "%.3f",
        $Lingua::Diversity::Variety::builtin_transform{'lukjanenkov_nesitoj'}->( 2, 3 ),
    ),
    -0.683,
    q{Transform 'lukjanenkov_nesitoj' is correctly defined}
);

# User-defined transforms are correctly handled...
$diversity = Lingua::Diversity::Variety->new(
    'transform' => sub { $_[0] * $_[0] },
);
is(
    $diversity->_measure( [ qw( a b c ) ] )->get_diversity(),
    9,
    q{User-defined transforms are correctly handled}
);

my $unit_array_ref          = [ qw( a  b  b  ) ];
my $category_array_ref      = [ qw( A  A  B  ) ];
my $recoded_unit_array_ref  = [ qw( Aa Ab Bb ) ];

my $result;

# Method _compute_variety() correctly computes variety...
is(
    $diversity->_compute_variety( $unit_array_ref ),
    2,
    'Method _compute_variety() correctly computes variety'
);

# Method _compute_variety() correctly computes perplexity...
$diversity->set_unit_weighting( 1 );
is(
    sprintf( "%.2f", $diversity->_compute_variety( $unit_array_ref ) ),
    1.89,
    'Method _compute_variety() correctly computes perplexity'
);

# Method _compute_variety() correctly computes Renyi's perplexity...
$diversity->set_unit_weighting( 0.5 );
is(
    sprintf( "%.3f", $diversity->_compute_variety( $unit_array_ref ) ),
    1.943,
    q{Method _compute_variety() correctly computes Renyi's perplexity}
);

# Method _compute_variety() correctly computes variety per category...
$diversity->set_unit_weighting( 0 );
is(
    $diversity->_compute_variety(
        $recoded_unit_array_ref,
        $category_array_ref
    ),
    1.5,
    'Method _compute_variety() correctly computes variety per cat.'
);

# Method _compute_variety() correctly computes perplexity per category...
$diversity->set_unit_weighting( 1 );
is(
    $diversity->_compute_variety(
        $recoded_unit_array_ref,
        $category_array_ref
    ),
    1.5,
    'Method _compute_variety() correctly computes perplexity per cat.'
);

# Method _compute_variety() correctly computes Renyi's perplexity per cat...
$diversity->set_unit_weighting( .5 );
is(
    $diversity->_compute_variety(
        $recoded_unit_array_ref,
        $category_array_ref
    ),
    1.5,
    q{Method _compute_variety() correctly computes Renyi's perplexity }
   .q{per cat.}
);

# Method _compute_variety() correctly computes weighted variety per cat...
$diversity->set_category_weighting( 1 );
$diversity->set_unit_weighting( 0 );
is(
    sprintf( "%.3f", $diversity->_compute_variety(
        $recoded_unit_array_ref,
        $category_array_ref
    ) ),
    1.667,
    'Method _compute_variety() correctly computes weighted variety per cat.'
);

# Method _compute_variety() correctly computes weighted perplexity per cat...
$diversity->set_unit_weighting( 1 );
is(
    sprintf( "%.3f", $diversity->_compute_variety(
        $recoded_unit_array_ref,
        $category_array_ref
    ) ),
    1.667,
    q{Method _compute_variety() correctly computes weighted perplexity }
  . q{per cat.}
);

# Method _compute_variety() correctly computes weighted Renyi perpl. per cat.
$diversity->set_unit_weighting( .5 );
is(
    sprintf( "%.3f", $diversity->_compute_variety(
        $recoded_unit_array_ref,
        $category_array_ref
    ) ),
    1.667,
    q{Method _compute_variety() correctly computes weighted Renyi's }
   .q{perplexity per cat.}
);

# Method _measure() correctly applies transforms...
$diversity->set_unit_weighting( 0 );
$diversity->set_category_weighting( 0 );
$diversity->set_transform( 'type_token_ratio' );
$result = $diversity->_measure( $unit_array_ref );
is(
    sprintf( "%.3f", $result->get_diversity() ),
    0.667,
    q{Method _measure() correctly applies transforms}
);

# Method _measure() correctly croaks at arrays smaller than subsample_size...
my $sampling_scheme = Lingua::Diversity::SamplingScheme->new(
    'subsample_size' => 50,
);
$diversity->set_sampling_scheme( $sampling_scheme );
eval {
    $diversity->_measure( [ qw( a b c ) ] );
};
is(
    ref $@,
    'Lingua::Diversity::X::ValidateSizeArrayTooSmall',
    'Method _measure() correctly croaks at arrays smaller than subsample_size'
);

# Method _compute_variety_average() works fine (random)...
$sampling_scheme = Lingua::Diversity::SamplingScheme->new(
    'mode'           => 'random',
    'num_subsamples' => 100000,
    'subsample_size' => 2,
);
$diversity = Lingua::Diversity::Variety->new(
    'sampling_scheme'   => $sampling_scheme,
    'transform'         => sub { $_[0] * $_[0] },
);
$result = $diversity->_compute_variety_average( $unit_array_ref );
is(
    sprintf( "%.0f", $result->get_diversity() ),
    3,
    q{Method _compute_variety_average() works fine (random)}
);

# Method _compute_variety_average() works fine (random, per cat.).
$result = $diversity->_compute_variety_average(
    $recoded_unit_array_ref,
    $category_array_ref,
);
is(
    sprintf( "%.0f", $result->get_diversity() ),
    2,
    q{Method _compute_variety_average() works fine (random, per category)}
);

$unit_array_ref          = [ qw( a  b  b  b  c ) ];
$category_array_ref      = [ qw( A  A  A  B  C  ) ];
$recoded_unit_array_ref  = [ qw( Aa Ab Ab Bb Cc ) ];

# Method _compute_variety_average() works fine (segmental)...
$sampling_scheme->set_mode( 'segmental' );
$result = $diversity->_compute_variety_average( $unit_array_ref );
is(
    sprintf( "%.1f", $result->get_diversity() ),
    2.5,
    q{Method _compute_variety_average() works fine (segmental)}
);

# Method _compute_variety_average() works fine (segm., per cat)...
$result = $diversity->_compute_variety_average(
    $recoded_unit_array_ref,
    $category_array_ref,
);
is(
    sprintf( "%.1f", $result->get_diversity() ),
    2.5,
    q{Method _compute_variety_average() works fine (segmental, per category)}
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


