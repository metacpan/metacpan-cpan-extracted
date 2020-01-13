use strict;
use warnings;

use Map::Tube::Bucharest;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Bucharest->new;
my $ret = $map->xml;
like($ret, qr{bucharest-map\.xml$}, 'Get XML file.');
