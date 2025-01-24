use strict;
use warnings;

use Map::Tube::Samara;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Samara->new;
my $ret = $map->xml;
like($ret, qr{samara-map\.xml$}, 'Get XML file.');
