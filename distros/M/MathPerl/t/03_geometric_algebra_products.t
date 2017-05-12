#!/usr/bin/perl

# suppress 'WEXRP00: Found multiple rperl executables' due to blib/ & pre-existing installation(s)
BEGIN { $ENV{RPERL_WARNINGS} = 0; }

use strict;
use warnings;
use RPerl::AfterSubclass;
our $VERSION = 0.000_010;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(ProhibitStringyEval) # SYSTEM DEFAULT 1: allow eval()
## no critic qw(ProhibitConstantPragma ProhibitMagicNumbers)  # USER DEFAULT 3: allow constants

# [[[ INCLUDES ]]]
use RPerl::Test;
use Test::More tests => 1537;
use Test::More;
use Test::Exception;
use Test::Number::Delta;

BEGIN {
    if ( $ENV{RPERL_VERBOSE} ) {
        Test::More::diag("[[[ Beginning MathPerl Geometric Algebra Products Pre-Test Loading ]]]");
    }
    lives_and( sub { use_ok('RPerl::AfterSubclass'); }, q{use_ok('RPerl::AfterSubclass') lives} );
    lives_and( sub { use_ok('MathPerl::GeometricAlgebra::Products'); }, q{use_ok('MathPerl::GeometricAlgebra::Products') lives} );
}

# [[[ CONSTANTS ]]]
use constant UNIT_VECTOR_MAGNITUDE_NORMALIZED_3 => my number $TYPED_UNIT_VECTOR_MAGNITUDE_NORMALIZED_3 = ( 1 / 3 )**( 1 / 2 );
use constant UNIT_VECTOR_MAGNITUDE_NORMALIZED_2 => my number $TYPED_UNIT_VECTOR_MAGNITUDE_NORMALIZED_2 = ( 1 / 2 )**( 1 / 2 );
use constant RIGHT_TRIANGLE_LEG_3_1             => my number $TYPED_RIGHT_TRIANGLE_LEG_3_1             = 3 / 13;
use constant RIGHT_TRIANGLE_LEG_3_2             => my number $TYPED_RIGHT_TRIANGLE_LEG_3_2             = 4 / 13;
use constant RIGHT_TRIANGLE_LEG_3_3             => my number $TYPED_RIGHT_TRIANGLE_LEG_3_3             = 12 / 13;

# [[[ PRIMARY RUNLOOP ]]]
# [[[ PRIMARY RUNLOOP ]]]
# [[[ PRIMARY RUNLOOP ]]]

