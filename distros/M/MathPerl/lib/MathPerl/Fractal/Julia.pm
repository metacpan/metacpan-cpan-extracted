# [[[ HEADER ]]]
use RPerl;

package MathPerl::Fractal::Julia;
use strict;
use warnings;
our $VERSION = 0.003_000;

# [[[ OO INHERITANCE ]]]
use parent qw(MathPerl::Fractal);
use MathPerl::Fractal;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(ProhibitConstantPragma ProhibitMagicNumbers)  # USER DEFAULT 3: allow constants

# [[[ CONSTANTS ]]]
use constant X_SCALE_MIN => my number $TYPED_X_SCALE_MIN = -2.5;
use constant X_SCALE_MAX => my number $TYPED_X_SCALE_MAX = 1.0;
use constant Y_SCALE_MIN => my number $TYPED_Y_SCALE_MIN = -1.0;
use constant Y_SCALE_MAX => my number $TYPED_Y_SCALE_MAX = 1.0;

# [[[ OO PROPERTIES ]]]
our hashref $properties = {};

# [[[ OO METHODS & SUBROUTINES ]]]

# OO interface wrapper
our integer_arrayref_arrayref::method $escape_time = sub {
    (   my MathPerl::Fractal::Julia $self,
        my number $real_c,
        my number $imaginary_c,
        my integer $x_pixel_count,
        my integer $y_pixel_count,
        my integer $iterations_max,
        my number $x_min,
        my number $x_max,
        my number $y_min,
        my number $y_max,
        my boolean $color_invert
    ) = @_;
    return julia_escape_time( $real_c, $imaginary_c, $x_pixel_count, $y_pixel_count, $iterations_max, $x_min, $x_max, $y_min, $y_max, $color_invert );
};


# procedural interface
our integer_arrayref_arrayref $julia_escape_time = sub {
    (   my number $real_c,
        my number $imaginary_c,
        my integer $x_pixel_count,
        my integer $y_pixel_count,
        my integer $iterations_max,
        my number $x_min,
        my number $x_max,
        my number $y_min,
        my number $y_max,
        my boolean $color_invert
    ) = @_;

#    print 'GENERATE JULIA' . "\n";

    my integer_arrayref_arrayref $julia_set = integer_arrayref_arrayref::new( $y_pixel_count, $x_pixel_count );    # row-major form (RMF)
    my number $color_scaling_factor = 255 / $iterations_max;
    my number $zoom           = (MathPerl::Fractal::Julia::X_SCALE_MAX() - MathPerl::Fractal::Julia::X_SCALE_MIN()) / ($x_max - $x_min);
    my integer $x_pixel_count_half = $x_pixel_count * 0.5;
    my integer $y_pixel_count_half = $y_pixel_count * 0.5;
    my number $x_pixel_count_half_zoom = $x_pixel_count_half * $zoom;
    my number $y_pixel_count_half_zoom = $y_pixel_count_half * $zoom;
    my number $x_offset = (0.5 * ($x_min - MathPerl::Fractal::Julia::X_SCALE_MIN())) - (0.5 * (MathPerl::Fractal::Julia::X_SCALE_MAX() - $x_max));
    my number $y_offset = (0.5 * ($y_min - MathPerl::Fractal::Julia::Y_SCALE_MIN())) - (0.5 * (MathPerl::Fractal::Julia::Y_SCALE_MAX() - $y_max));

    for my integer $y_pixel ( 0 .. ( $y_pixel_count - 1 ) ) {                                                      # row-major form (RMF)
        for my integer $x_pixel ( 0 .. ( $x_pixel_count - 1 ) ) {
            my number $real =       ( ( 1.5 * ( $x_pixel - $x_pixel_count_half ) ) / $x_pixel_count_half_zoom ) + $x_offset;
            my number $imaginary =  (         ( $y_pixel - $y_pixel_count_half )   / $y_pixel_count_half_zoom ) + $y_offset;

            my integer $i = 0;
            while ( ( ( ( $real * $real ) + ( $imaginary * $imaginary ) ) < 4 ) and ( $i < $iterations_max ) ) {
                my number $real_tmp = ( $real * $real ) - ( $imaginary * $imaginary ) + $real_c;
                $imaginary = ( 2 * $real * $imaginary ) + $imaginary_c;
                $real      = $real_tmp;
                $i++;
            }
            if ($color_invert) {
                $julia_set->[$y_pixel]->[$x_pixel] = number_to_integer( 255 - ( $i * $color_scaling_factor ) ); # scale to become color, invert for white background
            }
            else {
                $julia_set->[$y_pixel]->[$x_pixel] = number_to_integer( $i * $color_scaling_factor );           # scale to become color, black background
            }
        }
    }
    return $julia_set;
};

1;                                                                                                              # end of class
