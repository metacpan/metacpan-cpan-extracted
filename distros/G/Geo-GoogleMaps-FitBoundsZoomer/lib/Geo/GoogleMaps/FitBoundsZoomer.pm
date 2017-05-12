package Geo::GoogleMaps::FitBoundsZoomer;

use 5.10.0;

use strict;
use warnings;

our $VERSION = '1.03';

use Carp;
use List::Util qw(min max);

use constant ZOOM_LIMIT    => 20;
use constant PI => 3.141592653589793;

sub new {
    my ($class, %params) = @_;

    my $points      = delete $params{points};
    my $map_width   = delete $params{width};
    my $map_height  = delete $params{height};
    my $zoom_limit  = delete $params{zoom_limit} // ZOOM_LIMIT;
    
    bless {
        points      => $points,
        width       => $map_width,
        height      => $map_height,
        zoom_limit  => $zoom_limit
    }, $class;
}

# returns max zoom for a min bounding box
sub max_bounding_zoom {
    my $self = shift;

    if ( @_ || ! defined $self->{max_bounding_zoom} ) {

        if ( @_ ) {
            my %params = @_;

            undef $self->{map_center};
            my @all_params = ('points', 'width', 'height', 'zoom_limit');
            $self->{$_} = delete $params{$_} // $self->{$_} for @all_params;

        }
    
        foreach ('points', 'width', 'height') {
            croak "No map $_ parameter! Usage: max_bounding_zoom( points => \$points, width => \$map_width, height => \$map_height )" 
                                                                                                                    unless defined $self->{$_};
        }
        
        croak "At least one point must be provided!"        unless @{$self->{points}}   > 0;
        croak "Map width must be a positive number!"        unless $self->{width}       > 0;
        croak "Map height must be a positive number!"       unless $self->{height}      > 0;
        croak "Zoom limit must be greater of equal to 0!"   unless $self->{zoom_limit}  >= 0;
        
        $self->{bounds} = $self->_get_bounds();
        $self->{max_bounding_zoom} = $self->_zoom_level( $self->{bounds} ); 
        
    }

    croak "Insufficient data to calculate maximum zoom! Usage: max_bounding_zoom( points => \$points, width => \$map_width, height => \$map_height )"
                unless defined $self->{max_bounding_zoom};

    return $self->{max_bounding_zoom};
}

# returns center of the rectangular bounding box
sub bounding_box_center {
    my $self = shift;
        
    croak "Map data not initialized! max_bounding_zoom needs to be called first. Usage: max_bounding_zoom( points => \$points, width => \$map_width, height => \$map_height )" 
                if !$self->{points} || !$self->{bounds};

    if ( ! $self->{map_center} ) {
        my $center;
        my $bounds = $self->{bounds};

        my ($blp, $trp) = ($bounds->{blp}, $bounds->{trp});

        $center->{lat}  = ( ($trp->{lat}  - $blp->{lat})  / 2 ) + $blp->{lat};
        $center->{long} = ( ($trp->{long} - $blp->{long}) / 2 ) + $blp->{long};

        $self->{map_center} = $center;
    }

    return $self->{map_center};
}

# returns a bounding box (bottom left and top right point) for coordinates
sub _get_bounds {
    my $self = shift;

    my $blp = { 'lat' =>  90, 'long' =>  180 }; # bottom left point
    my $trp = { 'lat' => -90, 'long' => -180 }; # top right point
    
    my $points = $self->{points} 
                    or croak "Cannot calculate map bounds without points!";

    foreach my $point (@$points) {
        
        my ($lat, $lng) = ($point->{lat}, $point->{long});
         
        $blp->{'lat'}    = min ($blp->{'lat'}, $lat);
        $trp->{'lat'}    = max ($trp->{'lat'}, $lat);
        $blp->{'long'}   = min ($blp->{'long'}, $lng);
        $trp->{'long'}   = max ($trp->{'long'}, $lng);
    }
    
    croak "Point latitude out of bounds ( < -90 or > 90 )"       unless ( -90  <= $blp->{'lat'}  && $blp->{'lat'}  <= 90 ); 
    croak "Point latitude out of bounds ( < -90 or > 90 )"       unless ( -90  <= $trp->{'lat'}  && $trp->{'lat'}  <= 90 );
    croak "Point longitude out of bounds ( < -180 or > 180 )"    unless ( -180 <= $blp->{'long'} && $blp->{'long'} <= 180 );
    croak "Point longitude out of bounds ( < -180 or > 180 )"    unless ( -180 <= $trp->{'long'} && $trp->{'long'} <= 180 );

    return { 'blp' => $blp, 'trp' => $trp };
}

