# [[[ PREPROCESSOR ]]]
# <<< TYPE_CHECKING: TRACE >>>

# [[[ HEADER ]]]
package MathPerl::GeometricAlgebra::Products;
use strict;
use warnings;
use RPerl::AfterSubclass;
our $VERSION = 0.000_200;

# [[[ OO INHERITANCE ]]]
use parent qw(MathPerl::GeometricAlgebra);
use MathPerl::GeometricAlgebra;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls) # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils

# [[[ OO PROPERTIES ]]]
our hashref $properties = {};

# [[[ SUBROUTINES ]]]

# [[[ EUCLIDEAN INNER PRODUCTS ]]]
# [[[ EUCLIDEAN INNER PRODUCTS ]]]
# [[[ EUCLIDEAN INNER PRODUCTS ]]]

our number $inner_product__vector_vector_euclidean = sub {
    ( my number_arrayref $input_vector_1, my number_arrayref $input_vector_2 ) = @_;

    # bound checking
    if ( ( scalar @{$input_vector_1} ) != 4 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_vector_1 is not of length 4, croaking');
    }
    if ( ( scalar @{$input_vector_2} ) != 4 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_vector_2 is not of length 4, croaking');
    }

    #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__vector_vector_euclidean(), top of subroutine...\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__vector_vector_euclidean(), received \$input_vector_1\n" . Dumper($input_vector_1) . "\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__vector_vector_euclidean(), received \$input_vector_2\n" . Dumper($input_vector_2) . "\n");

    my number $return_value_number
        = ( $input_vector_1->[1] * $input_vector_2->[1] ) + ( $input_vector_1->[2] * $input_vector_2->[2] ) + ( $input_vector_1->[3] * $input_vector_2->[3] );

#    RPerl::diag("in PERLOPS_PERLTYPES inner_product__vector_vector_euclidean(), have \$return_value_number = $return_value_number\n");

    return $return_value_number;
};

our number_arrayref $inner_product__vector_bivector_euclidean = sub {
    ( my number_arrayref $input_vector, my number_arrayref $input_bivector) = @_;

    # bound checking
    if ( ( scalar @{$input_vector} ) != 4 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_vector is not of length 4, croaking');
    }
    if ( ( scalar @{$input_bivector} ) != 4 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_bivector is not of length 4, croaking');
    }

    my number_arrayref $return_value_vector = [];

#    RPerl::diag('in PERLOPS_PERLTYPES inner_product__vector_bivector_euclidean(), top of subroutine...' . "\n");
#    RPerl::diag('in PERLOPS_PERLTYPES inner_product__vector_bivector_euclidean(), received $input_vector' . "\n" . Dumper($input_vector) . "\n");
#    RPerl::diag('in PERLOPS_PERLTYPES inner_product__vector_bivector_euclidean(), received $input_bivector' . "\n" . Dumper($input_bivector) . "\n");

#    RPerl::diag('in PERLOPS_PERLTYPES inner_product__vector_bivector_euclidean(), setting $return_value_vector->[1] = ( ' . 
#        $input_vector->[3] . ' * ' . $input_bivector->[3] . ' ) - ( ' . $input_vector->[2] . ' * ' . $input_bivector->[1] . ' )' . "\n");
#    RPerl::diag('in PERLOPS_PERLTYPES inner_product__vector_bivector_euclidean(), setting $return_value_vector->[2] = ( ' . 
#        $input_vector->[1] . ' * ' . $input_bivector->[1] . ' ) - ( ' . $input_vector->[3] . ' * ' . $input_bivector->[2] . ' )' . "\n");
#    RPerl::diag('in PERLOPS_PERLTYPES inner_product__vector_bivector_euclidean(), setting $return_value_vector->[3] = ( ' . 
#        $input_vector->[2] . ' * ' . $input_bivector->[2] . ' ) - ( ' . $input_vector->[1] . ' * ' . $input_bivector->[3] . ' )' . "\n");

    $return_value_vector->[1] = ( $input_vector->[3] * $input_bivector->[3] ) - ( $input_vector->[2] * $input_bivector->[1] );
    $return_value_vector->[2] = ( $input_vector->[1] * $input_bivector->[1] ) - ( $input_vector->[3] * $input_bivector->[2] );
    $return_value_vector->[3] = ( $input_vector->[2] * $input_bivector->[2] ) - ( $input_vector->[1] * $input_bivector->[3] );

#    RPerl::diag('in PERLOPS_PERLTYPES inner_product__vector_bivector_euclidean(), returning $return_value_vector = ' . Dumper($return_value_vector) . "\n");
    return $return_value_vector;
};

