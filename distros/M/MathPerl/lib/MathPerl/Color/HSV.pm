# [[[ HEADER ]]]
use RPerl;

package MathPerl::Color::HSV;
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ OO INHERITANCE ]]]
use parent qw(MathPerl::Color);
use MathPerl::Color;

# [[[ INCLUDES ]]]
use MathPerl::Color::RGB;

# [[[ OO PROPERTIES ]]]
our hashref $properties = {
    hue        => my number $TYPED_hue        = undef,
    saturation => my number $TYPED_saturation = undef,
    value      => my number $TYPED_value      = undef,
};

# [[[ OO METHODS & SUBROUTINES ]]]

our MathPerl::Color::RGB $hsv_to_rgb = sub {
    ( my MathPerl::Color::HSV $hsv) = @_;
    return $hsv->to_rgb();
};

# OO interface wrapper
our MathPerl::Color::RGB::method $to_rgb = sub {
    ( my MathPerl::Color::HSV $self) = @_;
    return hsv_raw_to_rgb( [ $self->{hue}, $self->{saturation}, $self->{value} ] );
};

# procedural interface wrapper
our MathPerl::Color::RGB $hsv_raw_to_rgb = sub {
    ( my number_arrayref $hsv_raw) = @_;
    my MathPerl::Color::RGB $retval = MathPerl::Color::RGB->new();
    my number_arrayref $retval_raw  = hsv_raw_to_rgb_raw($hsv_raw);
    $retval->{red}   = $retval_raw->[0];
    $retval->{green} = $retval_raw->[1];
    $retval->{blue}  = $retval_raw->[2];
    return;
};

our number_arrayref $hsv_raw_to_rgb_raw = sub {
    ( my number_arrayref $hsv_raw) = @_;
    my number_arrayref $retval;

    # START HERE: implement >> operators in RPerl
    # START HERE: implement >> operators in RPerl
    # START HERE: implement >> operators in RPerl

    my unsigned_integer $region;
    my unsigned_integer $remainder;
    my unsigned_integer $p;
    my unsigned_integer $q;
    my unsigned_integer $t;

    if ( $hsv_raw->[1] == 0 ) {
        $retval->[0] = $hsv_raw->[2];
        $retval->[1] = $hsv_raw->[2];
        $retval->[2] = $hsv_raw->[2];
        return $retval;
    }

    $region = $hsv_raw->[0] / 43;
    $remainder = ( $hsv_raw->[0] - ( $region * 43 ) ) * 6;

    $p = ( $hsv_raw->[2] * ( 255 - $hsv_raw->[1] ) ) >> 8;
    $q = ( $hsv_raw->[2] * ( 255 - ( ( $hsv_raw->[1] * $remainder ) >> 8 ) ) ) >> 8;
    $t = ( $hsv_raw->[2] * ( 255 - ( ( $hsv_raw->[1] * ( 255 - $remainder ) ) >> 8 ) ) ) >> 8;

    if ( $region == 0 ) {
        $retval->[0] = $hsv_raw->[2];
        $retval->[1] = $t;
        $retval->[2] = $p;
    }
    elsif ( $region == 1 ) {
        $retval->[0] = $q;
        $retval->[1] = $hsv_raw->[2];
        $retval->[2] = $p;
    }
    elsif ( $region == 2 ) {
        $retval->[0] = $p;
        $retval->[1] = $hsv_raw->[2];
        $retval->[2] = $t;
    }
    elsif ( $region == 3 ) {
        $retval->[0] = $p;
        $retval->[1] = $q;
        $retval->[2] = $hsv_raw->[2];
    }
    elsif ( $region == 4 ) {
        $retval->[0] = $t;
        $retval->[1] = $p;
        $retval->[2] = $hsv_raw->[2];
    }
    else {
        $retval->[0] = $hsv_raw->[2];
        $retval->[1] = $p;
        $retval->[2] = $q;
    }

    return $retval;
};

1;    # end of class
