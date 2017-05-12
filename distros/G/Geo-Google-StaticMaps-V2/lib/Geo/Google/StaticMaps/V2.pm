package Geo::Google::StaticMaps::V2;
use warnings;
use strict;
use base qw{Package::New};
use File::Basename qw{};
use Path::Class qw{file};
use URI qw{};
use LWP::UserAgent qw{};
use Geo::Google::StaticMaps::V2::Markers;
use Geo::Google::StaticMaps::V2::Path;

our $VERSION = '0.12';
our $PACKAGE = __PACKAGE__;

=head1 NAME

Geo::Google::StaticMaps::V2 - Generate Images from Google Static Maps V2 API

=head1 SYNOPSIS

  use Geo::Google::StaticMaps::V2;
  my $map=Geo::Google::StaticMaps::V2->new;
  print $map->url;
  print $map->image;
  $map->save("filename.png");

=head1 DESCRIPTION

The packages generates images from the Google Static Maps V2 API which can be saved locally for use in accordance with your license with Google.

=head1 USAGE

=head1 CONSTRUCTORS

=head2 new

  use Geo::Google::StaticMaps::V2;
  my $map=Geo::Google::StaticMaps::V2->new(
                                           width    => 600,
                                           height   => 480,
                                           sensor   => 0,
                                           scale    => 1,
                                           format   => "png8",
                                           type     => "roadmap",
                                           protocol => "http",
                                           server   => "maps.googleapis.com",
                                           script   => "/maps/api/staticmap",
                                          );

Any property can be specified on construction but all have sane defaults and are not required to be set.

=head2 marker

Creates a L<Geo::Google::StaticMaps::V2::Markers> object and adds the object to the internal Markers array.

  $map->marker(location=>"7140 Main Street, Clifton, Virginia 20124");
  $map->marker(location=>{lat=>38.780676,lon=>-77.387105});
  $map->marker(location=>[38.780676,-77.387105]);
  $map->marker(location=>"38.780676,-77.387105");

markers (optional) define one or more markers to attach to the image at specified locations. Multiple markers may be placed within the same markers parameter as long as they exhibit the same style; you may add additional markers of differing styles by adding additional markers parameters. Note that if you supply markers for a map, you do not need to specify the (normally required) center and zoom parameters.

Examples

  my $marker1=$map->marker(location=>{lat=>38.780676,lon=>-77.387105}); #isa L<Geo::Google::StaticMaps::V2::Markers>
  $marker1->addLocation([38.780513,-77.387128]);                        #second point shares style with first point

  my $marker2=$map->marker(locations=>[
                                       {lat=>38.780596,lon=>-77.386837},
                                       [38.780346,-77.386923]
                                      ]);                               #third and forth points with different style
  $marker2->size("tiny");                                               #third and forth points are now tiny
  $marker1->color("blue");                                              #first and second point are now blue

=cut

sub marker {
  my $self=shift;
  my $obj=Geo::Google::StaticMaps::V2::Markers->new(@_);
  push @{$self->_markers}, $obj;
  return $obj;
}

#head2 _markers
#
#Returns an array reference with the current list of marker objects.
#
#cut

sub _markers {
  my $self=shift;
  $self->{"_markers"}=[] unless ref($self->{"_markers"}) eq "ARRAY";
  return $self->{"_markers"};
}

=head2 path

Creates a L<Geo::Google::StaticMaps::V2::Path> object and adds the object to the internal Paths array.

path (optional) defines a single path of two or more connected points to overlay on the image at specified locations. Note that if you supply a path for a map, you do not need to specify the (normally required) center and zoom parameters.

=cut

sub path {
  my $self=shift;
  my $obj=Geo::Google::StaticMaps::V2::Path->new(@_);
  push @{$self->_paths}, $obj;
  return $obj;
}

#head2 _paths
#
#Returns an array reference with the current list of path objects.
#
#cut

sub _paths {
  my $self=shift;
  $self->{"_paths"}=[] unless ref($self->{"_paths"}) eq "ARRAY";
  return $self->{"_paths"};
}

=head2 visible

Creates a L<Geo::Google::StaticMaps::V2::Visible> object and adds the object to the internal Visibles array.

visible (optional) specifies one or more locations that should remain visible on the map, though no markers or other indicators will be displayed. Use this parameter to ensure that certain features or map locations are shown on the static map.

=cut

sub visible {
  my $self=shift;
  my $obj=Geo::Google::StaticMaps::V2::Visible->new(@_);
  push @{$self->_visibles}, $obj;
  return $obj;
}

#head2 _visibles
#
#Returns an array reference with the current list of visible objects.
#
##cut

sub _visibles {
  my $self=shift;
  $self->{"_visibles"}=[] unless ref($self->{"_visibles"}) eq "ARRAY";
  return $self->{"_visibles"};
}

=head1 PROPERTIES

=head2 center