our number_arrayref $inner_product__bivector_vector_euclidean = sub {
    ( my number_arrayref $input_bivector, my number_arrayref $input_vector) = @_;

    # bound checking
    if ( ( scalar @{$input_bivector} ) != 4 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_bivector is not of length 4, croaking');
    }
    if ( ( scalar @{$input_vector} ) != 4 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_vector is not of length 4, croaking');
    }

    my number_arrayref $return_value_vector = [];

    #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__bivector_vector_euclidean(), top of subroutine...\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__bivector_vector_euclidean(), received \$input_bivector\n" . Dumper($input_bivector) . "\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__bivector_vector_euclidean(), received \$input_vector\n" . Dumper($input_vector) . "\n");

    $return_value_vector->[1] = ( $input_bivector->[1] * $input_vector->[2] ) - ( $input_bivector->[3] * $input_vector->[3] );
    $return_value_vector->[2] = ( $input_bivector->[2] * $input_vector->[3] ) - ( $input_bivector->[1] * $input_vector->[1] );
    $return_value_vector->[3] = ( $input_bivector->[3] * $input_vector->[1] ) - ( $input_bivector->[2] * $input_vector->[2] );

   #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__bivector_vector_euclidean(), returning \$return_value_vector\n" . Dumper($return_value_vector) . "\n");
    return $return_value_vector;
};

our number $inner_product__bivector_bivector_euclidean = sub {
    ( my number_arrayref $input_bivector_1, my number_arrayref $input_bivector_2 ) = @_;

    # bound checking
    if ( ( scalar @{$input_bivector_1} ) != 4 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_bivector_1 is not of length 4, croaking');
    }
    if ( ( scalar @{$input_bivector_2} ) != 4 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_bivector_2 is not of length 4, croaking');
    }

    RPerl::diag('in PERLOPS_PERLTYPES inner_product__bivector_bivector_euclidean(), top of subroutine...' . "\n");
    RPerl::diag('in PERLOPS_PERLTYPES inner_product__bivector_bivector_euclidean(), received $input_bivector_1' . "\n" . Dumper($input_bivector_1) . "\n");
    RPerl::diag('in PERLOPS_PERLTYPES inner_product__bivector_bivector_euclidean(), received $input_bivector_2' . "\n" . Dumper($input_bivector_2) . "\n");

    RPerl::diag('in PERLOPS_PERLTYPES inner_product__bivector_bivector_euclidean(), setting $return_value_number = -1 * ( ' . 
        $input_bivector_1->[1] . ' * ' . $input_bivector_2->[1] . ' ) + ( ' . $input_bivector_1->[2] . ' * ' . $input_bivector_2->[2] . ' ) + ( ' . $input_bivector_1->[3] . ' * ' . $input_bivector_2->[3] . ' )' . "\n");

    my number $return_value_number
        = -1 * ( ( $input_bivector_1->[1] * $input_bivector_2->[1] ) + ( $input_bivector_1->[2] * $input_bivector_2->[2] ) + ( $input_bivector_1->[3] * $input_bivector_2->[3] ) );

    RPerl::diag('in PERLOPS_PERLTYPES inner_product__bivector_bivector_euclidean(), returning $return_value_number = ' . $return_value_number . "\n");
    return $return_value_number;
};

# [[[ EUCLIDEAN OUTER PRODUCTS ]]]
# [[[ EUCLIDEAN OUTER PRODUCTS ]]]
# [[[ EUCLIDEAN OUTER PRODUCTS ]]]

