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
use lib q{lib};
use lib q{../lib};
use constant NEAR_DEFAULT => 7;

sub near {
  my $x=shift();
  my $y=shift();
  my $p=shift()||NEAR_DEFAULT;
  if (($x-$y)/$y < 10**-$p) {
    return 1;
  } else {
    return 0;
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

BEGIN { plan tests => 3 }

# just check that all modules can be compiled
ok(eval {require GPS::SpaceTrack; 1}, 1, $@);

my $filename="";
$filename="../doc/gps.tle" if -r "../doc/gps.tle";
$filename="./doc/gps.tle" if -r "./doc/gps.tle";

use GPS::SpaceTrack;
my $obj = GPS::SpaceTrack->new(filename=>$filename);
ok(ref $obj, "GPS::SpaceTrack");
my $p1={lat=>38.870997, lon=>-77.05596, alt=>13};
my $list=$obj->getsatellitelist($p1);
ok(ref($list), "ARRAY");
#foreach(@$list) { 
#  ok(1,1); #this test depends on GPS::PRN and the gps.tle file
#}
