# Copyrights 2008-2018 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Geo-WKT.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Geo::WKT;
use vars '$VERSION';
$VERSION = '0.96';

use base 'Exporter';

use strict;
use warnings;

use Geo::Shape  ();
use Carp;

our @EXPORT = qw(
  parse_wkt
  parse_wkt_point
  parse_wkt_polygon
  parse_wkt_geomcol
  parse_wkt_linestring
  wkt_point
  wkt_multipoint
  wkt_linestring
  wkt_polygon
  wkt_linestring
  wkt_multilinestring
  wkt_multipolygon
  wkt_optimal
  wkt_geomcollection
 );

sub wkt_optimal($);


sub parse_wkt_point($;$)
{     ($_[0] =~ m/^point\(\s*(\S+)\s+(\S+)\)$/i)
    ? Geo::Point->xy($1+0, $2+0, $_[1])
    : undef;
}


sub parse_wkt_polygon($;$)
{   my ($string, $proj) = @_;

    $string && $string =~ m/^polygon\(\((.+)\)\)$/i
        or return undef;

    my @poly;
    foreach my $poly (split m/\)\s*\,\s*\(/, $1)
    {   my @points = map +[split " ", $_, 2], split /\s*\,\s*/, $poly;
        push @poly, \@points;
    }

    Geo::Surface->new(@poly, proj => $proj);
}


sub parse_wkt_geomcol($;$)
{   my ($string, $proj) = @_;

    return undef if $string !~
        s/^(multiline|multipoint|multipolygon|geometrycollection)\(//i;

    my @comp;
    while($string =~ m/\D/)
    {   $string =~ s/^([^(]*\([^)]*\))//
            or last;

        my $take  = $1;
        while(1)
        {   my @open  = $take =~ m/\(/g;
            my @close = $take =~ m/\)/g;
            last if @open==@close;
            $take .= $1 if $string =~ s/^([^\)]*\))//;
        }
        push @comp, parse_wkt($take, $proj);
        $string =~ s/^\s*\,\s*//;
    }

    Geo::Space->new(@comp, proj => $proj);
}


sub parse_wkt_linestring($;$)
{   my ($string, $proj) = @_;

    $string && $string =~ m/^linestring\((.+)\)$/i
        or return undef;

    my @points = map +[split " ", $_, 2], split /\s*\,\s*/, $1;
    @points > 1 or return;

    Geo::Line->new(proj => $proj, points => \@points, filled => 0);
}


sub parse_wkt($;$)  # dirty code to avoid copying the sometimes huge string
{
      $_[0] =~ m/^point\(/i      ? &parse_wkt_point
    : $_[0] =~ m/^polygon\(/i    ? &parse_wkt_polygon
    : $_[0] =~ m/^linestring\(/i ? &parse_wkt_linestring
    :                              &parse_wkt_geomcol;
}


sub _list_of_points(@)
{   my @points
      = @_ > 1                      ? @_
      : ref $_[0] eq 'ARRAY'        ? @{$_[0]}
      : $_[0]->isa('Math::Polygon') ? $_[0]->points
      : $_[0];

    my @s = map
      { (ref $_ ne 'ARRAY' && $_->isa('Geo::Point'))
      ? $_->x.' '.$_->y
      : $_->[0].' '.$_->[1]
      } @points;

    local $" = ',';
    "(@s)";
}

sub wkt_point($;$)
{   my ($x, $y)
       = @_==2                ? @_
       : ref $_[0] eq 'ARRAY' ? @{$_[0]}
       :                       shift->xy;

    defined $x && defined $y ? "POINT($x $y)" : ();
}


sub wkt_linestring(@) { 'LINESTRING' . _list_of_points(@_) }


sub wkt_polygon(@)
{   my @polys
      = !defined $_[0]             ? return ()
      : ref $_[0] eq 'ARRAY'       ? (ref $_[0][0] ? @_ : [@_])
      : $_[0]->isa('Geo::Line')    ? @_
      : $_[0]->isa('Geo::Surface') ? ($_[0]->outer, $_[0]->inner)
      :                              [@_];

    'POLYGON(' .join(',' ,  map _list_of_points($_), @polys). ')';
}


sub wkt_multipoint(@) { 'MULTIPOINT(' .join(',', map wkt_point($_), @_). ')'}


sub wkt_multilinestring(@)
{   return () unless @_;
    'MULTILINESTRING(' .join(',' ,  map wkt_linestring($_), @_). ')';
}


sub wkt_multipolygon(@)
{   return () unless @_;

    my @polys = map wkt_polygon($_), @_;
    s/^POLYGON// for @polys;

    'MULTIPOLYGON(' .join(',' , @polys). ')';
}



sub wkt_optimal($)
{   my $geom = shift;
    return wkt_point(undef) unless defined $geom;

    return wkt_point($geom)
        if $geom->isa('Geo::Point');

    return ( $geom->isRing && $geom->isFilled
           ? wkt_polygon($geom)
           : wkt_linestring($geom))
        if $geom->isa('Geo::Line');

    return wkt_multipolygon($geom)
        if $geom->isa('Geo::Surface');

    $geom->isa('Geo::Space')
        or croak "ERROR: Cannot translate object $geom into SQL";

      $geom->nrComponents==1 ? wkt_optimal($geom->component(0))
    : $geom->onlyPoints      ? wkt_multipoint($geom->points)
    :                          wkt_geomcollection($geom);
}


sub wkt_geomcollection(@)
{   @_ = $_[0]->components
       if @_==1
       && ref $_[0] ne 'ARRAY'
       && $_[0]->isa('Geo::Space');

    'GEOMETRYCOLLECTION(' .join(',', map wkt_optimal($_), @_). ')';
}

1;