our number_arrayref $outer_product__vector_vector_euclidean = sub {
    ( my number_arrayref $input_vector_1, my number_arrayref $input_vector_2) = @_;

    # bound checking
    if ( ( scalar @{$input_vector_1} ) != 4 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_vector_1 is not of length 4, croaking');
    }
    if ( ( scalar @{$input_vector_2} ) != 4 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_vector_2 is not of length 4, croaking');
    }

    my number_arrayref $return_value_bivector = [];

#    RPerl::diag('in PERLOPS_PERLTYPES outer_product__vector_vector_euclidean(), top of subroutine...' . "\n");
#    RPerl::diag('in PERLOPS_PERLTYPES outer_product__vector_vector_euclidean(), received $input_vector_1' . "\n" . Dumper($input_vector_1) . "\n");
#    RPerl::diag('in PERLOPS_PERLTYPES outer_product__vector_vector_euclidean(), received $input_vector_2' . "\n" . Dumper($input_vector_2) . "\n");

#    RPerl::diag('in PERLOPS_PERLTYPES outer_product__vector_vector_euclidean(), setting $return_value_bivector->[1] = ( ' . 
#        $input_vector_1->[1] . ' * ' . $input_vector_2->[2] . ' ) - ( ' . $input_vector_1->[2] . ' * ' . $input_vector_2->[1] . ' )' . "\n");
#    RPerl::diag('in PERLOPS_PERLTYPES outer_product__vector_vector_euclidean(), setting $return_value_bivector->[2] = ( ' . 
#        $input_vector_1->[2] . ' * ' . $input_vector_2->[3] . ' ) - ( ' . $input_vector_1->[3] . ' * ' . $input_vector_2->[2] . ' )' . "\n");
#    RPerl::diag('in PERLOPS_PERLTYPES outer_product__vector_vector_euclidean(), setting $return_value_bivector->[3] = ( ' . 
#        $input_vector_1->[3] . ' * ' . $input_vector_2->[1] . ' ) - ( ' . $input_vector_1->[1] . ' * ' . $input_vector_2->[3] . ' )' . "\n");

    $return_value_bivector->[1] = ( $input_vector_1->[1] * $input_vector_2->[2] ) - ( $input_vector_1->[2] * $input_vector_2->[1] );
    $return_value_bivector->[2] = ( $input_vector_1->[2] * $input_vector_2->[3] ) - ( $input_vector_1->[3] * $input_vector_2->[2] );
    $return_value_bivector->[3] = ( $input_vector_1->[3] * $input_vector_2->[1] ) - ( $input_vector_1->[1] * $input_vector_2->[3] );

#    RPerl::diag('in PERLOPS_PERLTYPES outer_product__vector_vector_euclidean(), returning $return_value_bivector = ' . Dumper($return_value_bivector) . "\n");
    return $return_value_bivector;
};

our number $outer_product__vector_bivector_euclidean = sub {
    ( my number_arrayref $input_vector, my number_arrayref $input_bivector) = @_;

    # bound checking
    if ( ( scalar @{$input_vector} ) != 4 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_vector is not of length 4, croaking');
    }
    if ( ( scalar @{$input_bivector} ) != 4 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_bivector is not of length 4, croaking');
    }

    my number $return_value_number;

    #    RPerl::diag("in PERLOPS_PERLTYPES outer_product__vector_bivector_euclidean(), top of subroutine...\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES outer_product__vector_bivector_euclidean(), received \$input_vector\n" . Dumper($input_vector) . "\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES outer_product__vector_bivector_euclidean(), received \$input_bivector\n" . Dumper($input_bivector) . "\n");

    # DEV NOTE, CORRELATION #mp10: calculated the same way as outer_product__bivector_vector_euclidean()!
    $return_value_number
        = ( $input_bivector->[1] * $input_vector->[3] ) + ( $input_bivector->[2] * $input_vector->[1] ) + ( $input_bivector->[3] * $input_vector->[2] );

    #    RPerl::diag("in PERLOPS_PERLTYPES outer_product__vector_bivector_euclidean(), have \$return_value_number = $return_value_number\n");
    return $return_value_number;
};

