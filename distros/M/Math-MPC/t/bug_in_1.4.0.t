# This script checks that the workaround for the division bug in mpc-1.4.0 at
# https://sympa.inria.fr/sympa/arc/mpc-discuss/2026-03/msg00019.html
# is working as intended - irrespective of mpc version.

use strict;
use warnings;
use Config;
use Math::MPC qw(:mpc);

use Test::More;

#my $prec_op = 234;
#my $prec_rop = 99;
#my $mpc_prec_default = 160;
#my $mpfr_prec_default = 64;

for my $prec_op(11, 71, 134) {
  for my $prec_rop(5, 65, 129){
    for my $mpc_prec_default(53, 64, 113, 160){
      for my $mpfr_prec_default(3,60, 200) {


Rmpc_set_default_prec($mpc_prec_default);
Math::MPFR::Rmpfr_set_default_prec($mpfr_prec_default);

my $ok;
my $rop = Rmpc_init2($prec_rop);
my $op1 = Rmpc_init2($prec_op);
my $op2 = Rmpc_init2($prec_op);
my $op3 = Rmpc_init2($prec_op);
my $op4 = Rmpc_init2($prec_op);
my $op5 = Rmpc_init2($prec_op);
my $div = Rmpc_init2($prec_op);
my $fr = Math::MPFR::Rmpfr_init2($prec_op);

my $im = Math::MPFR->new();

Math::MPFR::Rmpfr_set_NV($fr, 5.6, 0); # MPFR_RNDN

#####################
#### Rmpc_ui_div ####
#####################

Rmpc_set_ui($op1, 5, MPC_RNDNN);
Rmpc_ui_div($rop, 1, $op1, MPC_RNDNN);

RMPC_IM($im, $rop);
cmp_ok("$im", 'eq', '-0', "Rmpc_ui_div: imaginary component of rop is -0");

my $p = Rmpc_get_prec($rop);
cmp_ok($p, '==', $prec_rop, "Rmpc_ui_div: rop precision is ok");
cmp_ok(Math::MPFR::Rmpfr_get_default_prec(), '==', $mpfr_prec_default, "Rmpc_ui_div: MPFR default prec is $mpfr_prec_default");

$p = Rmpc_get_default_prec();
cmp_ok($p, '==', $mpc_prec_default, "MPC default precision is unaltered");

if($Config{nvsize} == 8) {
  ####################
  #### Rmpc_d_div ####
  ####################
  Rmpc_set_ui($op2, 5, MPC_RNDNN);
  Rmpc_d_div($rop, 1.0, $op2, MPC_RNDNN);

RMPC_IM($im, $rop);
cmp_ok("$im", 'eq', '-0', "Rmpc_d_div: imaginary component of rop is -0");

  $p = Rmpc_get_prec($rop);
  cmp_ok($p, '==', $prec_rop, "Rmpc_d_div: rop precision is ok");
  cmp_ok(Math::MPFR::Rmpfr_get_default_prec(), '==', $mpfr_prec_default, "Rmpc_d_div: MPFR default prec is $mpfr_prec_default");

  $p = Rmpc_get_default_prec();
  cmp_ok($p, '==', $mpc_prec_default, "MPC default precision is unaltered");
}
elsif($Config{nvtype} eq 'long double') {
  #####################
  #### Rmpc_ld_div ####
  #####################
  Rmpc_set_ui($op2, 5, MPC_RNDNN);
  Rmpc_ld_div($rop, 1.0, $op2, MPC_RNDNN);

  RMPC_IM($im, $rop);
  cmp_ok("$im", 'eq', '-0', "Rmpc_ld_div: imaginary component of rop is -0");

  $p = Rmpc_get_prec($rop);
  cmp_ok($p, '==', $prec_rop, "Rmpc_ld_div: rop precision is ok");
  cmp_ok(Math::MPFR::Rmpfr_get_default_prec(), '==', $mpfr_prec_default, "Rmpc_ld_div: MPFR default prec is $mpfr_prec_default");

  $p = Rmpc_get_default_prec();
  cmp_ok($p, '==', $mpc_prec_default, "MPC default precision is unaltered");
}

#####################
#### Rmpc_fr_div ####
#####################

Rmpc_set_ui($op3, 5, MPC_RNDNN);
Rmpc_fr_div($rop, Math::MPFR->new(1), $op3, MPC_RNDNN);

RMPC_IM($im, $rop);
cmp_ok("$im", 'eq', '-0', "Rmpc_fr_div: imaginary component of rop is -0");

$p = Rmpc_get_prec($rop);
cmp_ok($p, '==', $prec_rop, "Rmpc_fr_div: rop precision is ok");
cmp_ok(Math::MPFR::Rmpfr_get_default_prec(), '==', $mpfr_prec_default, "Rmpc_fr_div: MPFR default prec is $mpfr_prec_default");

$p = Rmpc_get_default_prec();
cmp_ok($p, '==', $mpc_prec_default, "MPC default precision is unaltered");

my $dummy_rop = Rmpc_init2(20);
eval { Rmpc_sj_div($dummy_rop, 1, $op3, MPC_RNDNN);};
unless($@) {
  #####################
  #### Rmpc_sj_div ####
  #####################
  Rmpc_set_ui($op4, 5, MPC_RNDNN);
  Rmpc_sj_div($rop, 1, $op4, MPC_RNDNN);

RMPC_IM($im, $rop);
cmp_ok("$im", 'eq', '-0', "Rmpc_sj_div: imaginary component of rop is -0");

  $p = Rmpc_get_prec($rop);
  cmp_ok($p, '==', $prec_rop, "Rmpc_sj_div: rop precision is ok");
  cmp_ok(Math::MPFR::Rmpfr_get_default_prec(), '==', $mpfr_prec_default, "Rmpc_sj_div: MPFR default prec is $mpfr_prec_default");

  $p = Rmpc_get_default_prec();
  cmp_ok($p, '==', $mpc_prec_default, "MPC default precision is unaltered");
}

##################
#### Rmpc_div ####
##################
Rmpc_set_ui($op5, 5, MPC_RNDNN);
Rmpc_set_ui($div, 3, MPC_RNDNN);
Rmpc_div($rop, $div, $op5, MPC_RNDNN);

RMPC_IM($im, $rop);
cmp_ok("$im", 'eq', '0', "Rmpc_div: imaginary component of rop is 0");

$p = Rmpc_get_prec($rop);
cmp_ok($p, '==', $prec_rop, "Rmpc_div: rop precision is ok");
cmp_ok(Math::MPFR::Rmpfr_get_default_prec(), '==', $mpfr_prec_default, "Rmpc_div: MPFR default prec is $mpfr_prec_default");

$p = Rmpc_get_default_prec();
cmp_ok($p, '==', $mpc_prec_default, "MPC default precision is unaltered");

##########################################
##########################################

{
  ##### TRIZEN ui_div #####
  my $PREC = $mpc_prec_default;
  my $ROUND = MPC_RNDNN;

  my $y = Math::MPC::Rmpc_init2($PREC);
  Math::MPC::Rmpc_set_ui($y, 5, $ROUND);
  Math::MPC::Rmpc_atanh($y, $y, $ROUND);
  Math::MPC::Rmpc_tanh($y, $y, $ROUND);

  my $x = Math::MPC::Rmpc_init2($PREC);
  Math::MPC::Rmpc_set_ui($x, 5, $ROUND);

  Math::MPC::Rmpc_ui_div($x, 1, $x, $ROUND);
  RMPC_IM($im, $x);
  cmp_ok("$im", 'eq', '-0', "T1: Rmpc_ui_div: imaginary component of rop is -0");

  Math::MPC::Rmpc_ui_div($x, 1, $x, $ROUND);
  RMPC_IM($im, $x);
  cmp_ok("$im", 'eq', '0', "T2: Rmpc_ui_div: imaginary component of rop is 0");

  Math::MPC::Rmpc_atanh($x, $x, $ROUND);
  Math::MPC::Rmpc_tanh($x, $x, $ROUND);

  $ok = 0;
  if($y == $x) { $ok = 1 }
  else { warn "$x and $y differ\n" }
  cmp_ok($ok, '==', 1, "Rmpc_ui_div passes");
  cmp_ok(Math::MPFR::Rmpfr_get_default_prec(), '==', $mpfr_prec_default, "Rmpc_ui_div prec ok");
}

{
  ##### TRIZEN fr_div #####
  my $PREC = $mpc_prec_default;
  my $ROUND = MPC_RNDNN;

  my $y = Math::MPC::Rmpc_init2($PREC);
  Math::MPC::Rmpc_set_ui($y, 5, $ROUND);
  Math::MPC::Rmpc_atanh($y, $y, $ROUND);
  Math::MPC::Rmpc_tanh($y, $y, $ROUND);

  my $x = Math::MPC::Rmpc_init2($PREC);
  Math::MPC::Rmpc_set_ui($x, 5, $ROUND);

  Math::MPC::Rmpc_fr_div($x, Math::MPFR->new(1), $x, $ROUND);
  RMPC_IM($im, $x);
  cmp_ok("$im", 'eq', '-0', "T1: Rmpc_fr_div: imaginary component of rop is -0");

  Math::MPC::Rmpc_fr_div($x, Math::MPFR->new(1), $x, $ROUND);
  RMPC_IM($im, $x);
  cmp_ok("$im", 'eq', '0', "T2: Rmpc_fr_div: imaginary component of rop is 0");

  Math::MPC::Rmpc_atanh($x, $x, $ROUND);
  Math::MPC::Rmpc_tanh($x, $x, $ROUND);

  $ok = 0;
  if($y == $x) { $ok = 1 }
  else { warn "$x and $y differ\n" }
  cmp_ok($ok, '==', 1, "Rmpc_fr_div passes");
  cmp_ok(Math::MPFR::Rmpfr_get_default_prec(), '==', $mpfr_prec_default, "Rmpc_fr_div prec ok");
}

eval { Rmpc_sj_div($op3, 1, $op3, MPC_RNDNN);};
unless($@) {
  ##### TRIZEN sj_div #####
  my $PREC = $mpc_prec_default;
  my $ROUND = MPC_RNDNN;

  my $y = Math::MPC::Rmpc_init2($PREC);
  Math::MPC::Rmpc_set_ui($y, 5, $ROUND);
  Math::MPC::Rmpc_atanh($y, $y, $ROUND);
  Math::MPC::Rmpc_tanh($y, $y, $ROUND);

  my $x = Math::MPC::Rmpc_init2($PREC);
  Math::MPC::Rmpc_set_ui($x, 5, $ROUND);
  Math::MPC::Rmpc_sj_div($x, 1, $x, $ROUND);
  RMPC_IM($im, $x);
  cmp_ok("$im", 'eq', '-0', "T1: Rmpc_sj_div: imaginary component of rop is -0");

  Math::MPC::Rmpc_sj_div($x, 1, $x, $ROUND);
  RMPC_IM($im, $x);
  cmp_ok("$im", 'eq', '0', "T2: Rmpc_sj_div: imaginary component of rop is 0");

  Math::MPC::Rmpc_atanh($x, $x, $ROUND);
  Math::MPC::Rmpc_tanh($x, $x, $ROUND);

  $ok = 0;
  if($y == $x) { $ok = 1 }
  else { warn "$x and $y differ\n" }
  cmp_ok($ok, '==', 1, "Rmpc_sj_div passes");
  cmp_ok(Math::MPFR::Rmpfr_get_default_prec(), '==', $mpfr_prec_default, "Rmpc_sj_div prec ok");
}

if($Config{nvsize} == 8) {
  ##### TRIZEN d_div #####
  my $PREC = $mpc_prec_default;
  my $ROUND = MPC_RNDNN;

  my $y = Math::MPC::Rmpc_init2($PREC);
  Math::MPC::Rmpc_set_ui($y, 5, $ROUND);
  Math::MPC::Rmpc_atanh($y, $y, $ROUND);
  Math::MPC::Rmpc_tanh($y, $y, $ROUND);

  my $x = Math::MPC::Rmpc_init2($PREC);
  Math::MPC::Rmpc_set_ui($x, 5, $ROUND);
  Math::MPC::Rmpc_d_div($x, 1.0, $x, $ROUND);
  RMPC_IM($im, $x);
  cmp_ok("$im", 'eq', '-0', "T1: Rmpc_d_div: imaginary component of rop is -0");

  Math::MPC::Rmpc_d_div($x, 1.0, $x, $ROUND);
  RMPC_IM($im, $x);
  cmp_ok("$im", 'eq', '0', "T2: Rmpc_d_div: imaginary component of rop is 0");

  Math::MPC::Rmpc_atanh($x, $x, $ROUND);
  Math::MPC::Rmpc_tanh($x, $x, $ROUND);

  $ok = 0;
  if($y == $x) { $ok = 1 }
  else { warn "$x and $y differ\n" }
  cmp_ok($ok, '==', 1, "Rmpc_d_div passes");
  cmp_ok(Math::MPFR::Rmpfr_get_default_prec(), '==', $mpfr_prec_default, "Rmpc_d_div prec ok");
}

elsif($Config{nvtype} eq 'long double') {
  ##### TRIZEN ld_div #####
  my $PREC = $mpc_prec_default;
  my $ROUND = MPC_RNDNN;

  my $y = Math::MPC::Rmpc_init2($PREC);
  Math::MPC::Rmpc_set_ui($y, 5, $ROUND);
  Math::MPC::Rmpc_atanh($y, $y, $ROUND);
  Math::MPC::Rmpc_tanh($y, $y, $ROUND);

  my $x = Math::MPC::Rmpc_init2($PREC);
  Math::MPC::Rmpc_set_ui($x, 5, $ROUND);
  Math::MPC::Rmpc_ld_div($x, 1.0, $x, $ROUND);
  RMPC_IM($im, $x);
  cmp_ok("$im", 'eq', '-0', "T1: Rmpc_ld_div: imaginary component of rop is -0");

  Math::MPC::Rmpc_ld_div($x, 1.0, $x, $ROUND);
  RMPC_IM($im, $x);
  cmp_ok("$im", 'eq', '0', "T2: Rmpc_ld_div: imaginary component of rop is 0");

  Math::MPC::Rmpc_atanh($x, $x, $ROUND);
  Math::MPC::Rmpc_tanh($x, $x, $ROUND);

  $ok = 0;
  if($y == $x) { $ok = 1 }
  else { warn "$x and $y differ\n" }
  cmp_ok($ok, '==', 1, "Rmpc_ld_div passes");
  cmp_ok(Math::MPFR::Rmpfr_get_default_prec(), '==', $mpfr_prec_default, "Rmpc_ld_div prec ok");
}

{
  ##### TRIZEN div #####
  my $PREC = $mpc_prec_default;
  my $ROUND = MPC_RNDNN;

  my $y = Math::MPC::Rmpc_init2($PREC);
  Math::MPC::Rmpc_set_ui($y, 5, $ROUND);
  Math::MPC::Rmpc_atanh($y, $y, $ROUND);
  Math::MPC::Rmpc_tanh($y, $y, $ROUND);

  my $x = Math::MPC::Rmpc_init2($PREC);
  Math::MPC::Rmpc_set_ui($x, 5, $ROUND);
  Math::MPC::Rmpc_div($x, Math::MPC->new(1), $x, $ROUND);
  RMPC_IM($im, $x);
  cmp_ok("$im", 'eq', '0', "T1: Rmpc_div: imaginary component of rop is 0");

  Math::MPC::Rmpc_div($x, Math::MPC->new(1), $x, $ROUND);
  RMPC_IM($im, $x);
  cmp_ok("$im", 'eq', '0', "T2: Rmpc_div: imaginary component of rop is 0");

  Math::MPC::Rmpc_atanh($x, $x, $ROUND);
  Math::MPC::Rmpc_tanh($x, $x, $ROUND);

  $ok = 0;
  if($y == $x) { $ok = 1 }
  else { warn "$x and $y differ\n" }
  cmp_ok($ok, '==', 1, "Rmpc_div passes");
  cmp_ok(Math::MPFR::Rmpfr_get_default_prec(), '==', $mpfr_prec_default, "Rmpc_div prec ok");
}

######################################################
######################################################
######################################################
######################################################

### Overloading of Division

{
  ##### overloaded iv div #####
  my $op = Rmpc_init2($prec_op);
  Rmpc_set_ui($op, 5, MPC_RNDNN);
  my $rop = 1 / $op;

  RMPC_IM($im, $rop);
  cmp_ok("$im", 'eq', '-0', "$prec_op: overloaded integer div: imaginary component of rop is -0");

  $p = Rmpc_get_prec($op);
  cmp_ok($p, '==', $prec_op, "OP: overloaded integer div: precision is ok");

  my $p = Rmpc_get_prec($rop);
  cmp_ok($p, '==', $mpc_prec_default, "ROP: overloaded integer div: precision is ok");

  cmp_ok(Math::MPFR::Rmpfr_get_default_prec(), '==', $mpfr_prec_default, "overloaded integer div: MPFR default prec is $mpfr_prec_default");
}

{
  ##### overloaded nv div #####
  my $op = Rmpc_init2($prec_op);
  Rmpc_set_ui($op, 5, MPC_RNDNN);
  my $rop = 1.2 / $op;

  RMPC_IM($im, $rop);
  cmp_ok("$im", 'eq', '-0', "overloaded nv div: imaginary component of rop is -0");

  my $p = Rmpc_get_prec($op);
  cmp_ok($p, '==', $prec_op, "OP: overloaded nv div: precision is ok");

  $p = Rmpc_get_prec($rop);
  cmp_ok($p, '==', $mpc_prec_default, "ROP: overloaded nv div: precision is ok");

  cmp_ok(Math::MPFR::Rmpfr_get_default_prec(), '==', $mpfr_prec_default, "overloaded nv div: MPFR default prec is $mpfr_prec_default");
}

{
  ##### overloaded fr div #####
  if($Math::MPFR::VERSION >= 4.47) { # Overloading in earlier versions of Math::MPFR
                                     # does not cater for Math::MPC objects.
    my $op = Rmpc_init2($prec_op);
    Rmpc_set_ui($op, 5, MPC_RNDNN);
    my $rop = Math::MPFR->new(1) / $op;

  RMPC_IM($im, $rop);
  cmp_ok("$im", 'eq', '-0', "overloaded fr div: imaginary component of rop is -0");

    my $p = Rmpc_get_prec($op);
    cmp_ok($p, '==', $prec_op, "OP: overloaded fr div: precision is ok");

    $p = Rmpc_get_prec($rop);
    cmp_ok($p, '==', $mpc_prec_default, "ROP: overloaded fr div: precision is ok");

    cmp_ok(Math::MPFR::Rmpfr_get_default_prec(), '==', $mpfr_prec_default, "overloaded fr div: MPFR default prec is $mpfr_prec_default");
  }
}

{
  ##### overloaded iv string div #####
  my $op = Rmpc_init2($prec_op);
  Rmpc_set_ui($op, 5, MPC_RNDNN);
  my $rop = "1" / $op;

  # "1"/$rop is not the same as 1/$rop. See OPERATOR OVERLOADING documentation.
  RMPC_IM($im, $rop);
  cmp_ok("$im", 'eq', '0', "overloaded intstr div: imaginary component of rop is 0");

  my $p = Rmpc_get_prec($op);
  cmp_ok($p, '==', $prec_op, "OP: overloaded intstr div: precision is ok");

  $p = Rmpc_get_re_prec($rop);
  cmp_ok($p, '==', $mpc_prec_default, "ROP: overloaded intstr  div: precision is ok");

  cmp_ok(Math::MPFR::Rmpfr_get_default_prec(), '==', $mpfr_prec_default, "overloaded intstr div: MPFR default prec is $mpfr_prec_default"); # Should be unaltered
}

{
  ### overloaded nv string div ###
  my $op = Rmpc_init2($prec_op);
  Rmpc_set_ui($op, 5, MPC_RNDNN);
  my $rop = "1.3" / $op;

  # "1.3"/$rop is not the same as 1.3/$rop. See OPERATOR OVERLOADING documentation.
  RMPC_IM($im, $rop);
  cmp_ok("$im", 'eq', '0', "overloaded nvstr div: imaginary component of rop is 0");

  my $p = Rmpc_get_prec($op);
  cmp_ok($p, '==', $prec_op, "OP: overloaded nvstr div: precision is ok");

  $p = Rmpc_get_prec($rop);
  cmp_ok($p, '==', $mpc_prec_default, "ROP: overloaded nvstr div: precision is ok");

  cmp_ok(Math::MPFR::Rmpfr_get_default_prec(), '==', $mpfr_prec_default, "overloaded nvstr div: MPFR default prec is $mpfr_prec_default");
}

{
  ##### Overloaded fr div with Non-Zero imag #####
  if($Math::MPFR::VERSION >= 4.47) { # Overloading in earlier versions of Math::MPFR
                                     # does not cater for Math::MPC objects.
    my $op = Rmpc_init2($prec_op);
    Rmpc_set_ui_ui($op, 5, 1, MPC_RNDNN);
    $rop = Math::MPFR->new(1) / $op;

    my $p = Rmpc_get_prec($op);
    cmp_ok($p, '==', $prec_op, "OP: fr div overload with non-zero im: precision is ok");

    $p = Rmpc_get_re_prec($rop);
    cmp_ok($p, '==', $mpc_prec_default, "ROP: fr div overload with non-zero im: precision is ok");

    cmp_ok(Math::MPFR::Rmpfr_get_default_prec(), '==', $mpfr_prec_default, "fr div overload with non-zero im: MPFR default prec is $mpfr_prec_default");
  }
}

# Closing brackets:
}}}}


done_testing();

#################################



