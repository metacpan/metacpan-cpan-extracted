use strict;
use warnings;

use Encode qw(decode_utf8);
use Map::Tube::SaintPetersburg;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $metro = Map::Tube::SaintPetersburg->new;
my $ret = $metro->name;
is($ret, decode_utf8('Петербургский метрополитен'), 'Get metro name.');
