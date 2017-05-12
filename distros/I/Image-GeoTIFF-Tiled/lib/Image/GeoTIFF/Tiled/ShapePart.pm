package Image::GeoTIFF::Tiled::ShapePart;
use strict;
use warnings;
use Carp;

use vars qw/ $VERSION /;
$VERSION = '0.08';

# Parts are lines (start != end) or horizontal vertexes (start = end)

sub new {
    my ( $class, @p ) = @_;
    my $self = {};
    bless( $self, $class );
    my ( $start, $end );

    if ( ref $p[ 0 ] and ref $p[ 0 ] eq 'ARRAY' and @p == 1 ) {
        confess "2-element array required during constructor."
            unless @{ $p[ 0 ] } == 2;
        $start = $p[ 0 ]->[ 0 ];
        $end   = $p[ 0 ]->[ 1 ];
    }
    elsif ( @p == 2 ) {
        $start = $p[ 0 ];
        $end   = $p[ 1 ];
    }
    else {
        confess "Invalid constructor arguments: @p";
    }

    $self->start( $start );
    $self->end( $end );
    croak "Shape part needs a start and end point."
        unless defined $self->start and defined $self->end;

    $self;
}

sub str {
    my $self = shift;
    my ( $start, $end ) = sort { $a->[ 1 ] <=> $b->[ 1 ] } $self->start,
        $self->end;
    # my ( $p0, $p1 ) = sort { $a->[ 1 ] <=> $b->[ 1 ] } $self->{ _points }[ 0 ],
        # $self->{ _points }[ -1 ];
    my @pts = @{$self->{_points}};
    my ( $u, $l ) = ( $self->upper, $self->lower );
    join( "\n",
        sprintf( "Between:   (%.2f,%.2f) and (%.2f,%.2f)", @$start, @$end ),
        join("\n\t", "Points:", 
            map sprintf( "$_: (%.2f,%.2f)",
                        @{$pts[$_]} ), 0..@pts-1
            ),
        # sprintf( "Upper-Lower: (%.2f,%.2f) and (%.2f,%.2f)", @$u,     @$l ) );
        );
}

sub _point {
    my ( $self, $key, $point ) = @_;
    return $self->{ $key } unless defined $point;
    confess "Point must be 2-element arrayref"
        unless ref $point
            and ref $point eq 'ARRAY'
            and scalar @{ $point } == 2;
    carp "WARNING: Resetting $key value of part" if defined $self->{ $key };
    confess "Point values must be defined"
        if grep { not defined $_ } @{ $point };
#    confess "Point contains negative values" if grep { $_ < 0 } @$point;
    # Set the start/end point
    $self->{ $key } = $point;

    my ( $start, $end ) = ( $self->{ start }, $self->{ end } );
    if ( defined $start and defined $end ) {
        # Ensure _upper at a lower latitude
        if ( $start->[ 1 ] > $end->[ 1 ] ) {
            $self->{ _upper } = $end;
            $self->{ _lower } = $start;
        }
        else {
            $self->{ _upper } = $start;
            $self->{ _lower } = $end;
        }
      # Reset and re-interpolate points if starting and ending point are now set
        $self->_reset_points;
    }
}
sub start { shift->_point( 'start', @_ ); }
sub end   { shift->_point( 'end',   @_ ); }
sub upper { return $_[ 0 ]->{ _upper } }
sub lower { return $_[ 0 ]->{ _lower } }

sub _reset_points {
    my ( $self ) = @_;
    my ( $x0, $y0, $x1, $y1 ) =
        ( @{ $self->{ _upper } }[ 0 .. 1 ], @{ $self->{ _lower } }[ 0 .. 1 ] );

    $self->{ _points } = [];

    return if $y0 == $y1;

    # Interpolate interemediate latitudes (given y, solve for x):
    #   - interpolate the middle of the pixel
    my $y0_ =
        $y0 - int( $y0 ) <=
        0.5                # If in the lower half of the first pixel (inclusive)
        ? int( $y0 ) + 0.5 # start interpolating the middle of that pixel
        : int( $y0 ) + 1.5 # start interpolating the middle of the next pixel
        ;
    my $y1_ =
        $y1 - int( $y1 ) <
        0.5                # If in the lower half of the last pixel (exclusive)
        ? int( $y1 ) -
        0.5    # end interpolation in the middle of the previous pixel
        : int( $y1 ) + 0.5    # end interpolating in the middle of that pixel
        ;

    #   x = x0 + (y - y0) * [ (x1 - x0)/(y1 - y0) ]
    my $factor = ( $x1 - $x0 ) / ( $y1 - $y0 );
    my $i = 0;
    for ( my $y = $y0_; $y <= $y1_; $y++ ) {
        $self->{ _points }[ $i++ ] = [ $x0 + ( $y - $y0 ) * $factor, $y ];
    }
    $self->{ _y0_ } = $y0_;
} ## end sub _reset_points

sub get_point {
    # Get the [ x, y ] value of this part, given the integer y (latitude)
    my ( $self, $y ) = @_;
    confess "Require a y-value (latitude) to retrieve points" unless defined $y;
    return unless defined $self->{ _y0_ };
    my $i = int( $y ) + 0.5 - $self->{ _y0_ };
    # my $i = int( $y ) - 0.5 - $self->{ _y0_ };
    if ( $i < 0 ) {
        # carp "Latitude $y smaller than first point: ", $self->{ _y0_ };
        return;
    }
    $self->{ _points }[ $i ];
}

sub get_x {
    my ( $self, $y ) = @_;
    my $p = $self->get_point( $y );
    return unless defined $p;
    # printf "Point: (%.2f,%.2f)\n",$p->[0],$p->[1];
    return $p->[ 0 ];
}

#================================================================================================#
# POD
1;

=head1 NAME

Image::GeoTIFF::Tiled::ShapePart

=head1 DESCRIPTION

This class is used by L<Image::GeoTIFF::Tiled::Shape> to represent a single "part" of a shape (a line between two points), shapes being made up of multiple parts.

Whenever the start or end points are set, the linear interpolation along integer y-values are calculated and stored. Interpolation is done at the middle of the pixel latitude.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new($start,$end)

Starting and ending points are required during construction. Points are 2D array references [ $x, $y ].

=back

=head2 ACCESSORS

=over

=item start

Returns, optionally sets, the starting point. Setting causes the intermediate points between the ending point to be re-interpolated and therefore shouldn't be done.

=item end

Returns, optionally sets, the ending point. Setting causes the intermediate points between the starting point to be re-interpolated and therefore shouldn't be done.

=item upper

Returns the start or end point, whichever has the smaller latitude.

=item lower

Returns the start or end point, whichever has the larger latitude.

=item str

Returns a string representation of the object (debugging only).

=back

=head2 GET POINTS

=over

=item get_point($y)

Returns the [ $x, $y ] interpolated point located at (integer) pixel latitude $y, or C<undef> if there's no point along the given $y.

=item get_x($y)

Returns just the $x value of C<get_point>, or C<undef> if there's no point along the given $y.

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010 Blake Willmarth.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back

=cut
