use strict;
use warnings;

use Map::Tube::Prague;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Prague->new;
my $ret = $map->xml;
like($ret, qr{prague-map\.xml$}, 'Get XML file.');
