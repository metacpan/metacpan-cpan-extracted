# -*- cperl -*-

use Test::More tests => 6;

use Lingua::PT::ProperNames;

use locale;
use Data::Dumper;

my $dic = Lingua::PT::ProperNames->new;

isa_ok($dic, "Lingua::PT::ProperNames");

ok($dic->_exists("Alberto"));
ok($dic->_exists("Simões"));
ok(!$dic->_exists("cama"));

ok($dic->is_name("Maria"));
ok($dic->is_surname("Simões"));


# $a = 'à';
# SKIP: {
#   skip "not a good locale", 1 unless $a =~ m!^\w$!;


# }
