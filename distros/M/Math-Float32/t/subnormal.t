use strict;
use warnings;
use Math::Float32 qw(:all);

use Test::More;


for(8e-46, 9e-46, 19e-46, 20e-46, 21e-46) {
   cmp_ok($Math::Float32::flt_DENORM_MIN, '==', Math::Float32->new($_), "1.40129846e-45 == $_ (NV)");
   cmp_ok(Math::Float32->new(7e-46 ), '!=', Math::Float32->new($_), "7e-46 != $_ (NV)");
}

for ('8e-46', '9e-46', '19e-46', '20e-46', '21e-46') {
   cmp_ok($Math::Float32::flt_DENORM_MIN, '==', Math::Float32->new($_), "1.40129846e-45 == $_ (PV)");
   cmp_ok(Math::Float32->new(7e-46 ), '!=', Math::Float32->new($_), "7e-46 != $_ (PV)");
}

cmp_ok(Math::Float32->new(7e-46), '==', 0, '7e-41 is zero');


done_testing();