center (required if markers not present) defines the center of the map, equidistant from all edges of the map. This parameter takes a location as either a comma-separated {latitude,longitude} pair (e.g. "40.714728,-73.998672") or a string address (e.g. "City Hall, New York, NY") identifying a unique location on the face of the earth.

=cut

sub center {
  my $self=shift;
  $self->{"center"}=shift if @_;
  return $self->{"center"};
}

=head2 zoom

zoom (required if markers not present) defines the zoom level of the map, which determines the magnification level of the map. This parameter takes a numerical value corresponding to the zoom level of the region desired.

=cut

sub zoom {
  my $self=shift;
  $self->{"zoom"}=shift if @_;
  return $self->{"zoom"};
}

=head2 width

Width part of size parameter. 

UOM: pixels

Note: width of image is actually width times scale

=cut

sub width {
  my $self=shift;
  $self->{"width"}=shift if @_;
  $self->{"width"}||=600;
  return $self->{"width"};
}

=head2 height

Height part of size parameter

UOM: pixels

Note: height of image is actually height times scale

=cut

sub height {
  my $self=shift;
  $self->{"height"}=shift if @_;
  $self->{"height"}||=400;
  return $self->{"height"};
}

=head2 sensor

Sets or returns the sensor value true or false setting is Perlish.

  $map->sensor(0);       #default
  $map->sensor("false"); #Do not do this as "false" is true to Perl

sensor (required) specifies whether the application requesting the static map is using a sensor to determine the user's location. This parameter is required for all static map requests.

=cut

sub sensor {
  my $self=shift;
  $self->{"sensor"}=shift if @_;
  $self->{"sensor"}||=0;
  return $self->{"sensor"};
}

=head2 scale

