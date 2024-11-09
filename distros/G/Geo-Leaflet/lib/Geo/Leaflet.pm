package Geo::Leaflet;
use strict;
use warnings;
use base qw{Package::New};
use Geo::Leaflet::tileLayer;
use Geo::Leaflet::marker;
use Geo::Leaflet::circle;
use Geo::Leaflet::polygon;
use CGI qw{link};

our $VERSION = '0.01';
our $PACKAGE = __PACKAGE__;

=head1 NAME

Geo::Leaflet - Generates Leaflet web page

=head1 SYNOPSIS

  use Geo::Leaflet;
  my $map = Geo::Leaflet->new;
  print $map->html;

=head1 DESCRIPTION

The package is designed to be able to build a Leaflet map similar to what L<Geo::Google::StaticMaps::V2> used to be able to provide.

=head1 CONSTRUCTORS

=head2 new

Returns a map object

  my $map = Geo::Leaflet->new(
                              id     => "map",
                              center => [$lat, $lon],
                              zoom   => 13,
                             );

=head1 MAP PROPERTIES

=head2 id

Sets and returns the html id of the map.

Default: "map"

=cut

sub id {
  my $self      = shift;
  $self->{'id'} = shift if @_;
  $self->{'id'} = 'map' unless defined $self->{'id'};
  return $self->{'id'};
}

=head2 center

Sets and returns the center of the map.

  $map->center([$lat, $lon]);
  my $center = $map->center;

Default: [38.2, -97.2]

=cut

sub center {
  my $self           = shift;
  $self->{'center'}  = shift if @_;
  $self->{'center'}  = [38.2, -97.2] unless defined $self->{'center'};
  my $error_template = "Error: $PACKAGE property center expected %s (e.g., [\$lat, \$lon])";
  die(sprintf($error_template, 'array reference')) unless ref($self->{'center'}) eq 'ARRAY';
  die(sprintf($error_template, 'two elements'   )) unless   @{$self->{'center'}} == 2;
  return $self->{'center'};
}

=head2 zoom

Sets and returns the zoom of the map.

  $map->zoom(4.5);
  my $zoom = $map->zoom;

Default: 4.5

=cut

sub zoom {
  my $self        = shift;
  $self->{'zoom'} = shift if @_;
  $self->{'zoom'} = 4.5 unless defined $self->{'zoom'};
  return $self->{'zoom'};
}

=head2 setView

Sets the center and zoom of the map and returns the map object (i.e., matches leaflet.js interface).

  $map->setView([51.505, -0.09], 13);

=cut

sub setView {
  my $self   = shift;
  my $center = shift;
  my $zoom   = shift;
  $self->center($center) if defined $center;
  $self->zoom($zoom)     if defined $zoom;
  return $self;
}

=head2 width

Sets and returns the pixel width of the map.

  $map->width(600);
  my $width = $map->width;

Default: 600

=cut

sub width {
  my $self         = shift;
  $self->{'width'} = shift if @_;
  $self->{'width'} = 600 unless defined $self->{'width'};
  return $self->{'width'};
}

=head2 height

Sets and returns the pixel height of the map.

  $map->height(600);
  my $height = $map->height;

Default: 400

=cut

sub height {
  my $self          = shift;
  $self->{'height'} = shift if @_;
  $self->{'height'} = 400 unless defined $self->{'height'};
  return $self->{'height'};
}

=head1 HTML PROPERTIES

=head2 title

Sets and returns the HTML title.

Default: "Leaflet Map"

=cut

sub title {
  my $self         = shift;
  $self->{'title'} = shift if @_;
  $self->{'title'} = 'Leaflet Map' unless defined $self->{'title'};
  return $self->{'title'};
}

=head2 objects

=cut

sub objects {
  my $self           = shift;
  $self->{'objects'} = [] unless ref($self->{'objects'}) eq 'ARRAY';
  return $self->{'objects'};
}

=head1 OBJECT CONSTRUCTORS

=head2 tileLayer

Creates and returns a tileLayer object which is added to the map.

  $map->tileLayer(
                  url         => 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  maxZoom     => 19,
                  attribution => '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
                 );

  Default: OpenStreetMaps

=cut

sub tileLayer {
  my $self             = shift;
  $self->{'tileLayer'} = Geo::Leaflet::tileLayer->new(@_) if @_;
  $self->{'tileLayer'} = Geo::Leaflet::tileLayer->osm(  ) unless defined $self->{'tileLayer'};
  return $self->{'tileLayer'};
}

