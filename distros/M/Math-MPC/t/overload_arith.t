# Here we test that the overloaded arithmetic operators
# return the same as their respective functions.

use strict;
use warnings;
use Math::MPC qw(:mpc);

use Test::More;

my $rop1 = Math::MPC->new();
my $rop2 = Math::MPC->new();
my $op_neg = Math::MPC->new();
my $fr1 = Math::MPFR->new();
my $fr2 = Math::MPFR->new();

my $allow_mpfr_overloading = 0;
$allow_mpfr_overloading = 1 if $Math::MPFR::VERSION >= 4.47;

unless($allow_mpfr_overloading) {
  warn "\n Skipping tests involving overloading of Math::MPFR objects\n",
         " They require Math-MPFR-4.47 but we have only version $Math::MPFR::VERSION\n";
}

my @ops = (11, Math::MPFR->new(-11), Math::MPFR->new(11.5), Math::MPFR->new(-11.125),
            Math::MPC->new(5.5, 0), Math::MPC->new(5.625, -0.0), Math::MPC->new(0, 5.75), Math::MPC->new(-0.0, 5),
            Math::MPC->new(5.125, 2), Math::MPC->new(5.25, -2), Math::MPC->new(2, 5.375), Math::MPC->new(-2.375, 5));

our @negs = ();
for my $op(@ops) {
  if(ref($op) eq 'Math::MPC') {
    Rmpc_neg($op_neg, $op, MPC_RNDNN);
    push(@negs, get_copy($op_neg));
  }
}

for my $op1(@ops){
  for my $op2(@ops, @negs) {
    next unless ref($op2) eq 'Math::MPC';

    Rmpc_abs($fr1, $op2, MPC_RNDNN);
    $fr2 = abs($op2);
    cmp_ok("$fr1", 'eq', "$fr2", "abs($op2) consistent with Rmpc_abs()");

    Rmpc_sqrt($rop1, $op2, MPC_RNDNN);
    $rop2 = sqrt($op2);
    cmp_ok("$rop1", 'eq', "$rop2", "sqrt($op2) consistent with Rmpc_sqrt()");

    Rmpc_log($rop1, $op2, MPC_RNDNN);
    $rop2 = log($op2);
    cmp_ok("$rop1", 'eq', "$rop2", "log($op2) consistent with Rmpc_log()");

    Rmpc_exp($rop1, $op2, MPC_RNDNN);
    $rop2 = exp($op2);
    cmp_ok("$rop1", 'eq', "$rop2", "exp($op2) consistent with Rmpc_exp()");

    Rmpc_sin($rop1, $op2, MPC_RNDNN);
    $rop2 = sin($op2);
    cmp_ok("$rop1", 'eq', "$rop2", "sin($op2) consistent with Rmpc_sin()");

    Rmpc_cos($rop1, $op2, MPC_RNDNN);
    $rop2 = cos($op2);
    cmp_ok("$rop1", 'eq', "$rop2", "cos($op2) consistent with Rmpc_cos()");

  for my $operation('+', '-', '*', '/', '**') {

      next if(ref($op1) eq 'Math::MPFR' && !$allow_mpfr_overloading);

      if($operation eq '+') {
        $rop1 = $op2 + $op1;
        Rmpc_add_ui($rop2, $op2, $op1, MPC_RNDNN) if !ref($op1);
        Rmpc_add_fr($rop2, $op2, $op1, MPC_RNDNN) if ref($op1) eq 'Math::MPFR';
        Rmpc_add   ($rop2, $op2, $op1, MPC_RNDNN) if ref($op1) eq 'Math::MPC';
      }
      elsif($operation eq '-') {
        $rop1 = $op1 - $op2;
        Rmpc_ui_sub($rop2, $op1, $op2, MPC_RNDNN) if !ref($op1);
        Rmpc_fr_sub($rop2, $op1, $op2, MPC_RNDNN) if ref($op1) eq 'Math::MPFR';
        Rmpc_sub   ($rop2, $op1, $op2, MPC_RNDNN) if ref($op1) eq 'Math::MPC';
      }
      elsif($operation eq '*') {
        $rop1 = $op2 * $op1;
        Rmpc_mul_ui($rop2, $op2, $op1, MPC_RNDNN) if !ref($op1);
        Rmpc_mul_fr($rop2, $op2, $op1, MPC_RNDNN) if ref($op1) eq 'Math::MPFR';
        Rmpc_mul   ($rop2, $op2, $op1, MPC_RNDNN) if ref($op1) eq 'Math::MPC';
      }
      elsif($operation eq '/') {
        $rop1 = $op1 / $op2;
        Rmpc_ui_div($rop2, $op1, $op2, MPC_RNDNN) if !ref($op1);
        Rmpc_fr_div($rop2, $op1, $op2, MPC_RNDNN) if ref($op1) eq 'Math::MPFR';
        Rmpc_div   ($rop2, $op1, $op2, MPC_RNDNN) if ref($op1) eq 'Math::MPC';
        }
      elsif($operation eq '**') {
        $rop1 = $op2 ** $op1;
        Rmpc_pow_ui($rop2, $op2, $op1, MPC_RNDNN) if !ref($op1);
        Rmpc_pow_fr($rop2, $op2, $op1, MPC_RNDNN) if ref($op1) eq 'Math::MPFR';
        Rmpc_pow   ($rop2, $op2, $op1, MPC_RNDNN) if ref($op1) eq 'Math::MPC';
      }

      cmp_ok("$rop1", 'eq', "$rop2", "$op1 $operation $op2 ok");

      if($operation eq '-') {
        $rop1 = $op2 - $op1;
        Rmpc_sub_ui($rop2, $op2, $op1, MPC_RNDNN) if !ref($op1);
        Rmpc_sub_fr($rop2, $op2, $op1, MPC_RNDNN) if ref($op1) eq 'Math::MPFR';
        Rmpc_sub   ($rop2, $op2, $op1, MPC_RNDNN) if ref($op1) eq 'Math::MPC';
      }
      elsif($operation eq '/') {
        $rop1 = $op2 / $op1;
        Rmpc_div_ui($rop2, $op2, $op1, MPC_RNDNN) if !ref($op1);
        Rmpc_div_fr($rop2, $op2, $op1, MPC_RNDNN) if ref($op1) eq 'Math::MPFR';
        Rmpc_div   ($rop2, $op2, $op1, MPC_RNDNN) if ref($op1) eq 'Math::MPC';
      }

      cmp_ok("$rop1", 'eq', "$rop2", "$op2 $operation $op1 ok");
    }
  }
}

