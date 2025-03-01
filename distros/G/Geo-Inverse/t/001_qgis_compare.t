#!/usr/bin/perl
use strict;
use warnings;
use Test::Number::Delta relative => 1e-7;
use Test::More tests => 10;

BEGIN{use_ok('Geo::Inverse');};

my $debug = $ENV{'TEST_DEBUG'};
my $o     = Geo::Inverse->new;
isa_ok($o, 'Geo::Inverse');

{
  #MultiLineString ((-77.03460486004219376 38.8897543336967928, -77.00897613176105949 38.88988090882982362))
  #2223.60811 m
  my $dist_qgis = 2223.60811;
  my $dist_perl = $o->inverse(38.88975433369679, -77.0346048600422, 38.889880908829824, -77.00897613176106);
  diag("\nDist: Perl => $dist_perl m, QGIS => $dist_qgis m") if $debug;

  delta_within($dist_perl, $dist_qgis, 1e-5, 'distance compares to qgis');
  delta_ok($dist_perl, $dist_qgis, 'distance compares to qgis to about 7 significant figures');
}

{
  #MultiLineString ((-77.0365381628055701 38.89762940542472336, -77.03648927884935915 38.89397532969779547))
  #405.67388 m
  my $dist_qgis = 405.67388;
  my $dist_perl = $o->inverse(38.89762940542472336, -77.0365381628055701, 38.89397532969779547, -77.03648927884935915);
  diag("\nDist: Perl => $dist_perl m, QGIS => $dist_qgis m") if $debug;

  delta_within($dist_perl, $dist_qgis, 1e-5, 'distance compares to qgis');
  delta_ok($dist_perl, $dist_qgis, 'distance compares to qgis to about 7 significant figures');
}

{
  #MultiLineString ((-77.03655343904441111 38.89770063088451479, -77.43355694679300427 37.53881754174707197))
  #154791.10 m
  my $dist_qgis = 154791.10;
  my $dist_perl = $o->inverse(38.89770063088451479, -77.03655343904441111, 37.53881754174707197, -77.43355694679300427);
  diag("\nDist: Perl => $dist_perl m, QGIS => $dist_qgis m") if $debug;

  delta_within($dist_perl, $dist_qgis, 1e-2, 'distance compares to qgis to about 7 significant figures');
  delta_ok($dist_perl, $dist_qgis, 'distance compares to qgis to about 7 significant figures');
}

{
  #MultiLineString ((-77.03655343904441111 38.89770063088451479, -121.49340089639481732 38.5765645457972326))
  #3826214.64 m
  my $dist_qgis = 3826214.64;
  my $dist_perl = $o->inverse(38.89770063088451479, -77.03655343904441111, 38.5765645457972326, -121.49340089639481732);
  diag("\nDist: Perl => $dist_perl m, QGIS => $dist_qgis m") if $debug;

  delta_within($dist_perl, $dist_qgis, 1e-2, 'distance compares to qgis to about 7 significant figures');
  delta_ok($dist_perl, $dist_qgis, 'distance compares to qgis to about 7 significant figures');
}
