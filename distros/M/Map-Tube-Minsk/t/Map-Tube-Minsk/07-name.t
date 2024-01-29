use strict;
use warnings;

use Encode qw(decode_utf8);
use Map::Tube::Minsk;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $metro = Map::Tube::Minsk->new;
my $ret = $metro->name;
is($ret, decode_utf8('Мінскі метрапалітэн'), 'Get metro name.');
