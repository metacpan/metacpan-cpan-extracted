use strict;
use warnings;

use Map::Tube::Malaga;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Malaga->new;
my $ret = $map->xml;
like($ret, qr{malaga-map\.xml$}, 'Get XML file.');
