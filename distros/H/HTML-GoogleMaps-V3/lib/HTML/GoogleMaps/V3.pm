package HTML::GoogleMaps::V3;

=head1 NAME

HTML::GoogleMaps::V3 - a simple wrapper around the Google Maps API

=for html
<a href='https://travis-ci.org/Humanstate/html-googlemaps-v3?branch=master'><img src='https://travis-ci.org/Humanstate/html-googlemaps-v3.svg?branch=master' alt='Build Status' /></a>
<a href='https://coveralls.io/r/Humanstate/html-googlemaps-v3?branch=master'><img src='https://coveralls.io/repos/Humanstate/html-googlemaps-v3/badge.png?branch=master' alt='Coverage Status' /></a>

=head1 VERSION

0.14

=head1 SYNOPSIS

  use HTML::GoogleMaps::V3

  $map = HTML::GoogleMaps::V3->new;
  $map->center("1810 Melrose St, Madison, WI");
  $map->add_marker(point => "1210 W Dayton St, Madison, WI");
  $map->add_marker(point => [ 51, 0 ] );   # Greenwich

  my ($head, $map_div) = $map->onload_render;

=head1 NOTE

This module is forked from L<HTML::GoogleMaps> and updated to use V3 of
the API. Note that the module isn't quite a drop in replacement, although
it should be trivial to update your code to use it.

Note that V3 of the API does not require an API key, however you can pass
one and it will be used (useful for analytics).

Also note that this library only implements a subset of the functionality
available in the maps API, if you want more then raise an issue or create
a pull request.

=head1 DESCRIPTION

HTML::GoogleMaps::V3 provides a simple wrapper around the Google Maps
API. It allows you to easily create maps with markers, polylines and
information windows. Thanks to Geo::Coder::Google you can now look
up locations around the world without having to install a local database.

=head1 CONSTRUCTOR

=over 4

=item $map = HTML::GoogleMaps::V3->new;

Creates a new HTML::GoogleMaps::V3 object. Takes a hash of options.
Valid options are:

=over 4

=item api_key => key (your Google Maps API key)

=item height => height (in pixels or using your own unit)

=item width => width (in pixels or using your own unit)

=item z_index => place on z-axis (e.g. -1 to ensure scrolling works)

=item geocoder => an object such as Geo::Coder::Google

=back

=back

=cut

use strict;
use warnings;

use Template;

our $VERSION = '0.14';

sub new {
    my ( $class,%opts ) = @_;

    if ( !defined($opts{geocoder} ) ) {
        require Geo::Coder::Google;
        Geo::Coder::Google->import();

        $opts{'geocoder'} = Geo::Coder::Google->new(
            apidriver => 3,
            ( $opts{'api_key'} ? ( key => $opts{'api_key'}, sensor => 'false' ) : () ),
    );
    }

    $opts{'points'} = [];
    $opts{'poly_lines'} = [];

    return bless \%opts, $class;
}

sub _text_to_point {
    my ( $self,$point_text ) = @_;

    # IE, already a long/lat pair
    return [ reverse @$point_text ] if ref( $point_text ) eq "ARRAY";

    if ( my @loc = $self->{geocoder}->geocode( location => $point_text ) ) {
        if ( my $location = $loc[0] ) {

            if ( ref( $location ) ne 'HASH' ) {
                warn "$point_text didn't return a HASH ref as first element from ->geocode";
                return 0;
            }

            if(defined($location->{geometry}{location}{lat}) && defined($location->{geometry}{location}{lng})) {
                return [
                    $location->{geometry}{location}{lat},
                    $location->{geometry}{location}{lng},
                ];
            }
        }
    }

    # Unknown
    return 0;
}

