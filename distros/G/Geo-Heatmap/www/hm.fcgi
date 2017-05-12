#!/usr/bin/env perl

use strict;
use FCGI;
use DBI;
use CHI;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use YAML;

use Geo::Heatmap;

#my $cache = CHI->new( driver  => 'Memcached::libmemcached',
#    servers    => [ "127.0.0.1:11211" ],
#    namespace  => 'GoogleMapsHeatmap',
#);


my $cache = CHI->new( driver => 'File',
         root_dir => '/tmp/domainmap'
     );


our $dbh = DBI->connect("dbi:Pg:dbname=gisdb", 'gisdb', 'gisdb', {AutoCommit => 0});

my $request = FCGI::Request();

while ($request->Accept() >= 0) {
  my $env = $request->GetEnvironment();
  my $p = $env->{'QUERY_STRING'};
  
  my ($tile) = ($p =~ /tile=(.+)/);
  $tile =~ s/\+/ /g;
  
  # package needs a CHI Object for caching 
  #               a Function Reference to get LatLOng within a Google Tile
  #               maximum number of points per zoom level
 
  my $ghm = Geo::Heatmap->new();
  $ghm->palette('palette.store');

#  my $zoom_scale = 
#     {
#          '11' => 360,
#          '7' => 24133,
#          '17' => 5,
#          '2' => 151470,
#          '1' => 255623,
#          '18' => 4,
#          '0' => 270381,
#          '16' => 5,
#          '13' => 36,
#          '6' => 32306,
#          '3' => 89700,
#          '9' => 3129,
#          '12' => 116,
#          '14' => 16,
#          '15' => 8,
#          '8' => 10781,
#          '4' => 77088,
#          '10' => 1109,
#          '5' => 60148
#        };

  $ghm->zoom_scale( YAML::LoadFile('zoom_scale.yml') ); 

  $ghm->cache($cache);
  $ghm->return_points( \&get_points );
  my $image = $ghm->tile($tile);
  
  my $length = length($image);
  
  print "Content-type: image/png\n";
  print "Content-length: $length \n\n";
  binmode STDOUT;
  print $image;
                                       
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

