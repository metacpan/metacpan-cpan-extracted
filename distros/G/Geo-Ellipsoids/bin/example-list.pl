#!/usr/bin/perl -w

=head1 NAME

example-list.pl - Geo::Ellipsoids list method example

=cut

use strict;
use lib qw{./lib ../lib};
use Geo::Ellipsoids;

my $obj=Geo::Ellipsoids->new(); #defaults to WGS84
my $list=$obj->list;
foreach (sort @$list) {
  $obj->set($_);
  print "Short Name: ", $obj->shortname, "\n";
  print "Long Name:  ", $obj->longname, "\n";
  print "Ellipsoid:  ", "{a=>",$obj->a,",b=>",$obj->b,"}", "\n";
  print "\n";
}
foreach (100,110,120,130) {
  $obj->set({a=>1,i=>$_});
  print "Short Name: ", $obj->shortname, "\n";
  print "Long Name:  ", $obj->longname, "\n";
  print "Ellipsoid:  ", "{a=>",$obj->a,",b=>",$obj->b,"}", "\n";
  print "\n";
}

__END__

=head1 Sample Output

  Short Name: Airy 1858
  Long Name:  Airy 1858 Ellipsoid
  Ellipsoid:  {a=>6377563.396,b=>6356256.90923729}

  Short Name: Airy Modified
  Long Name:  Modified Airy Spheroid
  Ellipsoid:  {a=>6377340.189,b=>6356034.448}

  Short Name: Australian National
  Long Name:  Australian National Spheroid
  Ellipsoid:  {a=>6378160,b=>6356774.71919531}

  Short Name: Bessel 1841
  Long Name:  Bessel 1841 Ellipsoid
  Ellipsoid:  {a=>6377397.155,b=>6356078.96281819}

  Short Name: Clarke 1866
  Long Name:  Clarke Ellipsoid of 1866
  Ellipsoid:  {a=>6378206.4,b=>6356583.79999999}

  Short Name: Clarke 1880
  Long Name:  Clarke Ellipsoid of 1880
  Ellipsoid:  {a=>6378249.145,b=>6356514.966}

  Short Name: Everest 1830
  Long Name:  Everest Spheroid of 1830
  Ellipsoid:  {a=>6377276.345,b=>6356075.41314024}

  Short Name: Everest Modified
  Long Name:  Modified Everest Spheroid
  Ellipsoid:  {a=>6377304.063,b=>6356103.03899315}

  Short Name: Fisher 1960
  Long Name:  Fisher 1960
  Ellipsoid:  {a=>6378166,b=>6356784.28360711}

  Short Name: Fisher 1968
  Long Name:  Fisher 1968
  Ellipsoid:  {a=>6378150,b=>6356768.33724438}

  Short Name: GRS80
  Long Name:  Geodetic Reference System of 1980
  Ellipsoid:  {a=>6378137,b=>6356752.31414035}

  Short Name: Hough 1956
  Long Name:  Hough 1956
  Ellipsoid:  {a=>6378270,b=>6356794.34343434}

  Short Name: International (Hayford)
  Long Name:  International (Hayford)
  Ellipsoid:  {a=>6378388,b=>6356911.94612795}

  Short Name: Krassovsky 1938
  Long Name:  Krassovsky 1938
  Ellipsoid:  {a=>6378245,b=>6356863.01877305}

  Short Name: NWL-9D
  Long Name:  NWL-9D Ellipsoid
  Ellipsoid:  {a=>6378145,b=>6356759.76948868}

  Short Name: SA69
  Long Name:  South American 1969
  Ellipsoid:  {a=>6378160,b=>6356774.71919531}

  Short Name: SGS85
  Long Name:  Soviet Geodetic System 1985
  Ellipsoid:  {a=>6378136,b=>6356751.30156878}

  Short Name: UTM
  Long Name:  Department of the Army Universal Transverse Mercator
  Ellipsoid:  {a=>6378249.2,b=>6356515}

  Short Name: WGS72
  Long Name:  World Geodetic System 1972
  Ellipsoid:  {a=>6378135,b=>6356750.52001609}

  Short Name: WGS84
  Long Name:  World Geodetic System of 1984
  Ellipsoid:  {a=>6378137,b=>6356752.31424518}

  Short Name: WOS
  Long Name:  War Office Spheroid
  Ellipsoid:  {a=>6378300.58,b=>6356752.26722973}

  Short Name: Custom
  Long Name:  Custom Ellipsoid {a=>1,i=>100}
  Ellipsoid:  {a=>1,b=>0.99}

  Short Name: Custom
  Long Name:  Custom Ellipsoid {a=>1,i=>110}
  Ellipsoid:  {a=>1,b=>0.990909090909091}

  Short Name: Custom
  Long Name:  Custom Ellipsoid {a=>1,i=>120}
  Ellipsoid:  {a=>1,b=>0.991666666666667}

  Short Name: Custom
  Long Name:  Custom Ellipsoid {a=>1,i=>130}
  Ellipsoid:  {a=>1,b=>0.992307692307692}

=cut