################################################################################
################################################################################

for my $op1(@ops){
  next if(ref($op1) eq 'Math::MPFR' && !$allow_mpfr_overloading);
  for my $op2(@ops, @negs) {
    next unless ref($op2) eq 'Math::MPC';

    my $cop1 = get_copy($op1);
    my $cop2 = get_copy($op2);

    Rmpc_add_ui($rop2, $cop2, $cop1, MPC_RNDNN) if !ref($op1);
    Rmpc_add_fr($rop2, $cop2, $cop1, MPC_RNDNN) if ref($op1) eq 'Math::MPFR';
    Rmpc_add   ($rop2, $cop2, $cop1, MPC_RNDNN) if ref($op1) eq 'Math::MPC';
        $cop1 += $cop2;

    cmp_ok("$cop1", 'eq', "$rop2", "$op1 += $op2 ok");
  }
}

################################################################################
################################################################################
################################################################################
################################################################################

for my $op1(@ops){
  next if(ref($op1) eq 'Math::MPFR' && !$allow_mpfr_overloading);
  for my $op2(@ops, @negs) {
    next unless ref($op2) eq 'Math::MPC';

    my $cop1 = get_copy($op1);
    my $cop2 = get_copy($op2);

    Rmpc_mul_ui($rop2, $cop2, $cop1, MPC_RNDNN) if !ref($op1);
    Rmpc_mul_fr($rop2, $cop2, $cop1, MPC_RNDNN) if ref($op1) eq 'Math::MPFR';
    Rmpc_mul   ($rop2, $cop2, $cop1, MPC_RNDNN) if ref($op1) eq 'Math::MPC';
        $cop1 *= $cop2;

    cmp_ok("$cop1", 'eq', "$rop2", "$op1 *= $op2 ok");
  }
}

################################################################################
################################################################################
################################################################################
################################################################################

for my $op1(@ops){
  next if(ref($op1) eq 'Math::MPFR' && !$allow_mpfr_overloading);
  for my $op2(@ops, @negs) {
    next unless ref($op2) eq 'Math::MPC';

    my $cop1 = get_copy($op1);
    my $cop2 = get_copy($op2);

    Rmpc_ui_sub($rop2, $cop1, $cop2, MPC_RNDNN) if !ref($op1);
    Rmpc_fr_sub($rop2, $cop1, $cop2, MPC_RNDNN) if ref($op1) eq 'Math::MPFR';
    Rmpc_sub   ($rop2, $cop1, $cop2, MPC_RNDNN) if ref($op1) eq 'Math::MPC';
        $cop1 -= $cop2;

    cmp_ok("$cop1", 'eq', "$rop2", "$op1 -= $op2 ok");
  }
}

