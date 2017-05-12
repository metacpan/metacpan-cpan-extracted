package Geometry::Formula;

use strict;
use warnings;
use Carp qw(croak);
my $PI = 3.1415926;

our $VERSION = 0.02;

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    return $self;
}

sub annulus {
    my ( $self, %param, $x ) = @_;
    _param_check( 'annulus', %param );

    $x = $PI *
      ( $self->_squared( $param{'outer_radius'} ) - $self->_squared( $param{'inner_radius'} ) );

    return $x;
}

sub circle {
    my ( $self, %param, $x ) = @_;
    _param_check( 'circle', %param );

    if ( $param{'formula'} eq 'area' ) {
        $x = $PI * $self->_squared( $param{'radius'} );
    }
    elsif ( $param{'formula'} eq 'circumference' ) {
        $x = ( 2 * $PI ) * $param{'radius'};
    }
    else {
        $x = $param{'radius'} * 2;
    }

    return $x;
}

sub cone {
    my ( $self, %param, $x ) = @_;
    _param_check( 'cone', %param );

    $x = ( 1 / 3 ) * ( $param{'base'} * $param{'height'} );

    return $x;
}

sub cube {
    my ( $self, %param, $x ) = @_;
    _param_check( 'cube', %param );

    if ( $param{'formula'} eq 'surface_area' ) {
        $x = 6 * ( $param{'a'} * 2 );
    }
    else {
        $x = $self->_cubed( $param{'a'} );
    }

    return $x;
}

sub ellipse {
    my ( $self, %param, $x ) = @_;
    _param_check( 'ellipse', %param );

    if ( $param{'formula'} eq 'area' ) {
        $x = $PI * ( $param{'a'} * $param{'b'} );
    }
    else {
        $x = 2 * $PI *
          sqrt( ( $self->_squared( $param{'a'} ) + $self->_squared( $param{'b'} ) ) / 2 );
    }

    return $x;
}

sub ellipsoid {
    my ( $self, %param, $x ) = @_;
    _param_check( 'ellipsoid', %param );

    $x = ( 4 / 3 ) * $PI * $param{'a'} * $param{'b'} * $param{'c'};

    return $x;
}

sub equilateral_triangle {
    my ( $self, %param, $x ) = @_;
    _param_check( 'equilateral_triangle', %param );

    $x = $self->_squared( $param{'side'} ) * ( sqrt(3) / 4 );

    return $x;
}

sub frustum_of_right_circular_cone {
    my ( $self, %param, $x ) = @_;
    _param_check( 'frustum_of_right_circular_cone', %param );

    if ( $param{'formula'} eq 'lateral_surface_area' ) {
        $x =
          $PI *
          ( $param{'large_radius'} + $param{'small_radius'} ) *
          sqrt( $self->_squared( $param{'large_radius'} - $param{'small_radius'} ) +
              $self->_squared( $param{'slant_height'} ) );
    }
    elsif ( $param{'formula'} eq 'total_surface_area' ) {
        my $slant_height =
          sqrt( $self->_squared( $param{'large_radius'} - $param{'small_radius'} ) +
              $self->_squared( $param{'height'} ) );

        $x =
          $PI *
          ( $param{'small_radius'} *
              ( $param{'small_radius'} + $slant_height )
              + $param{'large_radius'} *
              ( $param{'large_radius'} + $slant_height ) );

    }
    else {
        $x = (
            $PI * (
                $self->_squared( $param{'small_radius'} ) +
                  ( $param{'small_radius'} * $param{'large_radius'} ) +
                  $self->_squared( $param{'large_radius'} )
              ) * $param{'height'}
        ) / 3;
    }

    return $x;
}

sub parallelogram {
    my ( $self, %param, $x ) = @_;
    _param_check( 'parallelogram', %param );

    if ( $param{'formula'} eq 'area' ) {
        $x = $param{'base'} * $param{'height'};
    }
    else {
        $x = ( 2 * $param{'a'} ) + ( 2 * $param{'b'} );
    }

    return $x;
}

