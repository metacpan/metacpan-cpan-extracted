# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Novosibirsk;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Novosibirsk->new;
my $ret = $map->xml;
like($ret, qr{novosibirsk-map\.xml$}, 'Get XML file.');
