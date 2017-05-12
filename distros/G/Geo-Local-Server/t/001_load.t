# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 8;

BEGIN { use_ok( 'Geo::Local::Server' ); }

my $gls = Geo::Local::Server->new;
isa_ok ($gls, 'Geo::Local::Server');
can_ok($gls, qw{new initialize});
can_ok($gls, qw{ci});
can_ok($gls, qw{configfile envname});
can_ok($gls, qw{lonlathae});
can_ok($gls, qw{lat lon hae});
can_ok($gls, qw{latlon latlong});