sub rectangle {
    my ( $self, %param, $x ) = @_;
    _param_check( 'rectangle', %param );

    if ( $param{'formula'} eq 'area' ) {
        $x = $param{'length'} * $param{'width'};
    }
    else {
        $x = ( 2 * $param{'length'} ) + ( 2 * $param{'width'} );
    }

    return $x;
}

sub rectangular_solid {
    my ( $self, %param, $x ) = @_;
    _param_check( 'rectangular_solid', %param );

    if ( $param{'formula'} eq 'volume' ) {
        $x = $param{'length'} * $param{'width'} * $param{'height'};
    }
    else {
        $x =
          2 *
          ( ( $param{'length'} * $param{'width'} ) +
              ( $param{'width'} * $param{'height'} ) +
              ( $param{'length'} * $param{'height'} ) );
    }

    return $x;
}

sub rhombus {
    my ( $self, %param, $x ) = @_;
    _param_check( 'rhombus', %param );

    $x = ( $param{'a'} * $param{'b'} ) / 2;

    return $x;
}

sub right_circular_cone {
    my ( $self, %param, $x ) = @_;
    _param_check( 'right_circular_cone', %param );

    if ( $param{'formula'} eq 'lateral_surface_area' ) {
        $x =
          $PI *
          $param{'radius'} *
          ( sqrt( $self->_squared( $param{'radius'} ) + $self->_squared( $param{'height'} ) ) );
    }
    else {
        $x = ( 1 / 3 ) * $PI * $self->_squared( $param{'radius'} ) * $param{'height'};
    }

    return $x;
}

sub right_circular_cylinder {
    my ( $self, %param, $x ) = @_;
    _param_check( 'right_circular_cylinder', %param );

    if ( $param{'formula'} eq 'lateral_surface_area' ) {
        $x = 2 * $PI * $param{'radius'} * $param{'height'};
    }
    elsif ( $param{'formula'} eq 'total_surface_area' ) {
        $x =
          2 * $PI * $param{'radius'} * ( $param{'radius'} + $param{'height'} );
    }
    else {
        $x = $PI * ( $self->_squared( $param{'radius'} ) * $param{'height'} );
    }

    return $x;
}

sub sector_of_circle {
    my ( $self, %param, $x ) = @_;
    _param_check( 'sector_of_circle', %param );

    $x = ( $param{'theta'} / 360 ) * $PI * $self->_squared( $param{'radius'} );

    return $x;
}

sub sphere {
    my ( $self, %param, $x ) = @_;
    _param_check( 'sphere', %param );

    if ( $param{'formula'} eq 'surface_area' ) {
        $x = 4 * $PI * $self->_squared( $param{'radius'} );
    }
    else {
        $x = ( 4 / 3 ) * $PI * $self->_cubed( $param{'radius'} );
    }

    return $x;
}

sub square {
    my ( $self, %param, $x ) = @_;
    _param_check( 'square', %param );

    if ( $param{'formula'} eq 'area' ) {
        $x = $self->_squared( $param{'side'} );
    }
    else {
        $x = $param{'side'} * 4;
    }

    return $x;
}

sub torus {
    my ( $self, %param, $x ) = @_;
    _param_check( 'torus', %param );

    if ( $param{'formula'} eq 'surface_area' ) {
        $x = 4 * $self->_squared($PI) * $param{'a'} * $param{'b'};
    }
    else {
        $x = 2 * $self->_squared($PI) * $self->_squared( $param{'a'} ) * $param{'b'};
    }

    return $x;
}

sub trapezoid {
    my ( $self, %param, $x ) = @_;
    _param_check( 'trapezoid', %param );

    if ( $param{'formula'} eq 'area' ) {
        $x = ( ( $param{'a'} + $param{'b'} ) / 2 ) * $param{'height'};
    }
    else {
        $x = $param{'a'} + $param{'b'} + $param{'c'} + $param{'d'};
    }

    return $x;
}

sub triangle {
    my ( $self, %param, $x ) = @_;
    _param_check( 'triangle', %param );

    if ( $param{'formula'} eq 'area' ) {
        $x = .5 * $param{'base'} * $param{'height'};
    }
    else {
        $x = $param{'a'} + $param{'b'} + $param{'c'};
    }

    return $x;
}

