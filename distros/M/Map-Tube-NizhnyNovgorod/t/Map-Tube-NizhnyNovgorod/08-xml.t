# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::NizhnyNovgorod;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::NizhnyNovgorod->new;
my $ret = $map->xml;
like($ret, qr{nizhny_novgorod-map\.xml$}, 'Get XML file.');
