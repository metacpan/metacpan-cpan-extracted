#!/usr/bin/perl -w
#
#Convert V + H to latlong in perl
#
#Copyright (C) 2004 Paul Timmins, All rights reserved.
#This program is free software; you can redistribute it and/or
#modify it under the same terms as Perl itself.
#
#The coordinates given should correspond to PNTCMIMN, in Downtown Pontiac, MI, USA.
#

use strict;
use Geo::Coordinates::VandH;
my $lat;
my $lon;
my $vhobj = new Geo::Coordinates::VandH;
($lat,$lon) = $vhobj->vh2ll(5498,2895);
printf "%lf,%lf\n",$lat, $lon;