our number $outer_product__bivector_vector_euclidean = sub {
    ( my number_arrayref $input_bivector, my number_arrayref $input_vector) = @_;

    # bound checking
    if ( ( scalar @{$input_bivector} ) != 4 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_bivector is not of length 4, croaking');
    }
    if ( ( scalar @{$input_vector} ) != 4 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_vector is not of length 4, croaking');
    }

    my number $return_value_number;

    #    RPerl::diag("in PERLOPS_PERLTYPES outer_product__bivector_vector_euclidean(), top of subroutine...\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES outer_product__bivector_vector_euclidean(), received \$input_bivector\n" . Dumper($input_bivector) . "\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES outer_product__bivector_vector_euclidean(), received \$input_vector\n" . Dumper($input_vector) . "\n");

    # DEV NOTE, CORRELATION #mp10: calculated the same way as outer_product__vector_bivector_euclidean()!
    $return_value_number
        = ( $input_bivector->[1] * $input_vector->[3] ) + ( $input_bivector->[2] * $input_vector->[1] ) + ( $input_bivector->[3] * $input_vector->[2] );

    #    RPerl::diag("in PERLOPS_PERLTYPES outer_product__bivector_vector_euclidean(), have \$return_value_number = $return_value_number\n");
    return $return_value_number;
};

our number_arrayref $outer_product__bivector_bivector_euclidean = sub {
    ( my number_arrayref $input_bivector_1, my number_arrayref $input_bivector_2) = @_;

    # bound checking
    if ( ( scalar @{$input_bivector_1} ) != 4 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_bivector_1 is not of length 4, croaking');
    }
    if ( ( scalar @{$input_bivector_2} ) != 4 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_bivector_2 is not of length 4, croaking');
    }

    my number_arrayref $return_value_bivector = [];

    #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__bivector_vector_euclidean(), top of subroutine...\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__bivector_vector_euclidean(), received \$input_bivector_1\n" . Dumper($input_bivector_1) . "\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__bivector_vector_euclidean(), received \$input_bivector_2\n" . Dumper($input_bivector_2) . "\n");

    $return_value_bivector->[1] = ( $input_bivector_1->[3] * $input_bivector_2->[2] ) - ( $input_bivector_1->[2] * $input_bivector_2->[3] );
    $return_value_bivector->[2] = ( $input_bivector_1->[1] * $input_bivector_2->[3] ) - ( $input_bivector_1->[3] * $input_bivector_2->[1] );
    $return_value_bivector->[3] = ( $input_bivector_1->[2] * $input_bivector_2->[1] ) - ( $input_bivector_1->[1] * $input_bivector_2->[2] );

   #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__bivector_vector_euclidean(), returning \$return_value_bivector\n" . Dumper($return_value_bivector) . "\n");
    return $return_value_bivector;
};

# [[[ MINKOWSKI INNER PRODUCTS ]]]
# [[[ MINKOWSKI INNER PRODUCTS ]]]
# [[[ MINKOWSKI INNER PRODUCTS ]]]

our number $inner_product__vector_vector_minkowski = sub {
    ( my number_arrayref $input_vector_1, my number_arrayref $input_vector_2 ) = @_;

    # bound checking
    if ( ( scalar @{$input_vector_1} ) != 4 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_vector_1 is not of length 4, croaking');
    }
    if ( ( scalar @{$input_vector_2} ) != 4 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_vector_2 is not of length 4, croaking');
    }

    #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__vector_vector_minkowski(), top of subroutine...\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__vector_vector_minkowski(), received \$input_vector_1\n" . Dumper($input_vector_1) . "\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__vector_vector_minkowski(), received \$input_vector_2\n" . Dumper($input_vector_2) . "\n");

    my number $return_value_number
        = ( ( $input_vector_1->[1] * $input_vector_2->[1] ) + ( $input_vector_1->[2] * $input_vector_2->[2] ) + ( $input_vector_1->[3] * $input_vector_2->[3] ) )
            - ( $input_vector_1->[0] * $input_vector_2->[0] );

#    RPerl::diag("in PERLOPS_PERLTYPES inner_product__vector_vector_minkowski(), have \$return_value_number = $return_value_number\n");

    return $return_value_number;
};

