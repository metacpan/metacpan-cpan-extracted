# Test "rounding away from zero", which is
# available only with mpc-1.3.0 and later.

use strict;
use warnings;
use Math::MPC qw(:mpc);

use Test::More;

my @new_modes = (MPC_RNDNA, MPC_RNDAN, MPC_RNDAZ, MPC_RNDZA,
                 MPC_RNDAD, MPC_RNDDA, MPC_RNDUA, MPC_RNDAU,
                 MPC_RNDAA);

my @old_modes = (MPC_RNDNN, MPC_RNDND, MPC_RNDNU, MPC_RNDNZ,
                 MPC_RNDDN, MPC_RNDUN, MPC_RNDZN, MPC_RNDDD,
                 MPC_RNDDU, MPC_RNDDZ, MPC_RNDZD, MPC_RNDUD,
                 MPC_RNDUU, MPC_RNDUZ, MPC_RNDZU, MPC_RNDZZ);

if(MPC_VERSION() < 66304) {
# Rounding away from zero is unavailable
  for(@new_modes) {
    eval{Rmpc_set_default_rounding_mode($_);};
    like($@, qr/^Illegal rounding value/, "Rounding mode ($_) is rejected");
  }

  for(@old_modes) {
    Rmpc_set_default_rounding_mode($_);
    cmp_ok(Rmpc_get_default_rounding_mode(), '==', $_, "Rounding mode ($_) is applied");
  }

}
else {
  for(@old_modes, @new_modes) {
    Rmpc_set_default_rounding_mode($_);
    cmp_ok(Rmpc_get_default_rounding_mode(), '==', $_, "Rounding mode ($_) is applied");
  }
}


done_testing();
