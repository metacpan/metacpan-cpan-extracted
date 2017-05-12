# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Nanjing;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Nanjing->new;
my $ret = $map->xml;
like($ret, qr{nanjing-map\.xml$}, 'Get XML file.');
