use strict;
use warnings;
use Geo::Heatmap::USNaviguide_Google_Tiles;
use Data::Dumper;
use DBI;
use YAML;

my $dbh = DBI->connect("dbi:Pg:dbname=gisdb", 'gisdb', 'gisdb', {AutoCommit => 0});

## where are most of my points:
# we use ST_GeoHash with a length of 5 (about city size)
# to group the points
# as there may be points which ST_GeoHash can not handle we check the borders
# where most of the points are ie points with the same hash
# select the Box (ST_Extent) covering all this points
# to be more sure one could use more rows 


my $sth = $dbh->prepare(qq(
  with geohash as (
    select ST_GeoHash(geom::geometry, 5) st_geohash,
           geom
       from geodata where
          not(St_X(geom) < -180 or St_Y(geom)< -90 or St_X(geom) > 180 or St_Y(geom) > 90)
    )
  SELECT ST_Extent(geom) as extent FROM geohash 
    where st_geohash =
        (select st_geohash from 
           (select st_geohash, count(*) c 
              from geohash 
             group by st_geohash 
     order by c desc limit 1) max_geohash)
  )
);

$sth->execute();
my @p;
my @r = $sth->fetchrow;
my ($lats, $lngw, $latn, $lnge) = ($r[0] =~/BOX\((.+?) (.+?),(.+?) (.+?)\)/);
$sth->finish;

print STDERR "$lats, $lngw, $latn, $lnge\n";

## 48.164089, 16.3476612, 48.2080069, 16.391593
## my $lats = 48.164089;
## my $latn = 48.2080069;
## my $lngw = 16.3476612;
## my $lnge = 16.391593;

my @gt;

my $max_per_level = {}; 
for (my $zoomlevel = 0; $zoomlevel <=18; $zoomlevel++) 
{
  my $max = 0;
  $max_per_level->{$zoomlevel} = 0;
  @gt = Google_Tiles($lats, $lngw, $latn, $lnge, $zoomlevel);
  
  foreach my $tile (@gt) {
    $max = max_points_per_tile($tile->{NAMEX}, $tile->{NAMEY}, $zoomlevel);
    $max_per_level->{$zoomlevel} = $max if $max > $max_per_level->{$zoomlevel}; 
  }
  printf STDERR "Tile found [%s] Zoom [%s] max points [%s]\n", scalar @gt, $zoomlevel, $max;
}
print Dump $max_per_level;

sub max_points_per_tile {
  my ($x, $y, $z) = @_;

  my $value = &Google_Tile_Factors($z, 0) ;

  my %r = Google_Tile_Calc($value, $y, $x);

  my @density;
  my $bin = 8;
  my $ps = get_points(\%r);
  my $max = 0;
  
  foreach my $p (@$ps) {
    my @d = Google_Coord_to_Pix($value, $p->[0], $p->[1]);
    my $ix = $d[1] - $r{PXW};
    my $iy = $d[0] - $r{PYN};
    $density[int($ix/$bin)][int($iy/$bin)] ++;
    $max = $density[int($ix/$bin)][int($iy/$bin)] if $density[int($ix/$bin)][int($iy/$bin)] > $max;
  }
  return $max;
}

sub get_points {
  my $r = shift;
  my $sth = $dbh->prepare( qq(select ST_AsEWKT(geom) from geodata
                         where geom &&
              ST_SetSRID(ST_MakeBox2D(ST_Point($r->{LATN}, $r->{LNGW}),
                                      ST_Point($r->{LATS}, $r->{LNGE})
                        ),4326))
              );

  $sth->execute();
  my @p;
  while (my @r = $sth->fetchrow) {
    my ($x, $y) = ($r[0] =~/POINT\((.+?) (.+?)\)/);
    push (@p, [$x ,$y]);
  }
  $sth->finish;
  return \@p;
}