sub _squared {
    my ( $self, $num ) = @_;

    return $num ** 2;
}

sub _cubed {
    my ( $self, $num ) = @_;

    return $num ** 3;
}

sub _param_check {
    my ( $method, %param ) = @_;

    my %valid_params = (
        annulus => { area => [ 'inner_radius', 'outer_radius' ] },
        circle  => {
            area          => ['radius'],
            circumference => ['radius'],
            diameter      => ['radius']
        },
        cone => { volume => [ 'base', 'height' ] },
        cube => {
            surface_area => ['a'],
            volume       => ['a']
        },
        ellipse => {
            area      => [ 'a', 'b' ],
            perimeter => [ 'a', 'b' ]
        },
        ellipsoid                      => { volume => [ 'a', 'b', 'c' ] },
        equilateral_triangle           => { area   => ['side'] },
        frustum_of_right_circular_cone => {
            lateral_surface_area =>
              [ 'slant_height', 'small_radius', 'large_radius' ],
            total_surface_area => [ 'height', 'small_radius', 'large_radius' ],
            volume             => [ 'height', 'small_radius', 'large_radius' ]
        },
        parallelogram => {
            area      => [ 'base', 'height' ],
            perimeter => [ 'a',    'b' ]
        },
        rectangle => {
            area      => [ 'length', 'width' ],
            perimeter => [ 'length', 'width' ]
        },
        rectangular_solid => {
            surface_area => [ 'length', 'width', 'height' ],
            volume       => [ 'length', 'width', 'height' ]
        },
        rhombus             => { area => [ 'a', 'b' ] },
        right_circular_cone => {
            lateral_surface_area => [ 'radius', 'height' ],
            volume               => [ 'radius', 'height' ]
        },
        right_circular_cylinder => {
            total_surface_area   => [ 'radius', 'height' ],
            lateral_surface_area => [ 'radius', 'height' ],
            volume               => [ 'radius', 'height' ]
        },
        sector_of_circle => { area => [ 'theta', 'radius' ] },
        sphere           => {
            surface_area => ['radius'],
            volume       => ['radius']
        },
        square => {
            area      => ['side'],
            perimeter => ['side']
        },
        torus => {
            surface_area => [ 'a', 'b' ],
            volume       => [ 'a', 'b' ]
        },
        trapezoid => {
            area      => [ 'a', 'b', 'height' ],
            perimeter => [ 'a', 'b', 'c', 'd' ]
        },
        triangle => {
            area      => [ 'base', 'height' ],
            perimeter => [ 'a',    'b', 'c' ]
        },
    );

    # validate that parameter values are defined and numeric
    foreach ( @{ $valid_params{$method}{ $param{'formula'} } } ) {
        croak "required parameter '$_' not defined"
          if !$param{$_};

        croak "parameter '$_' requires a numeric value"
          if $param{$_} !~ m/^\d+$/;
    }

    # validate parameter is a valid constructor/component of formula
    foreach my $param ( keys %param ) {
        next if $param eq 'formula';

        my @constructors = @{ $valid_params{$method}{ $param{'formula'} } };

        if ( !@constructors ) {
            croak "invalid formula name: $param{'formula'} specified";
        }

        if ( grep { $_ eq $param } @constructors ) {
            next;
        }
        else {
            croak "invalid parameter '$param' specified for $method";
        }
    }

    return 0;
}

1;

__END__

=pod

=head1 NAME

Geometry::Formula - methods to calculate common geometry formulas.

=head1 VERSION

    Version 0.01

=head1 SYNOPSIS

    use Geometry::Formula

    my $x = Geometry::Formula->new;

=head1 DESCRIPTION

This package provides users with the ability to calculate simple geometric
problems using the most common geometry formulas. This module was primarily
written for education and practical purposes.  

=head1 CONSTRUCTOR

=over

=item C<< new() >>

Returns a reference to a new formula object. No arguments currently needed
or required.

=back

=head1 SUBROUTINES/METHODS