# loop 3 times, once for each mode: PERLOPS_PERLTYPES, PERLOPS_CPPTYPES, CPPOPS_CPPTYPES
# TMP DISABLE
#foreach my integer $mode_id ( sort keys %{$RPerl::MODES} ) {
for my $mode_id ( 0 .. 0 ) {    # TEMPORARY DEBUGGING PERLOPS_PERLTYPES ONLY

    # [[[ MODE SETUP ]]]
    #    RPerl::diag("in 00_products.t, top of for() loop, have \$mode_id = $mode_id\n");
    my scalartype_hashref $mode = $RPerl::MODES->{$mode_id};
    my string $ops              = $mode->{ops};
    my string $types            = $mode->{types};
    my string $mode_tagline     = $ops . 'OPS_' . $types . 'TYPES';
    if ( $ENV{RPERL_VERBOSE} ) {
        Test::More::diag( '[[[ Beginning MathPerl Geometric Algebra Products Tests, ' . $ops . ' operations and ' . $types . ' data types' . ' ]]]' );
    }

    #    $RPerl::DEBUG = 1;
    #    RPerl::diag('have $ops = ' . $ops . "\n");
    #    RPerl::diag('have $types = ' . $types . "\n");
    #    RPerl::diag('have $mode_tagline = ' . $mode_tagline . "\n");




# NEED UPDATE: enable compiled modes
# NEED UPDATE: enable compiled modes
# NEED UPDATE: enable compiled modes

=TMP_DISABLE
    lives_ok( sub { rperltypes::types_enable($types) }, q{mode '} . $ops . ' operations and ' . $types . ' data types' . q{' enabled} );

    if ( $ops eq 'CPP' ) {

        # force reload
        delete $main::{ 'RPerl__DataType__' . $type . '__MODE_ID' };

        my $package = 'RPerl::DataType::' . $type . '_cpp';
        lives_and( sub { require_ok($package); }, 'require_ok(' . $package . ') lives' );

        #            lives_and( sub { use_ok($package); }, 'use_ok(' . $package . ') lives' );

        lives_ok( sub { eval( $package . '::cpp_load();' ) }, $package . '::cpp_load() lives' );
    }

    lives_ok( sub { main->can( 'RPerl__DataType__' . $type . '__MODE_ID' ) }, 'main::RPerl__DataType__' . $type . '__MODE_ID() exists' );

    # NEED ANSWER: why does direct-calling *MODE_ID() always return 0, but main->can(...) and eval(...) returns correct values?
    #        RPerl::diag('have $type = ' . $type . "\n");
    #        my string $eval_string = 'main::RPerl__DataType__' . $type . '__MODE_ID();';
    #        RPerl::diag('have $eval_string = ' . $eval_string . "\n");
    #        my string $eval_retval = eval($eval_string);
    #        RPerl::diag('have $eval_retval = ' . $eval_retval . "\n");
    #        RPerl::diag(q{have main::RPerl__DataType__Integer__MODE_ID() = '} . main::RPerl__DataType__Integer__MODE_ID() . "'\n");
    #        RPerl::diag(q{have main::RPerl__DataType__Number__MODE_ID() = '} . main::RPerl__DataType__Number__MODE_ID() . "'\n");
    #        RPerl::diag(q{have main::RPerl__DataType__String__MODE_ID() = '} . main::RPerl__DataType__String__MODE_ID() . "'\n");

    lives_and(
        sub {
            is( $RPerl::MODES->{ main->can( 'RPerl__DataType__' . $type . '__MODE_ID' )->() }->{ops},
                $ops, 'main::RPerl__DataType__' . $type . '__MODE_ID() ops returns ' . $ops );
        },
        'main::RPerl__DataType__' . $type . '__MODE_ID() lives'
    );
    lives_and(
        sub {
            is( $RPerl::MODES->{ main->can( 'RPerl__DataType__' . $type . '__MODE_ID' )->() }->{types},
                $types, 'main::RPerl__DataType__' . $type . '__MODE_ID() types returns ' . $types );
        },
        'main::RPerl__' . $type . '__MODE_ID() lives'
    );
=cut

    # [[[ INPUT DATA ]]]
    # [[[ INPUT DATA ]]]
    # [[[ INPUT DATA ]]]

    my number_arrayref_arrayref $inputs_vector_vector_euclidian = [
        [ 0.0, 0.0,  0.0,  0.0 ],
        [ 0.0, 3.0,  4.0,  12.0 ],
        [ 0.0, 4.0,  12.0, 3.0 ],
        [ 0.0, 12.0, 3.0,  4.0 ],
        [ 0.0, 12.0, 4.0,  3.0 ],
        [ 0.0, 4.0,  3.0,  12.0 ],
        [ 0.0, 3.0,  12.0, 4.0 ],
        [ 0.0, -3.0, 4.0,  12.0 ],
        [ 0.0, 3.0,  -4.0, 12.0 ],
        [ 0.0, 3.0,  4.0,  -12.0 ]
    ];

    # both $inputs_multi_purpose_0 and $inputs_multi_purpose_1 used for:
    # inner_product_vector_bivector_euclidean(), inner_product_bivector_vector_euclidean(),
    # outer_product_vector_bivector_euclidean(), and outer_product_bivector_vector_euclidean();
    # $inputs_multi_purpose_bivector is also used for:
    # inner_product_bivector_bivector_euclidean(), and outer_product_bivector_bivector_euclidean()
    my number_arrayref_arrayref $inputs_multi_purpose_vector = [
        [ 0.0, 0.0,  0.0,  0.0 ],
        [ 0.0, 1.0,  0.0,  0.0 ],
        [ 0.0, 0.0,  1.0,  0.0 ],
        [ 0.0, 0.0,  0.0,  1.0 ],
        [ 0.0, -1.0, 0.0,  0.0 ],
        [ 0.0, 0.0,  -1.0, 0.0 ],
        [ 0.0, 0.0,  0.0,  -1.0 ]
    ];

    my number_arrayref_arrayref $inputs_multi_purpose_bivector = [
        [ 0.0, 0.0,                                  0.0,                                  0.0 ],
        [ 0.0, RIGHT_TRIANGLE_LEG_3_1(),             RIGHT_TRIANGLE_LEG_3_2(),             RIGHT_TRIANGLE_LEG_3_3() ],
        [ 0.0, UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(), UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(), UNIT_VECTOR_MAGNITUDE_NORMALIZED_3() ],
        [ 0.0, 1.0,                                  0.0,                                  0.0 ],
        [ 0.0, 0.0,                                  1.0,                                  0.0 ],
        [ 0.0, 0.0,                                  0.0,                                  1.0 ],
        [ 0.0, UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), 0.0 ],
        [ 0.0, 0.0,                                  UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), UNIT_VECTOR_MAGNITUDE_NORMALIZED_2() ],
        [ 0.0, UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), 0.0,                                  UNIT_VECTOR_MAGNITUDE_NORMALIZED_2() ]
    ];

    # [[[ OUTPUT DATA ]]]
    # [[[ OUTPUT DATA ]]]
    # [[[ OUTPUT DATA ]]]

    my number_arrayref_arrayref $outputs_inner_product_vector_vector_euclidean = [
        [ 0.0, 0.0,    0.0,   0.0,   0.0,   0.0,    0.0,   0.0,    0.0,    0.0 ],
        [ 0.0, 169.0,  96.0,  96.0,  88.0,  168.0,  105.0, 151.0,  137.0,  -119.0 ],
        [ 0.0, 96.0,   169.0, 96.0,  105.0, 88.0,   168.0, 72.0,   0.0,    24.0 ],
        [ 0.0, 96.0,   96.0,  169.0, 168.0, 105.0,  88.0,  24.0,   72.0,   0.0 ],
        [ 0.0, 88.0,   105.0, 168.0, 169.0, 96.0,   96.0,  16.0,   56.0,   16.0 ],
        [ 0.0, 168.0,  88.0,  105.0, 96.0,  169.0,  96.0,  144.0,  144.0,  -120.0 ],
        [ 0.0, 105.0,  168.0, 88.0,  96.0,  96.0,   169.0, 87.0,   9.0,    9.0 ],
        [ 0.0, 151.0,  72.0,  24.0,  16.0,  144.0,  87.0,  169.0,  119.0,  -137.0 ],
        [ 0.0, 137.0,  0.0,   72.0,  56.0,  144.0,  9.0,   119.0,  169.0,  -151.0 ],
        [ 0.0, -119.0, 24.0,  0.0,   16.0,  -120.0, 9.0,   -137.0, -151.0, 169.0 ]
    ];

    # $outputs_inner_product_multi_purpose_euclidean used for inner_product_vector_bivector_euclidean() and inner_product_bivector_vector_euclidean()
    my number_arrayref_arrayref_arrayref $outputs_inner_product_multi_purpose_euclidean = [
        [ [ 0.0, 0.0, 0.0 ], [ 0.0, 0.0, 0.0 ], [ 0.0, 0.0, 0.0 ], [ 0.0, 0.0, 0.0 ], [ 0.0, 0.0, 0.0 ], [ 0.0, 0.0, 0.0 ], [ 0.0, 0.0, 0.0 ] ],
        [   [ 0.0,                           0.0,                           0.0 ],
            [ 0.0,                           RIGHT_TRIANGLE_LEG_3_1(),      -1 * RIGHT_TRIANGLE_LEG_3_3() ],
            [ -1 * RIGHT_TRIANGLE_LEG_3_1(), 0.0,                           RIGHT_TRIANGLE_LEG_3_2() ],
            [ RIGHT_TRIANGLE_LEG_3_3(),      -1 * RIGHT_TRIANGLE_LEG_3_2(), 0.0 ],
            [ 0.0,                           -1 * RIGHT_TRIANGLE_LEG_3_1(), RIGHT_TRIANGLE_LEG_3_3() ],
            [ RIGHT_TRIANGLE_LEG_3_1(),      0.0,                           -1 * RIGHT_TRIANGLE_LEG_3_2() ],
            [ -1 * RIGHT_TRIANGLE_LEG_3_3(), RIGHT_TRIANGLE_LEG_3_2(),      0.0 ]
        ],
        [   [ 0.0,                                       0.0,                                       0.0 ],
            [ 0.0,                                       UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(),      -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_3() ],
            [ -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(), 0.0,                                       UNIT_VECTOR_MAGNITUDE_NORMALIZED_3() ],
            [ UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(),      -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(), 0.0 ],
            [ 0.0,                                       -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(), UNIT_VECTOR_MAGNITUDE_NORMALIZED_3() ],
            [ UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(),      0.0,                                       -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_3() ],
            [ -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(), UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(),      0.0 ]
        ],
        [ [ 0.0, 0.0, 0.0 ], [ 0.0, 1.0, 0.0 ],  [ -1.0, 0.0, 0.0 ], [ 0.0, 0.0,  0.0 ], [ 0.0, -1.0, 0.0 ], [ 1.0, 0.0, 0.0 ],  [ 0.0,  0.0, 0.0 ] ],
        [ [ 0.0, 0.0, 0.0 ], [ 0.0, 0.0, 0.0 ],  [ 0.0,  0.0, 1.0 ], [ 0.0, -1.0, 0.0 ], [ 0.0, 0.0,  0.0 ], [ 0.0, 0.0, -1.0 ], [ 0.0,  1.0, 0.0 ] ],
        [ [ 0.0, 0.0, 0.0 ], [ 0.0, 0.0, -1.0 ], [ 0.0,  0.0, 0.0 ], [ 1.0, 0.0,  0.0 ], [ 0.0, 0.0,  1.0 ], [ 0.0, 0.0, 0.0 ],  [ -1.0, 0.0, 0.0 ] ],
        [   [ 0.0,                                       0.0,                                       0.0 ],
            [ 0.0,                                       UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(),      0.0 ],
            [ -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), 0.0,                                       UNIT_VECTOR_MAGNITUDE_NORMALIZED_2() ],
            [ 0.0,                                       -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), 0.0 ],
            [ 0.0,                                       -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), 0.0 ],
            [ UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(),      0.0,                                       -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2() ],
            [ 0.0,                                       UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(),      0.0 ]
        ],
        [   [ 0.0,                                       0.0,                                       0.0 ],
            [ 0.0,                                       0.0,                                       -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2() ],
            [ 0.0,                                       0.0,                                       UNIT_VECTOR_MAGNITUDE_NORMALIZED_2() ],
            [ UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(),      -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), 0.0 ],
            [ 0.0,                                       0.0,                                       UNIT_VECTOR_MAGNITUDE_NORMALIZED_2() ],
            [ 0.0,                                       0.0,                                       -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2() ],
            [ -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(),      0.0 ]
        ],
        [   [ 0.0,                                       0.0,                                       0.0 ],
            [ 0.0,                                       UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(),      -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2() ],
            [ -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), 0.0,                                       0.0 ],
            [ UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(),      0.0,                                       0.0 ],
            [ 0.0,                                       -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), UNIT_VECTOR_MAGNITUDE_NORMALIZED_2() ],
            [ UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(),      0.0,                                       0.0 ],
            [ -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), 0.0,                                       0.0 ]
        ]
    ];

    my number_arrayref_arrayref $outputs_inner_product_bivector_bivector_euclidean = [
        [ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 ],
        [   0.0, -1.0, -0.843_82,
            -1 * RIGHT_TRIANGLE_LEG_3_1(),
            -1 * RIGHT_TRIANGLE_LEG_3_2(),
            -1 * RIGHT_TRIANGLE_LEG_3_3(),
            -0.380_75, -0.870_285_3, -0.815_892_4
        ],
        [   0.0, -0.843_82, -1.0,
            -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(),
            -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(),
            -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(),
            -0.816_496_6, -0.816_496_6, -0.816_496_6
        ],
        [   0.0,
            -1 * RIGHT_TRIANGLE_LEG_3_1(),
            -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(),
            -1.0, 0.0, 0.0, -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(),
            0.0, -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2()
        ],
        [   0.0,
            -1 * RIGHT_TRIANGLE_LEG_3_2(),
            -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(),
            0.0, -1.0, 0.0,
            -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(),
            -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), 0.0
        ],
        [   0.0,
            -1 * RIGHT_TRIANGLE_LEG_3_3(),
            -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(),
            0.0, 0.0, -1.0, 0.0,
            -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(),
            -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2()
        ],
        [ 0.0, -0.380_75, -0.816_496_6, -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), 0.0, -1.0, -0.5, -0.5 ],
        [ 0.0, -0.870_285_3, -0.816_496_6, 0.0, -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), -0.5, -1.0, -0.5 ],
        [ 0.0, -0.815_892_4, -0.816_496_6, -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), 0.0, -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), -0.5, -0.5, -1.0 ]
    ];

    my number_arrayref_arrayref_arrayref $outputs_outer_product_vector_vector_euclidean = [
        [   [ 0.0, 0.0, 0.0 ],
            [ 0.0, 0.0, 0.0 ],
            [ 0.0, 0.0, 0.0 ],
            [ 0.0, 0.0, 0.0 ],
            [ 0.0, 0.0, 0.0 ],
            [ 0.0, 0.0, 0.0 ],
            [ 0.0, 0.0, 0.0 ],
            [ 0.0, 0.0, 0.0 ],
            [ 0.0, 0.0, 0.0 ],
            [ 0.0, 0.0, 0.0 ]
        ],
        [   [ 0.0,   0.0,    0.0 ],
            [ 0.0,   0.0,    0.0 ],
            [ 20.0,  -132.0, 39.0 ],
            [ -39.0, -20.0,  132.0 ],
            [ -36.0, -36.0,  135.0 ],
            [ -7.0,  12.0,   12.0 ],
            [ 24.0,  -128.0, 24.0 ],
            [ 24.0,  0.0,    -72.0 ],
            [ -24.0, 96.0,   0.0 ],
            [ 0.0,   -96.0,  72.0 ]
        ],
        [   [ 0.0,    0.0,    0.0 ],
            [ -20.0,  132.0,  -39.0 ],
            [ 0.0,    0.0,    0.0 ],
            [ -132.0, 39.0,   20.0 ],
            [ -128.0, 24.0,   24.0 ],
            [ -36.0,  135.0,  -36.0 ],
            [ 12.0,   12.0,   -7.0 ],
            [ 52.0,   132.0,  -57.0 ],
            [ -52.0,  156.0,  -39.0 ],
            [ -20.0,  -156.0, 57.0 ]
        ],
        [   [ 0.0,   0.0,   0.0 ],
            [ 39.0,  20.0,  -132.0 ],
            [ 132.0, -39.0, -20.0 ],
            [ 0.0,   0.0,   0.0 ],
            [ 12.0,  -7.0,  12.0 ],
            [ 24.0,  24.0,  -128.0 ],
            [ 135.0, -36.0, -36.0 ],
            [ 57.0,  20.0,  -156.0 ],
            [ -57.0, 52.0,  -132.0 ],
            [ 39.0,  -52.0, 156.0 ]
        ],
        [   [ 0.0,   0.0,   0.0 ],
            [ 36.0,  36.0,  -135.0 ],
            [ 128.0, -24.0, -24.0 ],
            [ -12.0, 7.0,   -12.0 ],
            [ 0.0,   0.0,   0.0 ],
            [ 20.0,  39.0,  -132.0 ],
            [ 132.0, -20.0, -39.0 ],
            [ 60.0,  36.0,  -153.0 ],
            [ -60.0, 60.0,  -135.0 ],
            [ 36.0,  -60.0, 153.0 ]
        ],
        [   [ 0.0,   0.0,    0.0 ],
            [ 7.0,   -12.0,  -12.0 ],
            [ 36.0,  -135.0, 36.0 ],
            [ -24.0, -24.0,  128.0 ],
            [ -20.0, -39.0,  132.0 ],
            [ 0.0,   0.0,    0.0 ],
            [ 39.0,  -132.0, 20.0 ],
            [ 25.0,  -12.0,  -84.0 ],
            [ -25.0, 84.0,   -12.0 ],
            [ 7.0,   -84.0,  84.0 ]
        ],
        [   [ 0.0,    0.0,    0.0 ],
            [ -24.0,  128.0,  -24.0 ],
            [ -12.0,  -12.0,  7.0 ],
            [ -135.0, 36.0,   36.0 ],
            [ -132.0, 20.0,   39.0 ],
            [ -39.0,  132.0,  -20.0 ],
            [ 0.0,    0.0,    0.0 ],
            [ 48.0,   128.0,  -48.0 ],
            [ -48.0,  160.0,  -24.0 ],
            [ -24.0,  -160.0, 48.0 ]
        ],
        [   [ 0.0,   0.0,    0.0 ],
            [ -24.0, 0.0,    72.0 ],
            [ -52.0, -132.0, 57.0 ],
            [ -57.0, -20.0,  156.0 ],
            [ -60.0, -36.0,  153.0 ],
            [ -25.0, 12.0,   84.0 ],
            [ -48.0, -128.0, 48.0 ],
            [ 0.0,   0.0,    0.0 ],
            [ 0.0,   96.0,   72.0 ],
            [ -24.0, -96.0,  0.0 ]
        ],
        [   [ 0.0,  0.0,    0.0 ],
            [ 24.0, -96.0,  0.0 ],
            [ 52.0, -156.0, 39.0 ],
            [ 57.0, -52.0,  132.0 ],
            [ 60.0, -60.0,  135.0 ],
            [ 25.0, -84.0,  12.0 ],
            [ 48.0, -160.0, 24.0 ],
            [ 0.0,  -96.0,  -72.0 ],
            [ 0.0,  0.0,    0.0 ],
            [ 24.0, 0.0,    72.0 ]
        ],
        [   [ 0.0,   0.0,   0.0 ],
            [ 0.0,   96.0,  -72.0 ],
            [ 20.0,  156.0, -57.0 ],
            [ -39.0, 52.0,  -156.0 ],
            [ -36.0, 60.0,  -153.0 ],
            [ -7.0,  84.0,  -84.0 ],
            [ 24.0,  160.0, -48.0 ],
            [ 24.0,  96.0,  0.0 ],
            [ -24.0, 0.0,   -72.0 ],
            [ 0.0,   0.0,   0.0 ]
        ],
    ];

    # $outputs_outer_product_multi_purpose_euclidean used for outer_product_vector_bivector_euclidean() and outer_product_bivector_vector_euclidean()
    my number_arrayref_arrayref $outputs_outer_product_multi_purpose_euclidean = [
        [ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 ],
        [   0.0,                           RIGHT_TRIANGLE_LEG_3_2(),      RIGHT_TRIANGLE_LEG_3_3(), RIGHT_TRIANGLE_LEG_3_1(),
            -1 * RIGHT_TRIANGLE_LEG_3_2(), -1 * RIGHT_TRIANGLE_LEG_3_3(), -1 * RIGHT_TRIANGLE_LEG_3_1()
        ],
        [   0.0,                                       UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(),
            UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(),      UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(),
            -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(), -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(),
            -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_3()
        ],
        [ 0.0, 0.0, 0.0, 1.0, 0.0,  0.0,  -1.0 ],
        [ 0.0, 1.0, 0.0, 0.0, -1.0, 0.0,  0.0 ],
        [ 0.0, 0.0, 1.0, 0.0, 0.0,  -1.0, 0.0 ],
        [   0.0,                                       UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(),
            0.0,                                       UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(),
            -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), 0.0,
            -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2()
        ],
        [   0.0,
            UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(),
            UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(),
            0.0,
            -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(),
            -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), 0.0
        ],
        [   0.0, 0.0,
            UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(),
            UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(),
            0.0,
            -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(),
            -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2()
        ]
    ];

    my number_arrayref_arrayref_arrayref $outputs_outer_product_bivector_bivector_euclidean = [
        [   [ 0.0, 0.0, 0.0 ],
            [ 0.0, 0.0, 0.0 ],
            [ 0.0, 0.0, 0.0 ],
            [ 0.0, 0.0, 0.0 ],
            [ 0.0, 0.0, 0.0 ],
            [ 0.0, 0.0, 0.0 ],
            [ 0.0, 0.0, 0.0 ],
            [ 0.0, 0.0, 0.0 ],
            [ 0.0, 0.0, 0.0 ]
        ],
        [   [ 0.0,                           0.0,                           0.0 ],
            [ 0.0,                           0.0,                           0.0 ],
            [ 0.355_292_5,                   -0.399_704_0,                  0.044_411_6 ],
            [ 0.0,                           -1 * RIGHT_TRIANGLE_LEG_3_3(), RIGHT_TRIANGLE_LEG_3_2() ],
            [ RIGHT_TRIANGLE_LEG_3_3(),      0.0,                           -1 * RIGHT_TRIANGLE_LEG_3_1() ],
            [ -1 * RIGHT_TRIANGLE_LEG_3_2(), RIGHT_TRIANGLE_LEG_3_1(),      0.0 ],
            [ 0.652_714_0,                   -0.652_714_0,                  0.054_392_8 ],
            [ 0.435_142_6,                   0.163_178_5,                   -0.163_178_5 ],
            [ -0.217_571_3,                  -0.489_535_5,                  0.217_571_3 ]
        ],
        [   [ 0.0,                                       0.0,                                       0.0 ],
            [ -0.355_292_5,                              0.399_704_0,                               -0.044_411_6 ],
            [ 0.0,                                       0.0,                                       0.0 ],
            [ 0.0,                                       -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(), UNIT_VECTOR_MAGNITUDE_NORMALIZED_3() ],
            [ UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(),      0.0,                                       -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_3() ],
            [ -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(), UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(),      0.0 ],
            [ 0.408_248_3,                               -0.408_248_3,                              0.0 ],
            [ 0.0,                                       0.408_248_3,                               -0.408_248_3 ],
            [ -0.408_248_3,                              0.0,                                       0.408_248_3 ]
        ],
        [   [ 0.0, 0.0,                                  0.0 ],
            [ 0.0, RIGHT_TRIANGLE_LEG_3_3(),             -1 * RIGHT_TRIANGLE_LEG_3_2() ],
            [ 0.0, UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(), -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_3() ],
            [ 0.0, 0.0,                                  0.0 ],
            [ 0.0, 0.0,                                  -1.0 ],
            [ 0.0, 1.0,                                  0.0 ],
            [ 0.0, 0.0,                                  -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2() ],
            [ 0.0, UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2() ],
            [ 0.0, UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), 0.0 ]
        ],
        [   [ 0.0,                                       0.0, 0.0 ],
            [ -1 * RIGHT_TRIANGLE_LEG_3_3(),             0.0, RIGHT_TRIANGLE_LEG_3_1() ],
            [ -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(), 0.0, UNIT_VECTOR_MAGNITUDE_NORMALIZED_3() ],
            [ 0.0,                                       0.0, 1.0 ],
            [ 0.0,                                       0.0, 0.0 ],
            [ -1.0,                                      0.0, 0.0 ],
            [ 0.0,                                       0.0, UNIT_VECTOR_MAGNITUDE_NORMALIZED_2() ],
            [ -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), 0.0, 0.0 ],
            [ -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), 0.0, UNIT_VECTOR_MAGNITUDE_NORMALIZED_2() ]
        ],
        [   [ 0.0,                                  0.0,                                       0.0 ],
            [ RIGHT_TRIANGLE_LEG_3_2(),             -1 * RIGHT_TRIANGLE_LEG_3_1(),             0.0 ],
            [ UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(), -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_3(), 0.0 ],
            [ 0.0,                                  -1.0,                                      0.0 ],
            [ 1.0,                                  0.0,                                       0.0 ],
            [ 0.0,                                  0.0,                                       0.0 ],
            [ UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), 0.0 ],
            [ UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), 0.0,                                       0.0 ],
            [ 0.0,                                  -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), 0.0 ]
        ],
        [   [ 0.0,                                       0.0,                                  0.0 ],
            [ -0.652_714_0,                              0.652_714_0,                          -0.054_392_8 ],
            [ -0.408_248_3,                              0.408_248_3,                          0.0 ],
            [ 0.0,                                       0.0,                                  UNIT_VECTOR_MAGNITUDE_NORMALIZED_2() ],
            [ 0.0,                                       0.0,                                  -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2() ],
            [ -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), 0.0 ],
            [ 0.0,                                       0.0,                                  0.0 ],
            [ -0.5,                                      0.5,                                  -0.5 ],
            [ -0.5,                                      0.5,                                  0.5 ]
        ],
        [   [ 0.0,                                       0.0,                                       0.0 ],
            [ -0.435_142_6,                              -0.163_178_5,                              0.163_178_5 ],
            [ 0.0,                                       -0.408_248_3,                              0.408_248_3 ],
            [ 0.0,                                       -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), UNIT_VECTOR_MAGNITUDE_NORMALIZED_2() ],
            [ UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(),      0.0,                                       0.0 ],
            [ -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), 0.0,                                       0.0 ],
            [ 0.5,                                       -0.5,                                      0.5 ],
            [ 0.0,                                       0.0,                                       0.0 ],
            [ -0.5,                                      -0.5,                                      0.5 ]
        ],
        [   [ 0.0,                                  0.0,                                       0.0 ],
            [ 0.217_571_3,                          0.489_535_5,                               -0.217_571_3 ],
            [ 0.408_248_3,                          0.0,                                       -0.408_248_3 ],
            [ 0.0,                                  -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), 0.0 ],
            [ UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(), 0.0,                                       -1 * UNIT_VECTOR_MAGNITUDE_NORMALIZED_2() ],
            [ 0.0,                                  UNIT_VECTOR_MAGNITUDE_NORMALIZED_2(),      0.0 ],
            [ 0.5,                                  -0.5,                                      -0.5 ],
            [ 0.5,                                  0.5,                                       -0.5 ],
            [ 0.0,                                  0.0,                                       0.0 ]
        ]
    ];

    my number_arrayref $retval_bivector;

    # [[[ EUCLIDEAN INNER PRODUCTS ]]]
    # [[[ EUCLIDEAN INNER PRODUCTS ]]]
    # [[[ EUCLIDEAN INNER PRODUCTS ]]]

    foreach my integer $i ( 0 .. 9 ) {
        foreach my integer $j ( 0 .. 9 ) {

            # TGAPR00
            lives_and(
                sub {
                    delta_ok(
                        MathPerl::GeometricAlgebra::Products::inner_product__vector_vector_euclidean(
                            $inputs_vector_vector_euclidian->[$i],
                            $inputs_vector_vector_euclidian->[$j]
                        ),
                        $outputs_inner_product_vector_vector_euclidean->[$i]->[$j],
                        q{TGAPR00 MathPerl::GeometricAlgebra::Products::inner_product__vector_vector_euclidean() [}
                            . $i . q{, }
                            . $j
                            . q{] returns correct value}
                    );
                },
                q{TGAPR00 MathPerl::GeometricAlgebra::Products::inner_product__vector_vector_euclidean() [} . $i . q{, } . $j . q{] lives}
            );
        }
    }

    foreach my integer $i ( 0 .. 6 ) {
        foreach my integer $j ( 0 .. 8 ) {

            # TGAPR01
            lives_ok(
                sub {
                    $retval_bivector = MathPerl::GeometricAlgebra::Products::inner_product__vector_bivector_euclidean( $inputs_multi_purpose_vector->[$i],
                        $inputs_multi_purpose_bivector->[$j] );
                },
                q{TGAPR01 MathPerl::GeometricAlgebra::Products::inner_product__vector_bivector_euclidean() [} . $i . q{, } . $j . q{] lives}
            );
            foreach my integer $k ( 1 .. 3 ) {
                delta_ok(
                    $retval_bivector->[$k],
                    $outputs_inner_product_multi_purpose_euclidean->[$j]->[$i]->[ $k - 1 ],
                    q{TGAPR01 MathPerl::GeometricAlgebra::Products::inner_product__vector_bivector_euclidean() [}
                        . $i . q{, }
                        . $j . q{, }
                        . $k
                        . q{] returns correct value}
                );
            }
        }
    }

    foreach my integer $i ( 0 .. 6 ) {
        foreach my integer $j ( 0 .. 8 ) {

            # TGAPR02
            lives_ok(
                sub {
                    $retval_bivector = MathPerl::GeometricAlgebra::Products::inner_product__bivector_vector_euclidean( $inputs_multi_purpose_bivector->[$j],
                        $inputs_multi_purpose_vector->[$i] );
                },
                q{TGAPR02 MathPerl::GeometricAlgebra::Products::inner_product__bivector_vector_euclidean() [} . $i . q{, } . $j . q{] lives}
            );
            foreach my integer $k ( 1 .. 3 ) {
                delta_ok(
                    -1 * $retval_bivector->[$k],
                    $outputs_inner_product_multi_purpose_euclidean->[$j]->[$i]->[ $k - 1 ],
                    q{TGAPR02 MathPerl::GeometricAlgebra::Products::inner_product__bivector_vector_euclidean() [}
                        . $i . q{, }
                        . $j . q{, }
                        . $k
                        . q{] returns correct value}
                );
            }
        }
    }

    foreach my integer $i ( 0 .. 8 ) {
        foreach my integer $j ( 0 .. 8 ) {

            # TGAPR03
            lives_and(
                sub {
                    delta_ok(
                        MathPerl::GeometricAlgebra::Products::inner_product__bivector_bivector_euclidean(
                            $inputs_multi_purpose_bivector->[$i],
                            $inputs_multi_purpose_bivector->[$j]
                        ),
                        $outputs_inner_product_bivector_bivector_euclidean->[$i]->[$j],
                        q{TGAPR03 MathPerl::GeometricAlgebra::Products::inner_product__bivector_bivector_euclidean() [}
                            . $i . q{, }
                            . $j
                            . q{] returns correct value}
                    );
                },
                q{TGAPR03 MathPerl::GeometricAlgebra::Products::inner_product__bivector_bivector_euclidean() [} . $i . q{, } . $j . q{] lives}
            );
        }
    }

    foreach my integer $i ( 0 .. 9 ) {
        foreach my integer $j ( 0 .. 9 ) {

            # TGAPR04
            lives_ok(
                sub {
                    $retval_bivector = MathPerl::GeometricAlgebra::Products::outer_product__vector_vector_euclidean( $inputs_vector_vector_euclidian->[$i],
                        $inputs_vector_vector_euclidian->[$j] );
                },
                q{TGAPR04 MathPerl::GeometricAlgebra::Products::outer_product__vector_vector_euclidean() [} . $i . q{, } . $j . q{] lives}
            );
            foreach my integer $k ( 1 .. 3 ) {
                delta_ok(
                    $retval_bivector->[$k],
                    $outputs_outer_product_vector_vector_euclidean->[$i]->[$j]->[ $k - 1 ],
                    q{TGAPR04 MathPerl::GeometricAlgebra::Products::outer_product__vector_vector_euclidean() [}
                        . $i . q{, }
                        . $j . q{, }
                        . $k
                        . q{] returns correct value}
                );
            }
        }
    }

    foreach my integer $i ( 0 .. 6 ) {
        foreach my integer $j ( 0 .. 8 ) {

            # TGAPR05
            lives_and(
                sub {
                    delta_ok(
                        MathPerl::GeometricAlgebra::Products::outer_product__vector_bivector_euclidean(
                            $inputs_multi_purpose_vector->[$i],
                            $inputs_multi_purpose_bivector->[$j]
                        ),
                        $outputs_outer_product_multi_purpose_euclidean->[$j]->[$i],
                        q{TGAPR05 MathPerl::GeometricAlgebra::Products::outer_product__vector_bivector_euclidean() [}
                            . $i . q{, }
                            . $j
                            . q{] returns correct value}
                    );
                },
                q{TGAPR05 MathPerl::GeometricAlgebra::Products::outer_product__vector_bivector_euclidean() [} . $i . q{, } . $j . q{] lives}
            );
        }
    }

    foreach my integer $i ( 0 .. 8 ) {
        foreach my integer $j ( 0 .. 6 ) {

            # TGAPR06
            lives_and(
                sub {
                    delta_ok(
                        MathPerl::GeometricAlgebra::Products::outer_product__bivector_vector_euclidean(
                            $inputs_multi_purpose_bivector->[$i],
                            $inputs_multi_purpose_vector->[$j]
                        ),
                        $outputs_outer_product_multi_purpose_euclidean->[$i]->[$j],
                        q{TGAPR06 MathPerl::GeometricAlgebra::Products::outer_product__bivector_vector_euclidean() [}
                            . $i . q{, }
                            . $j
                            . q{] returns correct value}
                    );
                },
                q{TGAPR06 MathPerl::GeometricAlgebra::Products::outer_product__bivector_vector_euclidean() [} . $i . q{, } . $j . q{] lives}
            );
        }
    }

    foreach my integer $i ( 0 .. 8 ) {
        foreach my integer $j ( 0 .. 8 ) {

            # TGAPR07
            lives_ok(
                sub {
                    $retval_bivector = MathPerl::GeometricAlgebra::Products::outer_product__bivector_bivector_euclidean( $inputs_multi_purpose_bivector->[$i],
                        $inputs_multi_purpose_bivector->[$j] );
                },
                q{TGAPR07 MathPerl::GeometricAlgebra::Products::outer_product__bivector_bivector_euclidean() [} . $i . q{, } . $j . q{] lives}
            );
            foreach my integer $k ( 1 .. 3 ) {
                delta_ok(
                    $retval_bivector->[$k],
                    $outputs_outer_product_bivector_bivector_euclidean->[$i]->[$j]->[ $k - 1 ],
                    q{TGAPR07 MathPerl::GeometricAlgebra::Products::outer_product__bivector_bivector_euclidean() [}
                        . $i . q{, }
                        . $j . q{, }
                        . $k
                        . q{] returns correct value}
                );
            }
        }
    }
}

done_testing();