our number_arrayref $inner_product__vector_bivector_minkowski = sub {
    ( my number_arrayref $input_vector, my number_arrayref $input_bivector) = @_;

    # bound checking
    if ( ( scalar @{$input_vector} ) != 4 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_vector is not of length 4, croaking');
    }
    if ( ( scalar @{$input_bivector} ) != 6 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_bivector is not of length 6, croaking');
    }

    my number_arrayref $return_value_vector = [];

    #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__vector_bivector_minkowski(), top of subroutine...\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__vector_bivector_minkowski(), received \$input_vector\n" . Dumper($input_vector) . "\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__vector_bivector_minkowski(), received \$input_bivector\n" . Dumper($input_bivector) . "\n");

    $return_value_vector->[0] = -1 * ( ( $input_vector->[1] * $input_bivector->[0] ) + ( $input_vector->[2] * $input_bivector->[1] ) + ( $input_vector->[3] * $input_bivector->[3] ) );
    $return_value_vector->[1] = -1 * ( ( $input_vector->[0] * $input_bivector->[0] ) + ( $input_vector->[2] * $input_bivector->[3] ) + ( $input_vector->[3] * $input_bivector->[4] ) );
    $return_value_vector->[2] = ( $input_vector->[1] * $input_bivector->[3] ) - ( $input_vector->[3] * $input_bivector->[4] ) - ( $input_vector->[0] * $input_bivector->[1] );
    $return_value_vector->[3] = ( $input_vector->[1] * $input_bivector->[4] ) + ( $input_vector->[2] * $input_bivector->[5] ) - ( $input_vector->[0] * $input_bivector->[2] );

   #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__vector_bivector_minkowski(), returning \$return_value_vector\n" . Dumper($return_value_vector) . "\n");
    return $return_value_vector;
};

our number_arrayref $inner_product__bivector_vector_minkowski = sub {
    ( my number_arrayref $input_bivector, my number_arrayref $input_vector) = @_;

    # bound checking
    if ( ( scalar @{$input_bivector} ) != 6 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_bivector is not of length 6, croaking');
    }
    if ( ( scalar @{$input_vector} ) != 4 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_vector is not of length 4, croaking');
    }

    my number_arrayref $return_value_vector = [];

    #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__bivector_vector_minkowski(), top of subroutine...\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__bivector_vector_minkowski(), received \$input_bivector\n" . Dumper($input_bivector) . "\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__bivector_vector_minkowski(), received \$input_vector\n" . Dumper($input_vector) . "\n");

    $return_value_vector->[0] = ( $input_bivector->[0] * $input_vector->[1] ) + ( $input_bivector->[1] * $input_vector->[2] ) + ( $input_bivector->[2] * $input_vector->[3] );
    $return_value_vector->[1] = ( $input_bivector->[0] * $input_vector->[0] ) + ( $input_bivector->[3] * $input_vector->[2] ) + ( $input_bivector->[4] * $input_vector->[3] );
    $return_value_vector->[2] = ( $input_bivector->[1] * $input_vector->[0] ) - ( $input_bivector->[3] * $input_vector->[1] ) - ( $input_bivector->[5] * $input_vector->[3] );
    $return_value_vector->[3] = ( $input_bivector->[2] * $input_vector->[0] ) - ( $input_bivector->[4] * $input_vector->[1] ) - ( $input_bivector->[5] * $input_vector->[2] );

   #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__bivector_vector_minkowski(), returning \$return_value_vector\n" . Dumper($return_value_vector) . "\n");
    return $return_value_vector;
};

