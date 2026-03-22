# Basic tests for newly added Rmpc_exp10, Rmpc_exp2 and Rmpc_log2.
use strict;
use warnings;
use Math::MPC qw(:mpc);

use Test::More;

my $op = Math::MPC->new(5);
my $rop = Math::MPC->new();

if(66306 <= MPC_VERSION) {

  Rmpc_exp10($rop, $op, MPC_RNDNN);
  cmp_ok($rop, '==', Math::MPC->new(10 ** 5), 'Rmpc_exp10 functioned correctly');

  Rmpc_log10($rop, $rop, MPC_RNDNN);
  cmp_ok($rop, '==', $op, 'Rmpc_log10 functioned correctly');

  Rmpc_exp2($rop, $op, MPC_RNDNN);
  cmp_ok($rop, '==', Math::MPC->new(2 ** 5), 'Rmpc_exp2 functioned correctly');

  Rmpc_log2($rop, $rop, MPC_RNDNN);
  cmp_ok($rop, '==', $op, 'Rmpc_log2 functioned correctly');
}
else {

  eval { Rmpc_exp10($rop, $op, MPC_RNDNN);};
  like($@, qr/^Rmpc_exp10 function requires mpc version 1.3.2/, 'Rmpc_exp10 croaks as expected');

  eval { Rmpc_exp2($rop, $op, MPC_RNDNN);};
  like($@, qr/^Rmpc_exp2 function requires mpc version 1.3.2/, 'Rmpc_exp2 croaks as expected');

  eval { Rmpc_log2($rop, $op, MPC_RNDNN);};
  like($@, qr/^Rmpc_log2 function requires mpc version 1.3.2/, 'Rmpc_log2 croaks as expected');
}

done_testing();
