package Geo::JSON::Simple;
BEGIN {
  $Geo::JSON::Simple::AUTHORITY = 'cpan:GETTY';
}
{
  $Geo::JSON::Simple::VERSION = '0.001';
}
# ABSTRACT: Simplified functions for generating Geo::JSON objects

use strict;
use warnings;
use Exporter 'import';
use Carp 'croak';
use List::MoreUtils qw(
  natatime
);

use Geo::JSON;
use Geo::JSON::Point;
use Geo::JSON::MultiPoint;
use Geo::JSON::LineString;
use Geo::JSON::MultiLineString;
use Geo::JSON::Polygon;
use Geo::JSON::MultiPolygon;
use Geo::JSON::Feature;
use Geo::JSON::FeatureCollection;
use Geo::JSON::GeometryCollection;

our @EXPORT = qw(

  point
  multipoint
  linestring
  multilinestring
  polygon
  multipolygon

  feature
  featurecollection
  geometrycollection

  from_geo_json

);

sub point { Geo::JSON::Point->new({ coordinates => [ $_[0], $_[1] ] }) }
sub multipoint { Geo::JSON::MultiPoint->new({ coordinates => [ _make_positions(@_) ] }) }

sub linestring { Geo::JSON::LineString->new({ coordinates => [ _make_positions(@_) ] }) }
sub multilinestring { Geo::JSON::MultiLineString->new({ coordinates => [ map {
  [_make_positions(@{$_})]
} @_ ] }) }

sub polygon { Geo::JSON::Polygon->new({ coordinates => [ _make_linear_ring(@_) ] }) }
sub multipolygon { Geo::JSON::MultiPolygon->new({ coordinates => [ map {
  [_make_linear_ring(@{$_})]
} @_ ] }) }

sub _make_linear_ring { map {
  my @coordlist = _make_positions(@{$_}); [@coordlist,$coordlist[0]]
} @_ }

sub _make_positions {
  my $it = natatime 2, @_;
  my @coords;
  while (my @pair = $it->()) {
    push @coords, [@pair];
  }
  return @coords;
}

sub feature {
  my ( $object, %properties ) = @_;
  Geo::JSON::Feature->new({
    geometry => $object,
    properties => \%properties
  });
}

sub featurecollection {
  my @features;
  my $current_geometry;
  my @args;
  for (@_) {
    if (ref $_) {
      if ($current_geometry) {
        push @features, feature($current_geometry, @args);
        @args = ();
        $current_geometry = $_;
      } else {
        $current_geometry = $_;
      }
    } elsif (!$current_geometry) {
      croak "featurecollection needs to start with a geometry";
    } else {
      push @args, $_;
    }
  }
  if ($current_geometry) {
    push @features, feature($current_geometry, @args);
  }
  Geo::JSON::FeatureCollection->new({
    features => \@features
  });
}

sub geometrycollection {
  Geo::JSON::GeometryCollection->new({
    geometries => \@_
  });
}

sub from_geo_json { Geo::JSON->from_json(@_) }

1;

__END__

=pod

=head1 NAME

Geo::JSON::Simple - Simplified functions for generating Geo::JSON objects

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Geo::JSON::Simple;

  my $point = point(qw( 1.1 1.1 ));
  $point->to_json; # See Geo::JSON->to_json

  # all functions generate several points out of a list
  multipoint(qw( 1.1 1.1 2.2 2.2 ));

  # polygon don't need the first element repeated at the end
  polygon([qw( 100.0 0.0 101.0 0.0 101.0 1.0 100.0 1.0 )]);

  collection(
    point(qw( 1.1 1.1 )), linestring(qw( 2.2 2.2 3.3 3.3 1.3 1.3 ))
  );

  feature point(qw( 717862.48638976 6648347.0162409 )),
    gold_amount => 23,
    data => "Here is the gold";

  geometrycollection(
    point(qw( 34 55 )), player => 1,
    point(qw( 56 15 )), player => 2,
    point(qw( 87 33 )), player => 3,
    point(qw( 11 23 )), player => 4
  );

  from_geo_json($json); # Shortcut to Geo::JSON->from_json

=head1 DESCRIPTION

This module gives an easy access to L<Geo::JSON>. You can generate complex
Geo::JSON object structures with simple commands. It also is a bit practical
orientated to avoid boilerplate in your code. More magic is upcoming (but not
much as far as I can see what is possible).

=encoding utf8

=head1 FUNCTIONS

=head2 point

Returns a L<Geo::JSON::Point>.

=head2 multipoint

Returns a L<Geo::JSON::MultiPoint>.

=head2 linestring

Returns a L<Geo::JSON::LineString>.

=head2 multilinestring

Returns a L<Geo::JSON::MultiLineString>.

=head2 polygon

Returns a L<Geo::JSON::Polygon>.

=head2 multipolygon

Returns a L<Geo::JSON::MultiPolygon>.

=head2 feature

Returns a L<Geo::JSON::Feature>.

=head2 featurecollection

Returns a L<Geo::JSON::FeatureCollection>.

=head2 geometrycollection

Returns a L<Geo::JSON::GeometryCollection>.

=head2 from_geo_json

Shortcut to L<Geo::JSON/from_json>.

=head1 SEE ALSO

=over 4

=item L<Geo::JSON>

=item L<http://geojson.org/>

=back

=head1 SUPPORT

IRC

  Join #duckduckgo on irc.freenode.net. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-geo-json-simple
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-geo-json-simple/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
