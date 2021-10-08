package Geo::GoogleEarth::Pluggable::Plugin::Default;
use strict;
use warnings;
use Geo::GoogleEarth::Pluggable::Contrib::Point;
use Geo::GoogleEarth::Pluggable::Contrib::LineString;
use Geo::GoogleEarth::Pluggable::Contrib::LinearRing;
use Geo::GoogleEarth::Pluggable::Contrib::Polygon;
use Geo::GoogleEarth::Pluggable::Contrib::MultiPolygon;

our $VERSION='0.17';

=head1 NAME

Geo::GoogleEarth::Pluggable::Plugin::Default - Geo::GoogleEarth::Pluggable Default Plugin Methods

=head1 METHODS

Methods in this package are AUTOLOADed into the  Geo::GoogleEarth::Pluggable::Folder namespace at runtime.

=head1 CONVENTIONS

Plugin Naming Convention: Geo::GoogleEarth::Pluggable::Plugin::CPANID (e.g. "MRDVT")
Object Naming Convention: Geo::GoogleEarth::Pluggable::Contrib::"$method" (e.g. Point, CircleByCenterPoint)

You only need to have one plugin pointing to all of your contributed objects.

The package should be named after the plugin not the objects since there is a many to one relationship.  (e.g. Geo-GoogleEarth-Pluggable-Plugin-MRDVT)

=head2 Point

Constructs a new Placemark Point object and appends it to the parent folder object.  Returns the object reference if you need to make any setting changes after construction.

  my $point=$folder->Point(name=>"My Placemark",
                           lat=>38.897607,
                           lon=>-77.036554,
                           alt=>0);

=cut

sub Point {
  my $self=shift; #This will be a Geo::GoogleEarth::Pluggable::Folder object
  my $obj=Geo::GoogleEarth::Pluggable::Contrib::Point->new(document=>$self->document, @_);
  $self->data($obj);
  return $obj;
}

=head2 Polygon

  $folder->Polygon(
                   name        => "My Polygon",
                   coordinates => [
                                    [ #outerBoundaryIs
                                      [ -95.74356, 29.61974 ],
                                      [ -95.74868, 29.62188 ],
                                      [ -95.74857, 29.62210 ],
                                      [ -95.74256, 29.62266 ],
                                      [ -95.74356, 29.61974 ],
                                    ],
                                    \@innerBoundaryIs1,
                                    \@innerBoundaryIs2,
                                    \@innerBoundaryIs3,
                                  ],
                   style       => $style,
                   open        => 1,
                   description => $html,
                  ),

=cut

sub Polygon {
  my $self = shift; #This will be a Geo::GoogleEarth::Pluggable::Folder object
  my $obj  = Geo::GoogleEarth::Pluggable::Contrib::Polygon->new(document=>$self->document, @_);
  $self->data($obj);
  return $obj;
}

=head2 MultiPolygon

  $folder->MultiPolygon(
                        name        => "My MultiPolygon",
                        coordinates => [ #MultiGeometry
                                         [ #Polygon1
                                           [
                                             [ -95.45662, 29.77814 ],
                                             [ -95.45668, 29.77809 ],
                                             [ -95.45675, 29.77814 ],
                                             [ -95.45669, 29.77820 ],
                                             [ -95.45662, 29.77814 ],
                                           ],
                                           \@innerBoundaryIs1,
                                         ],
                                         [ #Polygon2
                                           [
                                             [ -95.45677, 29.77785 ],
                                             [ -95.45683, 29.77780 ],
                                             [ -95.45689, 29.77785 ],
                                             [ -95.45683, 29.77791 ],
                                             [ -95.45677, 29.77785 ],
                                           ],
                                         ],
                                       ],
                       );

=cut

sub MultiPolygon {
  my $self = shift; #This will be a Geo::GoogleEarth::Pluggable::Folder object
  my $obj  = Geo::GoogleEarth::Pluggable::Contrib::MultiPolygon->new(document=>$self->document, @_);
  $self->data($obj);
  return $obj;
}

=head2 LineString

  $folder->LineString(name=>"My Placemark",
                      coordinates=>[
                                     [lat,lon,alt],
                                     {lat=>$lat,lon=>$lon,alt=>$alt},
                                   ]);

=cut

sub LineString {
  my $self=shift;
  my $obj=Geo::GoogleEarth::Pluggable::Contrib::LineString->new(document=>$self->document, @_);
  $self->data($obj);
  return $obj;
}

=head2 LinearRing

  $folder->LinearRing(name=>"My Placemark",
                      coordinates=>[
                                     [lat,lon,alt],
                                     {lat=>$lat,lon=>$lon,alt=>$alt},
                                   ]);

=cut

sub LinearRing {
  my $self=shift;
  my $obj=Geo::GoogleEarth::Pluggable::Contrib::LinearRing->new(document=>$self->document, @_);
  $self->data($obj);
  return $obj;
}

=head1 TODO

Need to determine what methods should be in the Folder package and what should be on the Plugin/Default package and why.

=head1 BUGS

Please log on RT and send to the geo-perl email list.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis (mrdvt92)
  CPAN ID: MRDVT

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<Geo::GoogleEarth::Pluggable::Contrib::Point>, L<Geo::GoogleEarth::Pluggable::Contrib::LineString>, L<Geo::GoogleEarth::Pluggable::Contrib::LinearRing>

=cut

1;
