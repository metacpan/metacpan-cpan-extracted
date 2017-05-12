# [[[ HEADER ]]]
use RPerl;
package MathPerl::Color::RGB;
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ OO INHERITANCE ]]]
use parent qw(MathPerl::Color);
use MathPerl::Color;

# [[[ INCLUDES ]]]
use MathPerl::Color::HSV;

# [[[ OO PROPERTIES ]]]
our hashref $properties = {
    red   => my number $TYPED_red   = undef,
    green => my number $TYPED_green = undef,
    blue  => my number $TYPED_blue  = undef,
};

# [[[ OO METHODS & SUBROUTINES ]]]

our MathPerl::Color::HSV $rgb_to_hsv = sub {
    ( my MathPerl::Color::RGB $rgb) = @_;
    return $rgb->to_hsv();
};

# OO interface wrapper
our MathPerl::Color::HSV::method $to_hsv = sub {
    ( my MathPerl::Color::RGB $self) = @_;
    return rgb_raw_to_hsv( [ $self->{red}, $self->{green}, $self->{blue} ] );
};

# procedural interface wrapper
our MathPerl::Color::HSV $rgb_raw_to_hsv = sub {
    ( my number_arrayref $rgb_raw) = @_;
    my MathPerl::Color::HSV $retval = MathPerl::Color::HSV->new();
    my number_arrayref $retval_raw  = rgb_raw_to_hsv_raw($rgb_raw);
    $retval->{hue}   = $retval_raw->[0];
    $retval->{saturation} = $retval_raw->[1];
    $retval->{value}  = $retval_raw->[2];
    return;
};

our number_arrayref $rgb_raw_to_hsv_raw = sub {
    ( my number_arrayref $rgb_raw) = @_;
    my number_arrayref $retval;

# START HERE: complete algorithm
# START HERE: complete algorithm
# START HERE: complete algorithm

    return $retval;
};

1;                         # end of class
