use strict;
use warnings;

use Encode qw(decode_utf8);
use Map::Tube::Moscow;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $metro = Map::Tube::Moscow->new;
my $ret = $metro->name;
is($ret, decode_utf8('Московский метрополитен'), 'Get metro name.');
