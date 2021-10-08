package Geo::GoogleEarth::Pluggable::Contrib::MultiPolygon;
use base qw{Geo::GoogleEarth::Pluggable::Placemark};
use XML::LibXML::LazyBuilder qw{E};
use warnings;
use strict;

our $VERSION='0.17';

=head1 NAME

Geo::GoogleEarth::Pluggable::Contrib::MultiPolygon - Geo::GoogleEarth::Pluggable MultiPolygon Object

=head1 SYNOPSIS

  use Geo::GoogleEarth::Pluggable;
  my $document=Geo::GoogleEarth::Pluggable->new();
  $document->MultiPolygon();

=head1 DESCRIPTION

Geo::GoogleEarth::Pluggable::Contrib::MultiPolygon is a L<Geo::GoogleEarth::Pluggable::Placemark>.

=head1 USAGE

#Note: lon, lat, alt like GeoJSON.

  my $placemark=$document->MultiPolygon(
                                   name        => "MultiPolygon Name",
                                   coordinates => [
                                                    [ #outerBoundaryIs
                                                      [lon, lat ,alt],
                                                      [lon, lat ,alt],
                                                      [lon, lat ,alt],
                                                      ...
                                                    ],
                                                    [ #innerBoundaryIs
                                                      [lon, lat ,alt],
                                                      [lon, lat ,alt],
                                                      [lon, lat ,alt],
                                                    ]
                                                  ],
                                  );

=head1 CONSTRUCTOR

  my $placemark=$document->MultiPolygon();

=head1 METHODS

=head2 subnode

=cut

sub subnode {
  my $self = shift;
  my %data = %$self;
  $data{"tessellate"} = 1 unless defined $data{"tessellate"};
  my $multipolygon    = $data{"coordinates"} or die("Error: MultiPolygon coordinates required");
  die("Error: MultiPolygon coordinates must be an array reference") unless ref($multipolygon) eq "ARRAY";
  my @elements        = ();
  foreach my $polygon (@$multipolygon) {
    die("Error: MultiPolygon coordinates polygon must be an array reference") unless ref($polygon) eq "ARRAY";
    my @polygon_element = (E(tessellate=>{}, $data{"tessellate"}));
    my $first           = 1;
    foreach my $boundary (@$polygon) {
      die("Error: MultiPolygon coordinates polygon first boundary (outerBoundaryIs) must be an array reference") unless ref($boundary) eq "ARRAY";
      my $string = $self->coordinates_stringify($boundary);
      push @polygon_element, E(($first ? "outerBoundaryIs" : "innerBoundaryIs"), {}, E(LinearRing=>{}, E(coordinates=>{}, $string)));
      $first     = 0;
    }
    push @elements, E(Polygon => {}, @polygon_element);
  }
  return E(MultiGeometry=>{}, @elements);
}

=head1 BUGS

Please log on RT and send to the geo-perl email list.

=head1 SUPPORT

Try geo-perl email list.

=head1 AUTHOR

  Michael R. Davis (mrdvt92)
  CPAN ID: MRDVT

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<Geo::GoogleEarth::Pluggable>, L<XML::LibXML::LazyBuilder>, L<Geo::GoogleEarth::Pluggable::Placemark>

=cut

1;