our number $inner_product__bivector_bivector_minkowski = sub {
    ( my number_arrayref $input_bivector_1, my number_arrayref $input_bivector_2 ) = @_;

    # bound checking
    if ( ( scalar @{$input_bivector_1} ) != 6 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_bivector_1 is not of length 6, croaking');
    }
    if ( ( scalar @{$input_bivector_2} ) != 6 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_bivector_2 is not of length 6, croaking');
    }

    #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__bivector_bivector_minkowski(), top of subroutine...\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__bivector_bivector_minkowski(), received \$input_bivector_1\n" . Dumper($input_bivector_1) . "\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__bivector_bivector_minkowski(), received \$input_bivector_2\n" . Dumper($input_bivector_2) . "\n");

    my number $return_value_number
        = ( $input_bivector_1->[0] * $input_bivector_2->[0] ) + ( $input_bivector_1->[1] * $input_bivector_2->[1] ) + ( $input_bivector_1->[2] * $input_bivector_2->[2] ) 
            - ( ( $input_bivector_1->[3] * $input_bivector_2->[3] ) + ( $input_bivector_1->[4] * $input_bivector_2->[4] ) + ( $input_bivector_1->[5] * $input_bivector_2->[5] ) );

#    RPerl::diag("in PERLOPS_PERLTYPES inner_product__bivector_bivector_minkowski(), have \$return_value_number = $return_value_number\n");

    return $return_value_number;
};

# [[[ MINKOWSKI MIDDLE PRODUCT ]]]
# [[[ MINKOWSKI MIDDLE PRODUCT ]]]
# [[[ MINKOWSKI MIDDLE PRODUCT ]]]

our number_arrayref $middle_product__bivector_bivector_minkowski = sub {
    ( my number_arrayref $input_bivector_1, my number_arrayref $input_bivector_2) = @_;

    # bound checking
    if ( ( scalar @{$input_bivector_1} ) != 6 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_bivector_1 is not of length 6, croaking');
    }
    if ( ( scalar @{$input_bivector_2} ) != 6 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_bivector_2 is not of length 6, croaking');
    }

    my number_arrayref $return_value_bivector = [];

    #    RPerl::diag("in PERLOPS_PERLTYPES middle_product__bivector_bivector_minkowski(), top of subroutine...\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES middle_product__bivector_bivector_minkowski(), received \$input_bivector_1\n" . Dumper($input_bivector_1) . "\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES middle_product__bivector_bivector_minkowski(), received \$input_bivector_2\n" . Dumper($input_bivector_2) . "\n");

    $return_value_bivector->[0] = ( $input_bivector_1->[4] * $input_bivector_2->[2] ) - ( $input_bivector_1->[2] * $input_bivector_2->[4] ) + ( $input_bivector_1->[3] * $input_bivector_2->[1] ) - ( $input_bivector_1->[1] * $input_bivector_2->[3] );
    $return_value_bivector->[1] = ( $input_bivector_1->[0] * $input_bivector_2->[3] ) - ( $input_bivector_1->[3] * $input_bivector_2->[0] ) + ( $input_bivector_1->[5] * $input_bivector_2->[2] ) - ( $input_bivector_1->[2] * $input_bivector_2->[5] );
    $return_value_bivector->[2] = ( $input_bivector_1->[0] * $input_bivector_2->[4] ) - ( $input_bivector_1->[4] * $input_bivector_2->[0] ) + ( $input_bivector_1->[1] * $input_bivector_2->[5] ) - ( $input_bivector_1->[5] * $input_bivector_2->[1] );
    $return_value_bivector->[3] = ( $input_bivector_1->[0] * $input_bivector_2->[1] ) - ( $input_bivector_1->[1] * $input_bivector_2->[0] ) + ( $input_bivector_1->[4] * $input_bivector_2->[5] ) - ( $input_bivector_1->[5] * $input_bivector_2->[4] );
    $return_value_bivector->[4] = ( $input_bivector_1->[0] * $input_bivector_2->[2] ) - ( $input_bivector_1->[2] * $input_bivector_2->[0] ) + ( $input_bivector_1->[3] * $input_bivector_2->[5] ) - ( $input_bivector_1->[5] * $input_bivector_2->[3] );
    $return_value_bivector->[5] = ( $input_bivector_1->[1] * $input_bivector_2->[2] ) - ( $input_bivector_1->[2] * $input_bivector_2->[1] ) + ( $input_bivector_1->[4] * $input_bivector_2->[3] ) - ( $input_bivector_1->[3] * $input_bivector_2->[4] );

   #    RPerl::diag("in PERLOPS_PERLTYPES middle_product__bivector_bivector_minkowski(), returning \$return_value_bivector\n" . Dumper($return_value_bivector) . "\n");
    return $return_value_bivector;
};

