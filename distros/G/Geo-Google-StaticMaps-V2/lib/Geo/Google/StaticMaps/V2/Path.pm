package Geo::Google::StaticMaps::V2::Path;
use warnings;
use strict;
use base qw{Geo::Google::StaticMaps::V2::Visible};
our $VERSION = '0.12';
our $PACKAGE = __PACKAGE__;

=head1 NAME

Geo::Google::StaticMaps::V2::Path - Generate Images from Google Static Maps V2 API

=head1 SYNOPSIS

  use Geo::Google::StaticMaps::V2;
  my $map=Geo::Google::StaticMaps::V2->new;
  my $path=$map->path(locations=>["Clifton, VA", "Pag, Croatia"], geodesic=>1); #isa Geo::Google::StaticMaps::V2::Path
  print $map->url, "\n";

=head1 DESCRIPTION

The packages generates images from the Google Static Maps V2 API which can be saved locally for use in accordance with your license with Google.

=head1 USAGE

=head1 PROPERTIES

=head2 encode

encode: (optional) specifies weather or not to encode path using the Google Polyline Encoding Algorithm as implemented by L<Algorithm::GooglePolylineEncoding>. The default is to not encode (value of 0).

  my $path=$map->path(encode=>1); #on construction
  $path->encode(1);               #after construction

Note: Encoding the path has the advantage of being able to specify large polylines on a limited URL length.  The disadvantages are: 1) it limits specified locations to latitude and longitude, 2) it limits coordinate accuracy to 5 decimal places and 3) the resultant URL is not human readable.

=cut

sub encode {
  my $self=shift;
  $self->{'encode'}=shift if @_;
  $self->{'encode'}=0 unless defined $self->{'encode'}; 
  return $self->{'encode'};
}

sub _styles {
  my $self=shift;
  my @styles=();
  push @styles, join ':', weight    => $self->weight                      if defined $self->weight;
  push @styles, join ':', color     => $self->color                       if defined $self->color;
  push @styles, join ':', fillcolor => $self->fillcolor                   if defined $self->fillcolor;
  push @styles, join ':', geodesic  => $self->geodesic ? 'true' : 'false' if defined $self->geodesic;
  return @styles;
}

=head2 weight

weight: (optional) specifies the thickness of the path in pixels. If no weight parameter is set, the path will appear in its default thickness (5 pixels). 

=cut

sub weight {
  my $self=shift;
  $self->{'weight'}=shift if @_;
  return $self->{'weight'};
}

=head2 color

color: (optional) specifies a color either as a 24-bit (example: color=0xFFFFCC) or 32-bit hexadecimal value (example: color=0xFFFFCCFF), or from the set {black, brown, green, purple, yellow, blue, gray, orange, red, white}.

When a 32-bit hex value is specified, the last two characters specify the 8-bit alpha transparency value. This value varies between 00 (completely transparent) and FF (completely opaque). Note that transparencies are supported in paths, though they are not supported for markers.

  my $color=$path->color("blue");
  my $color=$path->color("0xFFFFCC");
  my $color=$path->color({r=>255,g=>0,b=>0,a=>64}); #maps to red   25% returns 0xFF000040
  my $color=$path->color([0,255,0,"75%"]);          #maps to green 75% returns 0x00FF00C0

=cut

sub _color {
  my $self=shift;
  my $key=shift; #color||fillcolor
  $self->{$key}=shift if @_;
  if (ref($self->{$key})) {
    my $r;
    my $g;
    my $b;
    my $a;
    if (ref($self->{$key}) eq 'HASH') {
      $r = $self->{$key}->{'r'} || 0;
      $g = $self->{$key}->{'g'} || 0;
      $b = $self->{$key}->{'b'} || 0;
      $a = $self->{$key}->{'a'};
    } elsif (ref($self->{$key}) eq 'ARRAY') {
      $r = $self->{$key}->[0]   || 0;
      $g = $self->{$key}->[1]   || 0;
      $b = $self->{$key}->[2]   || 0;
      $a = $self->{$key}->[3];
    } else {
      die('Error: Unknown reference type expecting HASH or ARRAY.');
    }
    if (defined $a) {
      if ($a =~ m/^(100|\d\d|\d)\%$/) {
        $a=int($1/100*255);
      }
      return sprintf("0x%02X%02X%02X%02X", $r, $g, $b, $a);
    } else {
      return sprintf("0x%02X%02X%02X", $r, $g, $b);
    }
  } else {
    return $self->{$key};
  }
}

sub color {shift->_color(color=>@_)};

=head2 fillcolor

fillcolor: (optional) indicates both that the path marks off a polygonal area and specifies the fill color to use as an overlay within that area. The set of locations following need not be a "closed" loop; the Static Map server will automatically join the first and last points. Note, however, that any stroke on the exterior of the filled area will not be closed unless you specifically provide the same beginning and end location. 

=cut

sub fillcolor {shift->_color(fillcolor=>@_)};

=head2 geodesic

geodesic: (optional) indicates that the requested path should be interpreted as a geodesic line that follows the curvature of the Earth. When false, the path is rendered as a straight line in screen space. Defaults to false.

=cut

sub geodesic {
  my $self=shift;
  $self->{'geodesic'}=shift if @_;
  return $self->{'geodesic'};
}

=head1 METHODS

=head2 addLocation

  $marker->addLocation("Clifton, VA");

=cut

sub _encode_locations {
  my $self=shift;
  eval 'use Algorithm::GooglePolylineEncoding'; #run time requirment
  my $error=$@;
  die('Error: option encode was enabled but Algorithm::GooglePolylineEncoding pacakge would not load. \n$error') if $error;
  my @points=map {
                  ref($_) eq 'HASH'  ? $_                           :
                  ref($_) eq 'ARRAY' ? {lat=>$_->[0], lon=>$_->[1]} :
                  ref($_) && $_->can("lat") && $_->can("lon") ? {lat=>$_->lat, lon=>$_->lon} :
                  die('Error: Stringifacation with the encode option only supports locations as coordinate pairs in hashes, arrays or object than have lat and  lon methods')
                 } $self->locations;
  return 'enc:'. Algorithm::GooglePolylineEncoding::encode_polyline(@points); #@points=({lat=>38, lon=>-77}, ...);
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

L<Geo::Google::StaticMaps::V2>

=cut

1;
