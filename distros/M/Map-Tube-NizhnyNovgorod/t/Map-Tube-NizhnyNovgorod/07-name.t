use strict;
use warnings;

use Encode qw(decode_utf8);
use Map::Tube::NizhnyNovgorod;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $metro = Map::Tube::NizhnyNovgorod->new;
my $ret = $metro->name;
is($ret, decode_utf8('Нижегородский метрополитен'), 'Get metro name.');
