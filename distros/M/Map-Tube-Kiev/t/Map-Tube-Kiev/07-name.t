use strict;
use warnings;

use Encode qw(decode_utf8);
use Map::Tube::Kiev;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $metro = Map::Tube::Kiev->new;
my $ret = $metro->name;
is($ret, decode_utf8('Київський метрополітен'), 'Get metro name.');
