use strict;
use warnings;
use Math::FakeFloat16 qw(:all);

use Test::More;

for(3e-8, 4e-8, 5e-8, 6e-8, 7e-8) {
   cmp_ok(Math::FakeFloat16->new(8e-8), '==', Math::FakeFloat16->new($_), "8e-8== $_ (NV)");
   cmp_ok(Math::FakeFloat16->new(8e-8), '==', Math::FakeFloat16->new(Math::MPFR->new($_)), "8e-8 == $_ (MPFR from NV)");
   cmp_ok(Math::FakeFloat16->new(2e-8 ), '!=', Math::FakeFloat16->new($_), "2e-8 != $_ (NV)");
   cmp_ok(Math::FakeFloat16->new(2e-8 ), '!=', Math::FakeFloat16->new(Math::MPFR->new($_)), "2e-8 != $_ (MPFR from NV)");
}

for ('3e-8', '4e-8', '5e-8', '6e-8', '7e-8') {
   cmp_ok(Math::FakeFloat16->new(8e-8), '==', Math::FakeFloat16->new($_), "8e-8 == $_ (PV)");
   cmp_ok(Math::FakeFloat16->new(8e-8), '==', Math::FakeFloat16->new(Math::MPFR->new($_)), "8e-8 == $_ (MPFR from PV)");
   cmp_ok(Math::FakeFloat16->new(2e-8 ), '!=', Math::FakeFloat16->new($_), "2e-8 != $_ (PV)");
   cmp_ok(Math::FakeFloat16->new(2e-8 ), '!=', Math::FakeFloat16->new(Math::MPFR->new($_)), "2e-8 != $_ (MPFR from PV)");
}

cmp_ok(Math::FakeFloat16->new(2e-8), '==', 0, '2e-8 is zero');

done_testing();
