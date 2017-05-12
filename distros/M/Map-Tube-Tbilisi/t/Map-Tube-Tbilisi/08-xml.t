# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Tbilisi;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Tbilisi->new;
my $ret = $map->xml;
like($ret, qr{tbilisi-map\.xml$}, 'Get XML file.');