scale (optional) affects the number of pixels that are returned. scale=2 returns twice as many pixels as scale=1 while retaining the same coverage area and level of detail (i.e. the contents of the map don't change). This is useful when developing for high-resolution displays, or when generating a map for printing. The default value is 1. Accepted values are 2 and 4 (4 is only available to Maps API for Business customers.) See Scale Values for more information. 

  $map->scale; #undef (default is 1; not passed on URL), 1, 2, 4

=cut

sub scale {
  my $self=shift;
  $self->{"scale"}=shift if @_;
  return $self->{"scale"};
}

=head2 format

format (optional) defines the format of the resulting image. By default, the Static Maps API creates PNG images. There are several possible formats including GIF, JPEG and PNG types. Which format you use depends on how you intend to present the image. JPEG typically provides greater compression, while GIF and PNG provide greater detail. For more information, see Image Formats. 

  $map->format; #undef (default is png8; not passed on URL), png8, png32, gif, jpg, jpg-baseline

=cut

sub format {
  my $self=shift;
  $self->{"format"}=shift if @_;
  return $self->{"format"};
}

=head2 type

maptype (optional) defines the type of map to construct. There are several possible maptype values, including roadmap, satellite, hybrid, and terrain.

  $map->type; #undef (default is roadmap; not passed on URL), roadmap, satellite, terrain, hybrid

=cut

sub type {
  my $self=shift;
  $self->{"type"}=shift if @_;
  return $self->{"type"};
}

=head2 server

Sets or returns the Google Maps API server

  $map->server("maps.googleapis.com");  #default

=cut

sub server {
  my $self=shift;
  $self->{"server"}=shift if @_;
  $self->{"server"}="maps.googleapis.com" unless defined($self->{"server"});
  return $self->{"server"};
}

=head2 script

Sets or returns the script for the Google Maps API Static Map

  $map->script("/maps/api/staticmap");  #default

=cut

sub script {
  my $self=shift;
  $self->{"script"}=shift if @_;
  $self->{"script"}="/maps/api/staticmap" unless defined($self->{"script"});
  return $self->{"script"};
}

=head2 protocol

Sets or returns the protocol

  $map->protocol("http");  #default
  $map->protocol("https"); #https to avoid cross security domain issues in browsers but uses more resources

=cut

sub protocol {
  my $self=shift;
  $self->{"protocol"}=shift if @_;
  $self->{"protocol"}="http" unless defined($self->{"protocol"});
  return $self->{"protocol"};
}

#head2 _service
#
#Returns a cached URL with only "$protocol://$server"
#
#cut

sub _service {
  my $self=shift;
  $self->{"_service"}=shift if @_;
  unless (defined $self->{"_service"}) {
    $self->{"_service"}=URI->new;
    $self->{"_service"}->scheme($self->protocol);
    $self->{"_service"}->host($self->server);
  }
  return $self->{"_service"};
}

=head1 METHODS

=head2 image

Returns the image as a binary scalar.

  my $blob=$map->image;

See: L<LWP::UserAgent>

=cut

sub image {
  my $self=shift;
  my $response=$self->_ua->get($self->url);
  if ($response->is_success) {
    return $response->decoded_content;
  } else {
    die $response->status_line;
  }
}

#head2 _ua
#
#Returns a cached LWP::UserAgent object
#
#cut

sub _ua {
  my $self=shift;
  unless (defined $self->{"_ua"}) {
    $self->{"_ua"}=LWP::UserAgent->new;
    $self->{"_ua"}->timeout(10);
    $self->{"_ua"}->env_proxy;
  }
  return $self->{"_ua"};
}

=head2 save

Saves image to the local file system.

  $map->save("image.png");
  $map->save("image.gif");
  $map->save("image.jpg");

Note: If you have not explicitly set the format, the save method will guess the format from the extension.

=cut

sub save {
  my $self     = shift;
  my $filename = shift;
  my $suffix   = (File::Basename::fileparse($filename, keys(%{$self->_extensions})))[2];
  local $self->{"format"}=$self->_extensions->{$suffix}
    if (exists($self->_extensions->{$suffix}) && !defined($self->format));
  my $file=file($filename); #isa Path::Class::File
  my $fh=$file->openw;
  $fh->binmode; #support Win32
  print $fh $self->image;
  return $self;
}

sub _extensions {
  return {".png" => undef, ".gif" => "gif", ".jpg" => "jpg"};
}

=head2 url

Returns the URL for the Static map.  If L<URL::Signature::Google::Maps::API> is installed and configured the URL is seamlessly signed with your Google Enterprise Key.

  my $url=$map->url; #isa L<URI>

=cut

sub url {
  my $self=shift;
  my $url=URI->new($self->script); #isa URI
  my @q=();
  push @q, size    => $self->_size;  #required
  push @q, maptype => $self->type   if defined $self->type;
  push @q, scale   => $self->scale  if defined $self->scale;
  push @q, format  => $self->format  if defined $self->format;
  push @q, sensor  => $self->sensor ? "true" : "false";
  my $needs_view=1;
  foreach my $visible (@{$self->_visibles}) {
    $needs_view=0;
    push @q, visible  => $visible->stringify;
  }
  foreach my $marker (@{$self->_markers}) {
    $needs_view=0;
    push @q, markers => $marker->stringify;
  }
  foreach my $path (@{$self->_paths}) {
    $needs_view=0;
    push @q, path => $path->stringify;
  }
  if (defined $self->center) {
    push @q, center => $self->center;
  } else {
    push @q, center => "Clifton, VA" if $needs_view; #we should only get here in the trival case
  }
  if (defined $self->zoom) {
    push @q, zoom => $self->zoom;
  } else {
    push @q, zoom => "7" if $needs_view;             #we should only get here in the trival case
  }
  $url->query_form(@q);
  if ($self->_signer) {
    $url=$self->_signer->url($self->_service => $url);
  } else {
    $url->scheme($self->protocol);
    $url->host($self->server);
  }
  return $url;
}

#head2 _size
#
#size (required) defines the rectangular dimensions of the map image. This parameter takes a string of the form {horizontal_value}x{vertical_value}. For example, 500x400 defines a map 500 pixels wide by 400 pixels high. Maps smaller than 180 pixels in width will display a reduced-size Google logo. This parameter is affected by the scale parameter, described below; the final output size is the product of the size and scale values. 
#
#cut

sub _size {
  my $self=shift;
  return join("x", $self->width, $self->height);
}

#head2 _signer
#
#Returns false but defined or a cached L<> object
#
#Note: This method returns false if the URL::Signature::Google::Maps::API is not installed and thus URL signatures will not be available.
#
#cut

sub _signer {
  my $self=shift;
  $self->{"_signer"}=shift if @_;
  unless (defined $self->{"_signer"}) { #init
    eval('use URL::Signature::Google::Maps::API');
    if ($@) {
      $self->{"_signer"}="";
    } else {
      $self->{"_signer"}=URL::Signature::Google::Maps::API->new(channel=>$self->channel, client=>$self->client, key=>$self->key)
        unless defined($self->{"_signer"});
    }
  }
  return $self->{"_signer"};
}

=head1 Google Enterprise Credentials

These settings are simply passed through to L<URL::Signature::Google::Maps::API>.

I recommend storing the credentials in the INI formatted file and leaving these values as undef.

=head2 client

Sets and returns the Google Enterprise Client

=cut

sub client {
  my $self=shift;
  $self->{"client"}=shift if @_;
  return $self->{"client"};
}

=head2 key

Sets and returns the Google Enterprise Key

=cut

sub key {
  my $self=shift;
  $self->{"key"}=shift if @_;
  return $self->{"key"};
}

=head2 channel

Sets and returns the Google Enterprise channel.

=cut

sub channel {
  my $self=shift;
  $self->{"channel"}=shift if @_;
  return $self->{"channel"};
}

=head1 BUGS

Please log on RT and send an email to the author.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  Satellite Tracking of People, LLC
  mdavis@stopllc.com
  http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software licensed under the...

  The General Public License (GPL) Version 2, June 1991

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<Geo::Google::StaticMaps>, L<Geo::Google::MapObject>, L<Net::Flickr::Geo::GoogleMaps>, L<URL::Signature::Google::Maps::API>

=cut

1;