=head2 marker

Adds a marker object to the map and returns a reference to the marker object.

  $map->marker(lat=>$lat, lon=>$lon);

=cut

sub marker {
  my $self    = shift;
  my $objects = $self->objects;
  my $marker  = Geo::Leaflet::marker->new(@_);
  push @{$objects}, $marker;
  return $marker;
}

=head2 circle

Adds a circle object to the map and returns a reference to the circle object.

  $map->circle(lat=>$lat, lon=>$lon, radius=>$radius, properties=>{});

=cut

sub circle {
  my $self    = shift;
  my $objects = $self->objects;
  my $circle  = Geo::Leaflet::circle->new(@_);
  push @{$objects}, $circle;
  return $circle;
}

=head2 polygon

Adds a polygon object to the map and returns a reference to the polygon object.

  my $latlngs = [[$lat, $lon], ...]
  $map->polygon(coordinates=>$latlngs, properties=>{});

=cut

sub polygon {
  my $self    = shift;
  my $objects = $self->objects;
  my $polygon = Geo::Leaflet::polygon->new(@_);
  push @{$objects}, $polygon;
  return $polygon;
}

=head1 METHODS

=head2 html

=cut

sub html {
  my $self = shift;
  my $html = $self->CGI;
  return $html->html(
           $html->head(
             $html->title($self->title),
             $self->html_head_link,
             $self->html_head_script,
             $self->html_head_style,
           ),
           $html->body(
             $self->html_body_div,
             $self->html_body_script
           ),
         ), "\n";
}

=head2 html_head_link

=cut

sub html_head_link {
  my $self = shift;
  my $html = $self->CGI;
  return $html->link({
                      rel         => 'stylesheet',
                      href        => 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css',
                      integrity   => 'sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=',
                      crossorigin => '',
                     });
}

=head2 html_head_script

=cut

sub html_head_script {
  my $self = shift;
  my $html = $self->CGI;
  return $html->script({
                        src         => 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js',
                        integrity   => 'sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=',
                        crossorigin => '',
                       }, ''); #empty script required
}

=head2 html_head_style

=cut

sub html_head_style {
  my $self       = shift;
  my $html       = $self->CGI;
  my $style_size = sprintf('width: %dpx; height: %dpx;', $self->width, $self->height);
  my $style_full = 'html, body { height: 100%; margin: 0; } '.
                   ".leaflet-container { $style_size max-width: 100%; max-height: 100%; }";
  return $html->style({}, $style_full);
}

=head2 html_body_div

=cut

sub html_body_div {
  my $self       = shift;
  my $html       = $self->CGI;
  my $style_size = sprintf('width: %dpx; height: %dpx;', $self->width, $self->height);
  return $html->div({id => $self->id, style => $style_size});
}

=head2 html_body_script

=cut

sub html_body_script {
  my $self = shift;
  my $html = $self->CGI;
  return $html->script({}, $self->html_body_script_contents);
}

=head2 html_body_script_map

=cut

sub html_body_script_map {
  my $self = shift;
  return sprintf(q{const map = L.map('%s').setView([%f, %f], %u);}, $self->id, $self->center->[0], $self->center->[1], $self->zoom);
}

=head2 html_body_script_contents

=cut

sub html_body_script_contents {
  my $self     = shift;
  my $empty    = '';
  my @commands = (
                  $empty,
                  $empty,
                  $self->html_body_script_map,
                  $self->tileLayer->stringify,
                  $empty,
                 );
  my $loop     = 0;
  foreach my $object (@{$self->objects}) {
    $loop++;
    push @commands, "const object$loop = " . $object->stringify;
  }
  push @commands, $empty;

  return join $empty, map {"    $_\n"} @commands;
}

=head1 OBJECT ACCESSORS

=head2 CGI

Returns a L<CGI> object to generate HTML.

=cut

sub CGI {
  my $self       = shift;
  $self->{'CGI'} = shift if @_;
  $self->{'CGI'} = CGI->new('') unless defined $self->{'CGI'};
  return $self->{'CGI'};
}

=head1 SEE ALSO

L<Geo::Google::StaticMaps::V2>
https://leafletjs.com/

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Michael R. Davis

MIT LICENSE

=cut

1;
