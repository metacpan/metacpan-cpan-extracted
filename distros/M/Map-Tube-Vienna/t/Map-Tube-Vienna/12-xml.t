use strict;
use warnings;

use Map::Tube::Vienna;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Vienna->new;
my $ret = $map->xml;
like($ret, qr{vienna-map\.xml$}, 'Get XML file.');