The following methods are used to calculate our geometry formulas. Keep in
mind each formula has a unique set of constructors/parameters that are used
and must be provided accordingly. All attempts have been made to prevent a
user from providing invalid data to the method.

Methods are named after the 2d and 3d shapes one would expect to find while
using geometric formulas such as square or cube. Please see the individual
method items for the specific parameters one must use. In the example below
you can see how we make usage of Geometry::Formula:

    use Geometry::Formula;

    my $x   = Geometry::Formula->new;
    my $sqr = $x->square{ formula => 'area', side => 5 };

    print $sqr;
    ---
    25

=over

=item C<< annulus() >>

The annulus method provides an area formula. 

required: inner_radius, outer_radius

    $x->annulus{
        formula      => 'area',
        inner_radius => int,
        outer_radius => int
    };

Note: the inner_radius cannot be larger then the outer_radius.

=item C<< circle() >>

The circle method provides an area, circumference, and diameter formula.

required: radius

    $x->circle(
        formula => 'area',
        radius  => int
    );

    $x->circle(
        formula => 'circumference',
        radius  => int
    );

    $x->circle(
        formula => 'diameter',
        radius  => int
    );

=item C<< cone() >>

The cone method provides a volume formula.

required: base, height

    $x->cone(
        formula => 'volume',
        base    => int,
        height  => int
    );

=item C<< cube() >>

The cube method provides a surface area and volume formula.

required: a

    $x->cube(
        formula => 'surface_area',
        a       => int
    );

    $x->cube(
        formula => 'volume',
        a       => int
    );

=item C<< ellipse() >>

The ellipse method provides an area and perimeter formula.

required: a, b

    $x->ellipse(
        formula => 'area',
        a       => int,
        b       => int
    );

    $x->ellipse(
        formula => 'perimeter',
        a       => int,
        b       => int
    );

Note: a and b represent radii

=item C<< ellipsoid() >>

The ellipsoid method provides a volume formula.

required: a, b, c

    x->ellipsoid(
        formula => 'volume',
        a       => int,
        b       => int,
        c       => int,
    );

Note: a, b, and c represent radii

=item C<< equilateral_triangle() >>

The equalateral_triangle method provides an area formula.

required: side

    x->equilateral_triangle(
        formula => 'area',
        side    => int,
    );

=item C<< frustum_of_right_circular_cone() >>

The frustum_of_right_circular_cone method provides a lateral_surface_area,
total_surface_area, and volume formula.

required: slant_height, large_radius, small_radius

    x->frustum_of_right_circular_cone(
        formula      => 'lateral_surface_area',
        slant_height => int,
        large_radius => int,
        small_radius => int
    );

required: height, large_radius, small_radius

    x->frustum_of_right_circular_cone(
        formula      => 'total_surface_area',
        height       => int,
        large_radius => int,
        small_radius => int

    );

    x->frustum_of_right_circular_cone(
        formula      => 'volume',
        height       => int,
        large_radius => int,
        small_radius => int
    );

=item C<< parallelogram() >>

The parallelogram method provides an area and perimeter formula.

required: base, height

    x->parallelgram(
        formula => 'area',
        base    => int,
        height  => int
    );

required: a, b

    x->parallelgram(
        formula => 'perimeter',
        a       => int,
        b       => int
    );

Note: a and b are sides

=item C<< rectangle() >>

The rectangle method provides an area and perimeter formula.

required: length, width

    x->rectangle(
        formula => 'area',
        length  => int,
        width   => int
    );

    x->rectangle(
        formula => 'perimeter',
        length  => int,
        width   => int
    );

=item C<< rectangular_solid() >>

The rectangular_solid method provides an and perimeter formula.

required: length, width, height

    x->rectangular_solid(
        formula => 'surface_area',
        length  => int,
        width   => int,
        height  => int
    );

    x->rectangular_solid(
        formula => 'volume',
        length  => int,
        width   => int,
        height  => int
    );

=item C<< rhombus() >>

The rhombus method provides an area formula.

required: a, b

    x->rhombus(
        formula => 'area',
        a       => int,
        b       => int
    );