# [[[ MINKOWSKI OUTER PRODUCTS ]]]
# [[[ MINKOWSKI OUTER PRODUCTS ]]]
# [[[ MINKOWSKI OUTER PRODUCTS ]]]

our number_arrayref $outer_product__vector_vector_minkowski = sub {
    ( my number_arrayref $input_vector_1, my number_arrayref $input_vector_2) = @_;

    # bound checking
    if ( ( scalar @{$input_vector_1} ) != 4 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_vector_1 is not of length 4, croaking');
    }
    if ( ( scalar @{$input_vector_2} ) != 4 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_vector_2 is not of length 4, croaking');
    }

    my number_arrayref $return_value_bivector = [];

    #    RPerl::diag("in PERLOPS_PERLTYPES outer_product__vector_vector_minkowski(), top of subroutine...\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES outer_product__vector_vector_minkowski(), received \$input_vector_1\n" . Dumper($input_vector_1) . "\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES outer_product__vector_vector_minkowski(), received \$input_vector_2\n" . Dumper($input_vector_2) . "\n");

    $return_value_bivector->[0] = ( $input_vector_1->[0] * $input_vector_2->[1] ) - ( $input_vector_1->[1] * $input_vector_2->[0] );
    $return_value_bivector->[1] = ( $input_vector_1->[0] * $input_vector_2->[2] ) - ( $input_vector_1->[2] * $input_vector_2->[0] );
    $return_value_bivector->[2] = ( $input_vector_1->[1] * $input_vector_2->[2] ) - ( $input_vector_1->[2] * $input_vector_2->[1] );
    $return_value_bivector->[3] = ( $input_vector_1->[1] * $input_vector_2->[3] ) - ( $input_vector_1->[3] * $input_vector_2->[1] );
    $return_value_bivector->[4] = ( $input_vector_1->[2] * $input_vector_2->[3] ) - ( $input_vector_1->[3] * $input_vector_2->[2] );
    $return_value_bivector->[5] = ( $input_vector_1->[3] * $input_vector_2->[0] ) - ( $input_vector_1->[0] * $input_vector_2->[3] );

 #    RPerl::diag("in PERLOPS_PERLTYPES outer_product__vector_vector_minkowski(), returning \$return_value_bivector\n" . Dumper($return_value_bivector) . "\n");
    return $return_value_bivector;
};

our number_arrayref $outer_product__vector_bivector_minkowski = sub {
    ( my number_arrayref $input_vector, my number_arrayref $input_bivector) = @_;

    # bound checking
    if ( ( scalar @{$input_vector} ) != 4 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_vector is not of length 4, croaking');
    }
    if ( ( scalar @{$input_bivector} ) != 6 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_bivector is not of length 6, croaking');
    }

    my number_arrayref $return_value_trivector = [];

    #    RPerl::diag("in PERLOPS_PERLTYPES outer_product__vector_bivector_minkowski(), top of subroutine...\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES outer_product__vector_bivector_minkowski(), received \$input_vector\n" . Dumper($input_vector) . "\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES outer_product__vector_bivector_minkowski(), received \$input_bivector\n" . Dumper($input_bivector) . "\n");

    $return_value_trivector->[0] = ($input_vector->[0] * $input_bivector->[3]) - ($input_vector->[1] * $input_bivector->[1]) + ($input_vector->[2] * $input_bivector->[0]);
    $return_value_trivector->[1] = ($input_vector->[0] * $input_bivector->[4]) - ($input_vector->[1] * $input_bivector->[2]) + ($input_vector->[3] * $input_bivector->[0]);
    $return_value_trivector->[2] = ($input_vector->[0] * $input_bivector->[5]) - ($input_vector->[2] * $input_bivector->[2]) + ($input_vector->[3] * $input_bivector->[1]);
    $return_value_trivector->[3] = ($input_vector->[1] * $input_bivector->[5]) - ($input_vector->[2] * $input_bivector->[4]) + ($input_vector->[3] * $input_bivector->[3]);

#    RPerl::diag("in PERLOPS_PERLTYPES outer_product__vector_bivector_minkowski(), returning \$return_value_trivector\n" . Dumper($return_value_trivector) . "\n");
    return $return_value_trivector;
};