sub _find_center {
    my ( $self ) = @_;

    # Null case
    return unless @{$self->{points}};

    my ( $total_lat,$total_lng,$total_abs_lng );

    foreach ( @{$self->{points}} ) {
        my ( $lat,$lng ) = @{ $_->{point} };
        $total_lat     += defined $lat ? $lat : 0;
        $total_lng     += defined $lng ? $lng : 0;
        $total_abs_lng += abs( defined $lng ? $lng : 0 );
    }

    # Latitude is easy, just an average
    my $center_lat = $total_lat/@{$self->{points}};

    # Longitude, on the other hand, is trickier. If points are
    # clustered around the international date line a raw average
    # would produce a center around longitude 0 instead of -180.
    my $avg_lng     = $total_lng/@{$self->{points}};
    my $avg_abs_lng = $total_abs_lng/@{$self->{points}};

    return [ $center_lat,$avg_lng ] # All points are on the
        if abs( $avg_lng ) == $avg_abs_lng; # same hemasphere

    if ( $avg_abs_lng > 90 ) { # Closer to the IDL
        if ( $avg_lng < 0 && abs( $avg_lng ) <= 90) {
            $avg_lng += 180;
        } elsif ( abs( $avg_lng ) <= 90 ) {
            $avg_lng -= 180;
        }
    }

    return [ $center_lat,$avg_lng ];
}

=head1 METHODS

=over 4

=item $map->center($point)

Center the map at a given point. Returns 1 on success, 0 if
the point could not be found.

=cut

sub center {
    my ( $self,$point_text ) = @_;

    my $point = $self->_text_to_point( $point_text )
        || return 0;

    $self->{center} = $point;
    return 1;
}

=item $map->zoom($level)

Set the new zoom level (0 is corsest)

=cut

=item $map->dragging($enable)

Enable or disable dragging.

=cut

=item $map->info_window($enable)

Enable or disable info windows.

=cut

=item $map->map_id($id)

Set the id of the map div

=cut

sub add_icon    { 1; }
sub controls    { 1; }
sub dragging    { $_[0]->{dragging}    = $_[1]; }
sub info_window { $_[0]->{info_window} = $_[1]; }
sub map_id      { $_[0]->{id}          = $_[1]; }
sub zoom        { $_[0]->{zoom}        = $_[1]; }
sub v2_zoom     { $_[0]->{zoom}        = $_[1]; }

=item $map->map_type($type)

Set the map type. Either B<normal>, B<satellite>, B<road>, or B<hybrid>.

=cut

sub map_type {
    my ( $self,$type ) = @_;

    $type = {
        normal         => 'NORMAL',
        map_type       => 'NORMAL',
        satellite_type => 'SATELLITE',
        satellite      => 'SATELLITE',
        hybrid         => 'HYBRID',
        road           => 'ROADMAP',
    }->{ $type } || return 0;

    $self->{type} = $type;
}

=item $map->add_marker(point => $point, html => $info_window_html)

Add a marker to the map at the given point. A point can be a unique
place name, like an address, or a pair of coordinates passed in as
an arrayref: [ longitude, latitude ]. Will return 0 if the point
is not found and 1 on success.

If B<html> is specified, add a popup info window as well.

=cut

sub add_marker {
    my ( $self,%opts ) = @_;

    my $point = $self->_text_to_point($opts{point})
        || return 0;

    push( @{$self->{points}}, {
        point  => $point,
        html   => $opts{html},
        format => !$opts{noformat}
    } );
}

=item $map->add_polyline(points => [ $point1, $point2 ])

Add a polyline that connects the list of points. Other options
include B<color> (any valid HTML color), B<weight> (line width in
pixels) and B<opacity> (between 0 and 1). Will return 0 if the points
are not found and 1 on success.

=cut

sub add_polyline {
    my ( $self,%opts ) = @_;

    my @points = map { $self->_text_to_point($_) } @{$opts{points}};
        return 0 if grep { !$_ } @points;

    push( @{$self->{poly_lines}}, {
        points  => \@points,
        color   => $opts{color} || "\#0000ff",
        weight  => $opts{weight} || 5,
        opacity => $opts{opacity} || .5 }
    );
}

