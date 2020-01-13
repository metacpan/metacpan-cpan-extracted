use strict;
use warnings;

use Encode qw(decode_utf8);
use Map::Tube::Bucharest;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $metro = Map::Tube::Bucharest->new;
my $ret = $metro->name;
is($ret, decode_utf8('Metroul din București'), 'Get metro name.');