our number $outer_product__bivector_vector_minkowski = sub {
    ( my number_arrayref $input_bivector, my number_arrayref $input_vector) = @_;

    # bound checking
    if ( ( scalar @{$input_bivector} ) != 6 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_bivector is not of length 6, croaking');
    }
    if ( ( scalar @{$input_vector} ) != 4 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_vector is not of length 4, croaking');
    }

    my number $return_value_trivector;

    #    RPerl::diag("in PERLOPS_PERLTYPES outer_product__bivector_vector_minkowski(), top of subroutine...\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES outer_product__bivector_vector_minkowski(), received \$input_bivector\n" . Dumper($input_bivector) . "\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES outer_product__bivector_vector_minkowski(), received \$input_vector\n" . Dumper($input_vector) . "\n");

    $return_value_trivector->[0] = ( $input_bivector->[0] * $input_vector->[2] ) - ( $input_bivector->[1] * $input_vector->[1] ) + ( $input_bivector->[3] * $input_vector->[0] );
    $return_value_trivector->[1] = ( $input_bivector->[0] * $input_vector->[3] ) - ( $input_bivector->[2] * $input_vector->[1] ) + ( $input_bivector->[4] * $input_vector->[0] );
    $return_value_trivector->[2] = ( $input_bivector->[1] * $input_vector->[3] ) + ( $input_bivector->[2] * $input_vector->[2] ) + ( $input_bivector->[5] * $input_vector->[0] );
    $return_value_trivector->[3] = ( $input_bivector->[3] * $input_vector->[3] ) - ( $input_bivector->[4] * $input_vector->[2] ) + ( $input_bivector->[5] * $input_vector->[1] );

    #    RPerl::diag("in PERLOPS_PERLTYPES outer_product__bivector_vector_minkowski(), have \$return_value_trivector = $return_value_trivector\n");
    return $return_value_trivector;
};

our number_arrayref $outer_product__bivector_bivector_minkowski = sub {
    ( my number_arrayref $input_bivector_1, my number_arrayref $input_bivector_2) = @_;

    # bound checking
    if ( ( scalar @{$input_bivector_1} ) != 6 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_bivector_1 is not of length 6, croaking');
    }
    if ( ( scalar @{$input_bivector_2} ) != 6 ) {
        croak('ERROR EAVRV10, BOUND-CHECKING MISMATCH: Argument $input_bivector_2 is not of length 6, croaking');
    }

    my number $return_value_quadvector;

    #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__bivector_vector_minkowski(), top of subroutine...\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__bivector_vector_minkowski(), received \$input_bivector_1\n" . Dumper($input_bivector_1) . "\n");
    #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__bivector_vector_minkowski(), received \$input_bivector_2\n" . Dumper($input_bivector_2) . "\n");

    $return_value_quadvector = ( $input_bivector_1->[0] * $input_bivector_2->[5] ) - ( $input_bivector_1->[2] * $input_bivector_2->[4] ) + ( $input_bivector_1->[2] * $input_bivector_2->[3] ) + ( $input_bivector_1->[3] * $input_bivector_2->[2] ) - ( $input_bivector_1->[4] * $input_bivector_2->[1] ) + ( $input_bivector_1->[5] * $input_bivector_2->[0] );

   #    RPerl::diag("in PERLOPS_PERLTYPES inner_product__bivector_vector_minkowski(), returning \$return_value_quadvector\n" . Dumper($return_value_quadvector) . "\n");
    return $return_value_quadvector;
};

1;    # end of class
