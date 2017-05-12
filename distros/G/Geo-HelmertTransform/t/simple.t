#!/usr/bin/env perl
#
# simple.t:
# Tests for Geo::HelmertTransform.
#
# $Id: simple.t,v 1.3 2011-08-10 09:50:43 evdb Exp $
#

use strict;
use warnings;
use lib 'lib';
use Test::More tests => 4;
use_ok('Geo::HelmertTransform');

#
# This just tests that we can translate a point on the equator in the Airy1830
# datum into WGS84 (not something you'd ever want to do, mind). Should perhaps
# extend with the examples from OS's "Coordinate Systems in Great Britain"
# technical report.
#

my ($lat, $lon, $h) = (0, 0, 0);
my $airy1830 = Geo::HelmertTransform::datum('Airy1830');
my $wgs84    = Geo::HelmertTransform::datum('WGS84');

($lat, $lon, $h)
    = Geo::HelmertTransform::convert_datum($airy1830, $wgs84, $lat, $lon, $h);

# Use like to get a consistent result across different architectures.
# 7 decimal points should be plenty
like( $lat,    qr/^0\.0048009\d*$/);
like( $lon,   qr/^-0\.0008904\d*$/);
like( $h,   qr/^-257\.8054366\d*$/);