Note: a and b represent diagonal lines (sides)

=item C<< right_circular_cone() >>

The right_circular_cone method provides a lateral surface area formula.

required: height, radius

    $x->right_circular_cone(
        formula => 'lateral_surface_area', 
        height  => int,
        radius  => int
    );

=item C<< right_circular_cylinder() >>

The right_circular_cylinder method provides a side surface area,
total surface area, and volume formula. 

required: height, radius

    $x->right_circular_cylinder(
        formula => 'lateral_surface_area', 
        height  => int,
        radius  => int
    );

    $x->right_circular_cylinder(
        formula => 'total_surface_area', 
        height  => int,
        radius  => int
    );

    $x->right_circular_cylinder(
        formula => 'volume', 
        height  => int,
        radius  => int
    );

=item C<< sector_of_circle() >>

The sector_of_circle method provides an area formula.

required: theta

    $x->sector_of_circle(
        formula => 'area', 
        theta   => int
    );

Note: theta value should not be greater then 360 (degrees).

=item C<< sphere() >>

The sphere method provides a surface area and volume formula.

required: radius

    $x->sphere(
        formula => 'surface_area', 
        radius  => int
    );

    $x->sphere(
        formula => 'volume', 
        radius  => int
    );

=item C<< square() >>

The square method provides an area and perimeter formula.

required: side

    $x->square(
        formula => 'area', 
        side    => int
    );

    $x->square(
        formula => 'perimeter', 
        side    => int
    );

=item C<< torus() >>

The torus method provides a surface area and volume formula.

    $x->torus(
        formula => 'surface_area', 
        a       => int,
        b       => int
    );

    $x->torus(
        formula => 'volume', 
        a  => int,
        b  => int
    );

Note: a and b represent radii

=item C<< trapezoid() >>

The trapezoid method provides an area and perimeter formula.

required: a, b, and height

    $x->trapezoid(
        formula => 'area', 
        a       => int,
        b       => int,
        height  => int
    );

required a, b, c, and d

    $x->trapezoid(
        formula => 'perimeter', 
        a       => int,
        b       => int,
        c       => int,
        d       => int
    );

=item C<< triangle() >>

The triangle method provides an area and perimeter formula.

    $x->triangle(
        formula => 'area', 
        base    => int,
        height  => int
    );

    $x->triangle(
        formula => 'perimeter', 
        a  => int,
        b  => int,
        c  => int
    );

=back 

=head1 HELPER SUBROUTINES/METHODS

While documented typically you will not call these methods directly. These
methods are provided for readability and parameter validation.

=over

=item C<< $self->_squared( int ) >>

numeric values passed to this function get $self->_squared and returned. 

=item C<<$self->_cubed( int ) >>

numeric values passed to this fucntion get$self->_cubed and returned

=item C<< _param_check( $name_of_method, %param ) >> 

this method validates the parameters being passed into our formula methods
are properly constructed. 

=back

=head1 DIAGNOSTICS 

N/A at the current point in time

=head1 CONFIGURATION AND ENVIRONMENT

This package has only been tested in a 64bit Unix (OSX) environment however
it does not make usage of any code or modules considered OS specific and no
special configuration or configuration files are needed. 

=head1 INCOMPATIBILITIES

This package is intended to be compatible with Perl 5.008 and beyond.

=head1 BUGS AND LIMITATIONS

The package cannot prevent users from specifying duplicate keys within a
method. When validating parameters the first error that is caught will be
reported even in the event that additional errors exist. The methods
provided were not intended to handle very large numbers.

=head1 DEPENDENCIES

No modules outside of the perl core/base install. 

=head1 SEE ALSO

B<Carp>

=head1 SUPPORT

The module is provided free of support however feel free to contact the
author or current maintainer with questions, bug reports, and patches.

Consideration will be taken when making changes to the API. Any changes to
its interface will go through at the least one deprecation cycle.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 Casey W. Vega.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but without
any warranty; without even the implied warranty of merchantability or
fitness for a particular purpose.

=head1 Author

Casey Vega <cvega@cpan.org>

=cut 
