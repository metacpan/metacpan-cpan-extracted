use strict;
use warnings;

use Encode qw(decode_utf8);
use Map::Tube::Dnipropetrovsk;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $metro = Map::Tube::Dnipropetrovsk->new;
my $ret = $metro->name;
is($ret, decode_utf8('Дніпропетровський метрополітен'), 'Get metro name.');
