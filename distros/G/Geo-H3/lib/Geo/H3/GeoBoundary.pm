package Geo::H3::GeoBoundary;
use strict;
use warnings;
use base qw{Geo::H3::Base}; #provides new and ffi

our $VERSION = '0.06';
our $PACKAGE = __PACKAGE__;

=head1 NAME

Geo::H3::GeoBoundary - H3 Geospatial Hexagon Indexing System GeoBoundary Object

=head1 SYNOPSIS

  use Geo::H3::GeoBoundary;
  my $gb = Geo::H3::GeoBoundary->new(gb=>$gb); #isa Geo::H3::GeoBoundary
  my $gb = Geo::H3::GeoBoundary->new(gb=>$gb, ffi=>$ffi); #isa Geo::H3::GeoBoundary

=head1 DESCRIPTION

H3 Geospatial Hexagon Indexing System GeoBoundary Object provides coordinates method to extract data from the FFI GeoBoundary object

=head1 CONSTRUCTORS

=head2 new

  my $geo = Geo::H3::GeoBoundary->new(gb=>$gb);

=head1 PROPERTIES

=head2 gb

Returns the H3 GeoBoundary Object from the API as a L<Geo::H3::FFI::Struct::GeoBoundary> object

=cut

sub gb {shift->{'gb'}};

=head1 METHODS

=head2 coordinates

Returns an OGC compatible closed polygon as an array reference of hashes i.e. [{lat=>$lat, lon=>$lon}, ...].

This coordinates format plugs directly into the format required for many L<Geo::GoogleEarth::Pluggable> objects.

=cut

sub coordinates {
  my $self        = shift;
  my @coordinates = ();
  my $gb          = $self->gb or die;
  my $max         = $gb->num_verts - 1;
  foreach my $index (0 .. $max, 0) {
    my $vert = $gb->verts->[$index];
    my $lat  = $self->ffi->radsToDegs($vert->lat);
    my $lon  = $self->ffi->radsToDegs($vert->lon);
    push @coordinates, {lat=>$lat, lon=>$lon};
  }
  return \@coordinates;
}

=head1 SEE ALSO

L<Geo::H3>, L<Geo::H3::FFI::Struct::GeoBoundary>, L<Geo::GoogleEarth::Pluggable>

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2021 Michael R. Davis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;
