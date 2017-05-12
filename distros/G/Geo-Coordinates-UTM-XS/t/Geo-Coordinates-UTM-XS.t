#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 34000;

our $debug = 0; # 1;

use Geo::Coordinates::UTM::XS ();
# use Geo::Coordinates::UTM ();

if ($debug) {
    open LOG, ">/tmp/log";
    select LOG; $| = 1;
    select STDOUT;
}

sub isub (*) {
    my $name = shift;
    no strict 'refs';
    my $sub = eval "\\\&Geo::Coordinates::UTM::XS::$name";
    # my $sub = eval "\\\&Geo::Coordinates::UTM::$name";
    if ($debug) {
	*{$name} = sub {
	    my @ret = $sub->(@_);
	    printf LOG "%s(%s) ==> %s\n",
		$name, join(', ', @_), join(', ', @ret);
	    @ret;
	}
    }
    else {
	*{$name} = $sub;
    }
}

isub latlon_to_utm;
isub latlon_to_utm_force_zone;
isub utm_to_latlon;

use constant maxerror => 7.5e-4;

use warnings;
use strict;

sub fleq ($$;$) {
    if (abs($_[0] - $_[1]) < maxerror) {
        pass($_[2]);
    }
    else {
        fail($_[2]);
	print LOG "ERROR: $_[0] != $_[1] ($_[2])\n" if $debug;
        diag("floating point value $_[0] too different to reference $_[1]");
    }
}

open TD, '<', 't/test.dat'
    or die "unable to open test data file 't/test.dat'";

my $latlon = "CDEFGHJKLMNPQRSTUVWX";

while(<TD>) {
    chomp;
    next if /^\s*(?:#.*)?$/;
    print LOG "DATA: $_\n" if $debug;
    my ($ellipsoid, $latitude, $longitude, $zone, $easting, $northing) = split /\|/;
    my ($z, $e, $n) = latlon_to_utm($ellipsoid, $latitude, $longitude);
    is($z, $zone, "zone $.");
    fleq($e, $easting, "easting $.");
    fleq($n, $northing, "northing $.");

    my ($lat, $lon) = utm_to_latlon($ellipsoid, $z, $easting, $northing);
    fleq($lon, $longitude, "longitude $.");
    fleq($lat, $latitude, "latitude $.");

    my ($zone_number, $zone_letter) = $zone =~ /^(\d+)(\w)/;
    ($z, $e, $n) = latlon_to_utm_force_zone($ellipsoid, $zone_number, $latitude, $longitude);
    is($z, $zone, "fz zone $.");
    fleq($e, $easting, "fz easting $.");
    fleq($n, $northing, "fz northing $.");

    ($lat, $lon) = utm_to_latlon($ellipsoid, $z, $e, $n);
    fleq($lat, $latitude, "reverse latitude $.");
    fleq($lon, $longitude, "reverse longitude $.");

    for my $z1 ($zone_number - 1 .. $zone_number + 1) {
	my $z1 = $zone_number + int(-2 + rand 5);
	$z1 -= 60 if $z1 > 60;
	$z1 += 60 if $z1 < 1;
	# $z1 = 60 if $z1 > 60;
	# $z1 = 1 if $z1 < 1;
	for my $l1 (($latlon =~ /(.?)($zone_letter)(.?)/), '') {
	    ($z, $e, $n) = latlon_to_utm_force_zone($ellipsoid, "$z1$l1", $latitude, $longitude);
	    ($lat, $lon) = utm_to_latlon($ellipsoid, $z, $e, $n);
	    fleq($lon, $longitude, "fz longitude (zone $zone) $.");
	    fleq($lat, $latitude, "fz latitude (zone $zone) $.");
	}
    }
}

