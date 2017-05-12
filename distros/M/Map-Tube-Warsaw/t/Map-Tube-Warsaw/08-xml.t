# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Warsaw;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Warsaw->new;
my $ret = $map->xml;
like($ret, qr{warsaw-map\.xml$}, 'Get XML file.');
