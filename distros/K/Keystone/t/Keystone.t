use strict;
use warnings;

use Test::More tests => 3;

BEGIN { use_ok('Keystone', ':all'); }

ok(join('.',Keystone::version()) eq '0.9');

ok(Keystone::arch_supported(KS_ARCH_X86));
