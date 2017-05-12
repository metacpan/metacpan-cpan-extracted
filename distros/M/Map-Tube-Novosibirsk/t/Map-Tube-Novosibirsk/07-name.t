# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8);
use Map::Tube::Novosibirsk;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $metro = Map::Tube::Novosibirsk->new;
my $ret = $metro->name;
is($ret, decode_utf8('Новосибирский метрополитен'), 'Get metro name.');
