#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: base.t,v 0.1 2006/02/21 eserte Exp $
# Author: Michael R. Davis
#

=head1 NAME

base.t - Good examples concerning how to use this module

=cut

use strict;
use blib;
#use lib q{lib};
#use lib q{../lib};
use constant NEAR_DEFAULT => 7;

sub near {
  my $x=shift();
  my $y=shift();
  my $p=shift()||NEAR_DEFAULT;
  if (abs($y) > 10**-$p) {
    if (($x-$y)/$y < 10**-$p) {
      return 1;
    } else {
      return 0;
    }
  } else {
    if (abs($x-$y) < 10**-$p) { # if $y is near 0
      return 1;
    } else {
      return 0;
    }
  }
}


BEGIN {
    if (!eval q{
	use Test;
	1;
    }) {
	print "1..0 # tests only works with installed Test module\n";
	exit;
    }
}

BEGIN { plan tests => 52 }

# just check that all modules can be compiled
ok(eval {require Geo::ECEF; 1}, 1, $@);

my $o = Geo::ECEF->new();
ok(ref $o, "Geo::ECEF");

my ($x, $y, $z)=$o->ecef(0,0,0);
ok(near $x, 6378137.000);
ok(near $z, 0, 13);

($x, $y, $z)=$o->ecef(0,90,0);
ok(near $z, 0, 13);
ok(near $y, 6378137.000, 13);

($x, $y, $z)=$o->ecef(0,90,100);
ok(near $z, 0, 13);
ok(near $y, 6378237.000, 13);

($x, $y, $z)=$o->ecef(90,0,0);
ok(near $z, 6356752.31424518, 13);
ok(near $y, 0, 13);

($x, $y, $z)=$o->ecef(90,0,100);
ok(near $z, 6356852.31424518, 13);
ok(near $y, 0, 13);

($x, $y, $z)=$o->ecef(90,0,0);
ok(near $y, 0, 13);

($x, $y, $z)=$o->ecef(0,0,100);
ok(near $x, 6378237.000, 13);

($x, $y, $z)=$o->ecef(30.2746722,-97.7403306,0);
ok(near $x, -742507.1);
ok(near $y, -5462738.5);
ok(near $z, 3196706.5);

($x, $y, $z)=$o->ecef(38.684,-77.150,0);
ok(near $x, 1110000, 2);
ok(near $y, -4860000, 3);
ok(near $z, 3960000, 2);

($x, $y, $z)=$o->ecef(37.89038,126.73316,23);
ok(near $x, -3014326.6);
ok(near $y, 4039148.7);
ok(near $z, 3895863);

my $xyz=$o->ecef(37.89038,126.73316,23);
ok(near $xyz->[0], -3014326.6);
ok(near $xyz->[1], 4039148.7);
ok(near $xyz->[2], 3895863);

my ($lat, $lon, $hae)=$o->geodetic(-3014326.6, 4039148.7, 3895863);
ok(near $lat, 37.89038);
ok(near $lon, 126.73316);
ok(near $hae, 23, 2);

my $llh=$o->geodetic(-3014326.6, 4039148.7, 3895863);
ok(near $llh->[0], 37.89038);
ok(near $llh->[1], 126.73316);
ok(near $llh->[2], 23, 2);

$o->initialize('GRS80');
#Test Data From http://www.ngs.noaa.gov/cgi-bin/xyz_getxyz.prl
($lat, $lon, $hae)=$o->geodetic(1116523.1999, 4836193.3033, 3992379.9547);
ok(near $lat, 39, 10);
ok(near $lon, 77, 10);
ok(near $hae, 100, 6);

($lat, $lon, $hae)=$o->geodetic(1116523.1999, -4836193.3033, 3992379.9547);
ok(near $lat, 39, 10);
ok(near $lon, -77, 10);
ok(near $hae, 100, 6);

($lat, $lon, $hae)=$o->geodetic_direct(1116523.1999, -4836193.3033, 3992379.9547);
ok(near $lat, 39, 9);
ok(near $lon, -77, 9);
ok(near $hae, 100, 6);

$llh=$o->geodetic_direct(1116523.1999, -4836193.3033, 3992379.9547);
ok(near $llh->[0], 39, 9);
ok(near $llh->[1], -77, 9);
ok(near $llh->[2], 100, 6);

($lat, $lon, $hae)=$o->geodetic($o->ecef(90,0,0));
ok(near $lat, 90, 10);
ok(near $hae, 0, 10);

($lat, $lon, $hae)=$o->geodetic($o->ecef(-90,0,0));
ok(near $lat, -90, 10);
ok(near $hae, 0, 10);

($lat, $lon, $hae)=$o->geodetic_direct($o->ecef(90,0,0));
ok(near $lat, 90, 10);
ok(near $hae, 0, 10);

($lat, $lon, $hae)=$o->geodetic_direct($o->ecef(-90,0,0));
ok(near $lat, -90, 10);
ok(near $hae, 0, 10);

