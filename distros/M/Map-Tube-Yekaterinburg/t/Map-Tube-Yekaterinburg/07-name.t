use strict;
use warnings;

use Encode qw(decode_utf8);
use Map::Tube::Yekaterinburg;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $metro = Map::Tube::Yekaterinburg->new;
my $ret = $metro->name;
is($ret, decode_utf8('Екатеринбургский метрополитен'), 'Get metro name.');
