# [[[ HEADER ]]]
use RPerl;

package MathPerl::Geometry::PiDigits;
use strict;
use warnings;
our $VERSION = 0.002_000;

# [[[ OO INHERITANCE ]]]
use parent qw(RPerl::CompileUnit::Module::Class);
use RPerl::CompileUnit::Module::Class;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(ProhibitCStyleForLoops)  # USER DEFAULT 6: allow C-style for() loop headers

# [[[ INCLUDES ]]]
use rperlgmp;

# [[[ OO PROPERTIES ]]]
our hashref $properties = {};

# [[[ OO METHODS & SUBROUTINES ]]]

our unsigned_integer $extract_digit = sub {
    ( my unsigned_integer $nth, my gmp_integer $tmp1, my gmp_integer $tmp2, my gmp_integer $acc, my gmp_integer $den, my gmp_integer $num ) = @_;
    gmp_mul_unsigned_integer( $tmp1, $num, $nth );
    gmp_add( $tmp2, $tmp1, $acc );
    gmp_div_truncate_quotient( $tmp1, $tmp2, $den );
    return gmp_get_unsigned_integer($tmp1);
};

our void $eliminate_digit = sub {
    ( my unsigned_integer $d, my gmp_integer $acc, my gmp_integer $den, my gmp_integer $num ) = @_;
    gmp_sub_mul_unsigned_integer( $acc, $den, $d );
    gmp_mul_unsigned_integer( $acc, $acc, 10 );
    gmp_mul_unsigned_integer( $num, $num, 10 );
};

our void $next_term = sub {
    ( my unsigned_integer $k, my gmp_integer $acc, my gmp_integer $den, my gmp_integer $num ) = @_;
    my unsigned_integer $k2 = $k * integer_to_unsigned_integer(2) + integer_to_unsigned_integer(1);
    gmp_add_mul_unsigned_integer( $acc, $num, integer_to_unsigned_integer(2) );
    gmp_mul_unsigned_integer( $acc, $acc, $k2 );
    gmp_mul_unsigned_integer( $den, $den, $k2 );
    gmp_mul_unsigned_integer( $num, $num, $k );
};

our void $display_pi_digits = sub {
    ( my integer $n ) = @_;
    my gmp_integer $tmp1 = gmp_integer->new();
    my gmp_integer $tmp2 = gmp_integer->new();
    my gmp_integer $acc = gmp_integer->new();
    my gmp_integer $den = gmp_integer->new();
    my gmp_integer $num = gmp_integer->new();
    my unsigned_integer $d;
    my unsigned_integer $k;

    gmp_init($tmp1);
    gmp_init($tmp2);
    gmp_init_set_unsigned_integer( $acc, 0 );
    gmp_init_set_unsigned_integer( $den, 1 );
    gmp_init_set_unsigned_integer( $num, 1 );

    $k = 0;
    MAIN_LOOP:
    for ( my unsigned_integer $i = 0; $i < $n; $i = $i ) {
        $k = $k + 1;
        next_term( $k, $acc, $den, $num );
        if ( gmp_cmp( $num, $acc ) > 0 ) { next; }

        $d = extract_digit( 3, $tmp1, $tmp2, $acc, $den, $num );
        if ( $d != extract_digit( 4, $tmp1, $tmp2, $acc, $den, $num ) ) { next; }

        print $d;
        $i = $i + 1;
        if ( ( $i % 10 ) == 0 ) { print "\t:" . integer_to_string($i) . "\n"; }
        eliminate_digit( $d, $acc, $den, $num );
    }
};

1;    # end of class
