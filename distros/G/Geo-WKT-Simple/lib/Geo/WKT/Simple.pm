package Geo::WKT::Simple;
use strict;
use warnings;

use parent 'Exporter';

our $VERSION = '0.05';

our @EXPORT;
our %EXPORT_TAGS = (
    all => \@EXPORT,
    parse => [qw/
      wkt_parse_point
      wkt_parse_linestring
      wkt_parse_multilinestring
      wkt_parse_polygon
      wkt_parse_multipolygon
      wkt_parse_geometrycollection
      wkt_parse
    /],
    make => [qw/
      wkt_make_point
      wkt_make_linestring
      wkt_make_multilinestring
      wkt_make_polygon
      wkt_make_multipolygon
      wkt_make_geometrycollection
      wkt_make
    /],
);
@EXPORT = map { @{ $_ } } @EXPORT_TAGS{qw/ parse make /};

sub _parse_point {
    $_[0] =~ /^\s*(\S+)\s+(\S+)\s*$/
}

sub _parse_points_list {
    map { [ _parse_point($_) ] } split /\s*,\s*/, $_[0]
}

sub _parse_points_group {
    map {
        [ _parse_points_list($_) ]
    } split /\s*\)\s*,\s*\(\s*/, $_[0]
}

sub _parse_points_group_list {
    map {
        [ _parse_points_group($_) ]
    } split /\s*\)\s*\)\s*,\s*\(\s*\(\s*/, $_[0]
}

sub wkt_parse_point {
    my ($data) = $_[0] =~ /^point\s*\((.+)\)$/i
        or return;

    _parse_point($data);
}

sub wkt_parse_linestring {
    my ($data) = $_[0] =~ /^linestring\s*\((.+)\)$/i
        or return;

    _parse_points_list($data);
}

sub wkt_parse_multilinestring {
    my ($data) = $_[0] =~ /^multilinestring\s*\(\s*\((.+)\)\s*\)$/i
        or return;

    _parse_points_group($data);
}

sub wkt_parse_polygon {
    my ($data) = $_[0] =~ /^polygon\s*\(\s*\((.+)\)\s*\)$/i
        or return;

    _parse_points_group($data);
}

sub wkt_parse_multipolygon {
    my ($data) = $_[0] =~ /^multipolygon\s*\(\s*\(\s*\((.+)\)\s*\)\s*\)$/i
        or return;

    _parse_points_group_list($data);
}

my $ALLTYPES = 'POINT|(?:MULTI)?(?:LINESTRING|POLYGON)|GEOMETRYCOLLECTION';
sub wkt_parse_geometrycollection {
    my ($wkt) = $_[0] =~ /^geometrycollection\s*\((.+)\)$/i
        or return;

    # Copy from Geo::WKT
    my @comps;
    while ($wkt =~ /\D/) {
        last unless $wkt =~ s/^[^(]*\([^)]*\)//;
        my $take  = $&;
        while (1) {
            my @open  = $take =~ /\(/g;
            my @close = $take =~ /\)/g;
            last if @open == @close;
            $take .= $& if $wkt =~ s/^[^\)]*\)//;
        }
        my ($type) = $take =~ /^($ALLTYPES)/i;
        push @comps, [ uc($type) => [ wkt_parse($type => $take) ] ];

        $wkt =~ s/^\s*,\s*//;
    }

    @comps;
}

sub wkt_parse {
    my ($type, $wkt) = @_;

    return if $type !~ /^$ALLTYPES$/i;
    __PACKAGE__->can('wkt_parse_'.lc($type))->($wkt);
}

sub _cat {
    '('.join(', ', @_).')'
}

sub _catlinestring {
    _cat( map { "$_->[0] $_->[1]" } @_ )
}

sub _catpolygon {
    _cat( map { _catlinestring(@$_) } @_ )
}

sub wkt_make_point {
    'POINT'._cat("$_[0] $_[1]")
}

sub wkt_make_linestring {
    'LINESTRING'._catlinestring(@_)
}

sub wkt_make_multilinestring {
    'MULTILINESTRING'._catpolygon(@_)
}

sub wkt_make_polygon {
    'POLYGON'._catpolygon(@_)
}

sub wkt_make_multipolygon {
    'MULTIPOLYGON'._cat(
        map { _catpolygon(@$_) } @_
    )
}

sub wkt_make_geometrycollection {
    'GEOMETRYCOLLECTION'._cat( map { wkt_make(@$_) } @_ )
}

sub wkt_make {
    my ($type, $data) = @_;

    return if $type !~ /^$ALLTYPES$/i;
    __PACKAGE__->can('wkt_make_'.lc($type))->(@$data);
}

