use strict;
use warnings;

use Encode qw(decode_utf8);
use Map::Tube::Samara;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $metro = Map::Tube::Samara->new;
my $ret = $metro->name;
is($ret, decode_utf8('Самарский метрополитен'), 'Get metro name.');