################################################################################
################################################################################
################################################################################
################################################################################

for my $op1(@ops){
  next if(ref($op1) eq 'Math::MPFR' && !$allow_mpfr_overloading);
  for my $op2(@ops, @negs) {
    next unless ref($op2) eq 'Math::MPC';

    my $cop1 = get_copy($op1);
    my $cop2 = get_copy($op2);

    Rmpc_ui_div($rop2, $cop1, $cop2, MPC_RNDNN) if !ref($op1);
    Rmpc_fr_div($rop2, $cop1, $cop2, MPC_RNDNN) if ref($op1) eq 'Math::MPFR';
    Rmpc_div   ($rop2, $cop1, $cop2, MPC_RNDNN) if ref($op1) eq 'Math::MPC';
        $cop1 /= $cop2;

    cmp_ok("$cop1", 'eq', "$rop2", "$op1 /= $op2 ok");
  }
}

################################################################################
################################################################################
################################################################################
################################################################################

for my $op1(@ops){
  next if(ref($op1) eq 'Math::MPFR' && !$allow_mpfr_overloading);
  for my $op2(@ops, @negs) {
    next unless ref($op2) eq 'Math::MPC';

    my $cop1 = get_copy($op1);
    my $cop2 = get_copy($op2);

    Rmpc_pow_ui($rop2, $cop2, $cop1, MPC_RNDNN) if !ref($op1);
    Rmpc_pow_fr($rop2, $cop2, $cop1, MPC_RNDNN) if ref($op1) eq 'Math::MPFR';
    Rmpc_pow   ($rop2, $cop2, $cop1, MPC_RNDNN) if ref($op1) eq 'Math::MPC';
        $cop2 **= $cop1;

    cmp_ok("$cop2", 'eq', "$rop2", "$op2 **= $op1 ok");
  }
}

################################################################################
################################################################################
################################################################################
################################################################################

for my $op1(@ops){
  next if(ref($op1) eq 'Math::MPFR' && !$allow_mpfr_overloading);
  for my $op2(@ops, @negs) {
    next unless ref($op2) eq 'Math::MPC';

    my $cop1 = get_copy($op1);
    my $cop2 = get_copy($op2);

    Rmpc_sub_ui($rop2, $cop2, $cop1, MPC_RNDNN) if !ref($op1);
    Rmpc_sub_fr($rop2, $cop2, $cop1, MPC_RNDNN) if ref($op1) eq 'Math::MPFR';
    Rmpc_sub   ($rop2, $cop2, $cop1, MPC_RNDNN) if ref($op1) eq 'Math::MPC';
        $cop2 -= $cop1;

    cmp_ok("$cop2", 'eq', "$rop2", "$op2 -= $op1 ok");
  }
}

################################################################################
################################################################################
################################################################################
################################################################################

for my $op1(@ops){
  next if(ref($op1) eq 'Math::MPFR' && !$allow_mpfr_overloading);
  for my $op2(@ops, @negs) {
    next unless ref($op2) eq 'Math::MPC';

    my $cop1 = get_copy($op1);
    my $cop2 = get_copy($op2);

    Rmpc_div_ui($rop2, $cop2, $cop1, MPC_RNDNN) if !ref($op1);
    Rmpc_div_fr($rop2, $cop2, $cop1, MPC_RNDNN) if ref($op1) eq 'Math::MPFR';
    Rmpc_div   ($rop2, $cop2, $cop1, MPC_RNDNN) if ref($op1) eq 'Math::MPC';
        $cop2 /= $cop1;

    cmp_ok("$cop2", 'eq', "$rop2", "$op2 /= $op1 ok");
  }
}

done_testing();

sub get_copy {
  return $_[0] unless ref($_[0]);

  if(ref($_[0]) eq 'Math::MPFR') {
    my $ret = Math::MPFR->new();
    Math::MPFR::Rmpfr_set($ret, $_[0], 0);
    return $ret;
  }

  my $ret = Math::MPC->new();
  Rmpc_set($ret, $_[0], MPC_RNDNN);
  return $ret;
}

__END__