sub _js_template {

    my $template =<<"EndOfTemplate";

function html_googlemaps_initialize() {

    myCenterLatLng = new google.maps.LatLng({lat: [% center.0 %], lng: [% center.1 %]});

    // key map controls
    var map = new google.maps.Map(document.getElementById('[% id %]'), {
        mapTypeId: google.maps.MapTypeId.[% type %],
        [% IF center %]center: myCenterLatLng,[% END %]
        scrollwheel: false,
        zoom: [% zoom %],
        draggable: [% dragging ? 'true' : 'false' %]
    });

    [% FOREACH point IN points %]

    // marker
    myMarker[% loop.count %]LatLng = new google.maps.LatLng({lat: [% point.point.0 %], lng: [% point.point.1 %]});
    var marker[% loop.count %] = new google.maps.Marker({
        map: map,
        position: myMarker[% loop.count %]LatLng,
    });

    // marker infoWindow
    [% IF info_window AND point.html %]
    var contentString[% loop.count %] = '[% point.html %]';
    var infowindow[% loop.count %] = new google.maps.InfoWindow({
        content: contentString[% loop.count %]
    });

    marker[% loop.count %].addListener('click', function() {
        infowindow[% loop.count %].open(map, marker[% loop.count %]);
    });
    [% END %]

    [% END -%]

    [% FOREACH route IN poly_lines %]

    // polylines
    var route[% loop.count %]Coordinates = [
        [% FOREACH point IN route.points %]{lat: [% point.0 %], lng: [% point.1 %]}[% loop.last ? '' : ',' %]
        [% END %]
    ];

    var route[% loop.count %] = new google.maps.Polyline({
        path: route[% loop.count %]Coordinates,
        geodesic: true,
        strokeColor: '[% route.color %]',
        strokeOpacity: [% route.opacity %],
        strokeWeight: [% route.weight %]
    });

    route[% loop.count %].setMap(map);
    [% END %]
}
EndOfTemplate
}

=item $map->onload_render

Renders the map and returns a two element list. The first element
needs to be placed in the head section of your HTML document. The
second in the body where you want the map to appear. You will also 
need to add a call to html_googlemaps_initialize() in your page's 
onload handler. The easiest way to do this is adding it to the body
tag:

    <body onload="html_googlemaps_initialize()">

=back

=cut

sub onload_render {
    my ( $self ) = @_;

    # Add in all the defaults
    $self->{id}         ||= 'map';
    $self->{height}     ||= '400px';
    $self->{width}      ||= '600px';
    $self->{type}       ||= "NORMAL";
    $self->{zoom}       ||= 13;
    $self->{center}     ||= $self->_find_center;
    $self->{dragging}     = 1 unless defined $self->{dragging};
    $self->{info_window}  = 1 unless defined $self->{info_window};

    $self->{width}  .= 'px' if $self->{width} =~ m/^\d+$/;
    $self->{height} .= 'px' if $self->{height} =~ m/^\d+$/;

    my $header = '<script src="https://maps.googleapis.com/maps/api/js__KEY__"'
        . ' async defer type="text/javascript"></script>'
    ;

    my $key = $self->{api_key}
        ? "?key=@{[ $self->{api_key} ]}" : "";

    $header =~ s/__KEY__/$key/;

    my $map = sprintf(
        '<div id="%s" style="width: %s; height: %s%s"></div>',
        @{$self}{qw/ id width height / },
        exists($self->{'z_index'})
            ? '; z-index: ' . $self->{'z_index'} : ''
    );

    my $out;
    Template->new->process( \$self->_js_template,$self,\$out );

    $header .= "<script>$out</script>";

    return ( $header,$map );
}

=head1 SEE ALSO

L<https://developers.google.com/maps/documentation/javascript/3.exp/reference>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/html-googlemaps-v3

=cut

=head1 AUTHORS

Nate Mueller <nate@cs.wisc.edu> - Original Author

Lee Johnson <leejo@cpan.org> - Maintainer of this fork

Nigel Horne - Contributor of several patches

=cut

1;

# vim: ts=4:sw=4:et
