use strict;
use warnings;

use Map::Tube::Moscow;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Moscow->new;
my $ret = $map->xml;
like($ret, qr{moscow-map\.xml$}, 'Get XML file.');