# returns max bounding zoom level given a set of points, map width and height
sub _zoom_level {
	my ($self, $bounds) = @_;

    croak "Map bounds not set!" if !$bounds;

    my ($width, $height) = ($self->{width}, $self->{height});
    
    croak "Map width not set!"   unless defined $width;
    croak "Map height not set!"  unless defined $height;
    
    my $zoom_limit = $self->{zoom_limit};    

    my ($blp, $trp) = ($bounds->{blp}, $bounds->{trp});
    
	foreach my $zoom_level (reverse (0 .. $zoom_limit)) {
		my $blpxl = $self->_coord2pix($blp->{lat}, $blp->{long}, $zoom_level);
		my $trpxl = $self->_coord2pix($trp->{lat}, $trp->{long}, $zoom_level);
		
		$blpxl->{x} -= (2**($zoom_level + 8)) if ( $blpxl->{x} > $trpxl->{x} );
		my $delta={ x => abs($trpxl->{x} - $blpxl->{x}), y => abs($trpxl->{y} - $blpxl->{y}) };
        return $zoom_level if ( ($delta->{x} <= $width) && ($delta->{y} <= $height) );
	}
	return 0;
}

# returns an X,Y pixel cordinate from $lat, $lng coordinates for a given zoom level
sub _coord2pix {
	#values hash is the output of google_magic™ for a given zoom level
	my ($self, $lat, $lng, $zoom ) = @_;
    
    croak "Latitude not set!"    unless defined $lat;
    croak "Longitude not set!"   unless defined $lng;
    croak "Zoom not set!"        unless defined $zoom;

    my $center_point = 2**($zoom + 7);
    my $total_pixels = $center_point*2;
    my $pixels_per_lng_degree = $total_pixels / 360;
    my $pixels_per_lng_radian = $total_pixels / (2 * PI);
    my $siny = min ( max( sin( $lat*(PI/180) ), -0.99999999 ), 0.99999999 );

    my $coord;
    $coord->{x} = $center_point + $lng * $pixels_per_lng_degree;
    $coord->{y} = $center_point - 0.5 * log((1+$siny)/(1-$siny)) * $pixels_per_lng_radian;
    
    return $coord;
}

1; # end of Geo::GoogleMaps::FitBoundsZoomer

__END__

=head1 NAME

Geo::GoogleMaps::FitBoundsZoomer

=head1 SYNOPSIS

  use Geo::GoogleMaps::FitBoundsZoomer;

 
  my $zoomer = Geo::GoogleMaps::FitBoundsZoomer::->new();

  my @map_points =  
      ( 
          {'lat' => 43.72,   'long' => -79.42},
          {'lat' => 44.13,   'long' => -79.60},
          {'lat' => 43.87,   'long' => -79.07},
          {'lat' => 43.86,   'long' => -79.72},
          {'lat' => 44.12,   'long' => -79.17},
      );

  my $map_height_pixels = 380;
  my $map_width_pixels  = 400;


  my $zoom = $zoomer->max_bounding_zoom( points => \@map_points,
                                         height => $map_height_pixels,
                                         width  => $map_width_pixels );

  my $center = $zoomer->bounding_box_center();

=head1 DESCRIPTION

Geo::GoogleMaps::FitBoundsZoomer calculates the maximum Google Maps zoom which 
fits the minimum bounding rectangle of Google Map points.

It can also return the center coordinates for the bounding rectangle.

=cut

=head1 METHODS

=over 4

=item new

  $zoomer = Geo::GoogleMaps::FitBoundsZoomer->new();
  $zoomer = Geo::GoogleMaps::FitBoundsZoomer->new(points => [ { lat => 43.71, long => -79.38 },
                                                              { lat => 44.82, long => -78.42 } ]);

  $zoomer = Geo::GoogleMaps::FitBoundsZoomer->new(width  => 380);
  $zoomer = Geo::GoogleMaps::FitBoundsZoomer->new(height => 400);
  $zoomer = Geo::GoogleMaps::FitBoundsZoomer->new(zoom_limit => 18);

Creating a new zoomer object:

When creating a new zoomer object, you may optionally wish to initialize 
it with one or more parameters. The following are required parameters as
they are needed in order to calculate the maximum zoom:

I<points> is an array ref of one or more points, each of which is a hash ref 
to a points' lat and long.

I<width> is the width of the map's viewport in pixels. 

I<height> is the height of the map's viewport in pixels. 

I<zoom_limit> is an optional parameter which redefines the maximum allowable 
zoom level. Default is 20.

=item max_bounding_zoom

  $zoom = $zoomer->max_bounding_zoom();

Returns the maximum Google Maps zoom level for a set of points and a given
rectangular viewport geometry. These parameters can be specified
when creating a L</"new"> zoomer object, or passed directly to this
method.

=item bounding_box_center

  $center = $zoomer->bounding_box_center();

Returns the center coordinates for the bounding box.

I<Caveat>: Can only be called following a call to L</"max_bounding_zoom">.

Returned data structure is similar to the following:

  { lat => 43.71, long => -79.38 }

=back

=head1 CONTRIBUTORS

Big thanks to Alex Timoshenko.

=head1 AUTHOR

Copyright 2012, Michael Portnoy E<lt>mport@cpan.orgE<gt>. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<https://developers.google.com/maps>

=cut
