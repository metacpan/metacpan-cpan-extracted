# -*- cperl -*-

use Test::More tests => 2;

BEGIN {
  use_ok( 'Lingua::PT::Abbrev' );
}

my $dic = Lingua::PT::Abbrev->new;

isa_ok($dic, "Lingua::PT::Abbrev");


