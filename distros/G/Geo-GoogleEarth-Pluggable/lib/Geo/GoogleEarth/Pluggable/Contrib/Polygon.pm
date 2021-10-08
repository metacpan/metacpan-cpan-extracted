package Geo::GoogleEarth::Pluggable::Contrib::Polygon;
use base qw{Geo::GoogleEarth::Pluggable::Placemark};
use XML::LibXML::LazyBuilder qw{E};
use warnings;
use strict;

our $VERSION='0.17';

=head1 NAME

Geo::GoogleEarth::Pluggable::Contrib::Polygon - Geo::GoogleEarth::Pluggable Polygon Object

=head1 SYNOPSIS

  use Geo::GoogleEarth::Pluggable;
  my $document=Geo::GoogleEarth::Pluggable->new();
  $document->Polygon();

=head1 DESCRIPTION

Geo::GoogleEarth::Pluggable::Contrib::Polygon is a L<Geo::GoogleEarth::Pluggable::Placemark>.

=head1 USAGE

  my $placemark=$document->Polygon(
                                   name        => "Polygon Name",
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

  my $placemark=$document->Polygon();

=head1 METHODS

=head2 subnode

=cut

sub subnode {
  my $self = shift;
  my %data = %$self;
  $data{"tessellate"} = 1 unless defined $data{"tessellate"};
  my $polygon         = $data{"coordinates"} or die("Error: Polygon coordinates required");
  die("Error: Polygon coordinates must be an array reference") unless ref($polygon) eq "ARRAY";
  my @elements        = (E(tessellate=>{}, $data{"tessellate"}));
  my $first           = 1;
  foreach my $boundary (@$polygon) {
    die("Error: Polygon coordinates boundary must be an array reference") unless ref($boundary) eq "ARRAY";
    my $string  = $self->coordinates_stringify($boundary);
    push @elements, E(($first ? "outerBoundaryIs" : "innerBoundaryIs"), {}, E(LinearRing=>{}, E(coordinates=>{}, $string)));
    $first      = 0;
  }
  return E(Polygon=>{}, @elements);
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