1;
__END__

=head1 NAME

Geo::WKT::Simple - Simple utils to parse/build Well Known Text(WKT) format string.

=head1 SYNOPSIS

  use Geo::WKT::Simple;           # Export all
  or
  use Geo::WKT::Simple ':parse';  # Only WKT parser functions
  or
  use Geo::WKT::Simple ':make';   # Only WKT builder functions

  # WKT POINT
  wkt_parse_point('POINT(10 20)');                  #=> (10 20)
  wkt_make_point(10, 20);                           #=> POINT(10 20)

  # WKT LINESTRING
  wkt_parse_linestring('LINESTRING(1 2, 3 4)');     #=> ([ 1, 2 ], [ 3, 4 ])
  wkt_make_linestring([ 1, 2 ], [ 3, 4 ]);          #=> LINESTRING(1 2, 3 4)

  # WKT POLYGON
  wkt_parse_polygon('POLYGON((1 2, 3 4, 5 6, 1 2), (1 2, 3 4, 5 6, 1 2))');
  #=> (
  #      [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ], [ 1, 2 ] ],
  #      [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ], [ 1, 2 ] ],
  #   )
  wkt_make_polygon(
      [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ], [ 1, 2 ] ],
      [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ], [ 1, 2 ] ],
  ); #=> 'POLYGON((1 2, 3 4, 5 6, 1 2), (1 2, 3 4, 5 6, 1 2))'

  # And like so on for (MULTI)LINESTRING|POLYGON

  # WKT GEOMETRYCOLLECTION
  wkt_parse_geometrycollection(
      'GEOMETRYCOLLECTION(POINT(10 20), LINESTRING(10 20, 30 40))'
  ); #=> ([ POINT => [ 10, 20 ] ], [ LINESTRING => [ [ 10, 20 ], [ 30, 40 ] ] ])
  wkt_make_geometrycollection(
      [ POINT => [ 10, 20 ] ], [ LINESTRING => [ [ 10, 20 ], [ 30, 40 ] ] ]
  ); #=> 'GEOMETRYCOLLECTION(POINT(10 20), LINESTRING(10 20, 30 40))'


  # If you don't like too many exported symbols:
  use Geo::WKT::Simple qw/ wkt_parse wkt_make /;
  wkt_parse(POINT => 'POINT(10 20)');
  wkt_make(POINT => [ 10, 20 ]);

=head1 DESCRIPTION

Geo::WKT::Simple is a module to provide simple parser/builder for Well Known Text(WKT) format string.

This module can parse/build WKT format string into/from pure perl data structure.

=head2 Why not L<Geo::WKT> ?

There is few reasons.

=over

=item - I just need simple return value represented by pure perl data structure.
Geo::WKT returns results as a Geo::* instances which represents each type of geodetic components.

=item - L<Geo::Proj4> dependencies. L<Geo::Proj4> depends to libproj4

=item - I need to support MULTI(LINESTRING|POLYGON).

=back

=head1 FUNCTIONS

See SYNOPSIS section for usages.

=head2 wkt_parse_point()

Parse WKT Point string.

=head2 wkt_parse_linestring()

Parse WKT Linestring string.

=head2 wkt_parse_multilinestring()

Parse WKT MultiLinestring string.

=head2 wkt_parse_polygon()

Parse WKT Polygon string.

=head2 wkt_parse_multipolygon()

Parse WKT MultiPolygon string.

=head2 wkt_parse_geometrycollection()

Parse WKT GeometryCollection string.

=head2 wkt_parse()

Dispatch to parser which specified in first argument.

  wkt_parse(POINT => 'POINT(10 20)') is equivalent to wkt_parse_point('POINT(10 20)')

=head2 wkt_make_point()

Build WKT Point string.

=head2 wkt_make_linestring()

Build WKT Linestring string.

=head2 wkt_make_multilinestring()

Build WKT MultiLinestring string.

=head2 wkt_make_polygon()

Build WKT Polygon string.

=head2 wkt_make_multipolygon()

Build WKT MultiPolygon string.

=head2 wkt_make_geometrycollection()

Build WKT GeometryCollection string.

=head2 wkt_make()

Dispatch to builder function which specified in first argument.

  wkt_make(POINT => [ 10, 20 ]) is equivalent to wkt_make_point(10, 20)

=head1 AUTHOR

Yuto KAWAMURA(kawamuray) E<lt>kawamuray.dadada {at} gmail.comE<gt>

=head1 SEE ALSO

L<Geo::WKT>: As same as this module except few things.

Well-known text: http://en.wikipedia.org/wiki/Well-known_text

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
