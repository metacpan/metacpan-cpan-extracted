# Check some values to verify that Rmpfr_set_IV is functioning
# correctly. We check some values that are not IVs.
# In all cases Rmpfr_set_IV should agree with both MPFR_SET_IV()
# and MPFR_INIT_SET_IV().
use strict;
use warnings;
use Math::MPFR qw(:mpfr IOK_flag NOK_flag POK_flag);
use Config;

use Test::More;

my $bits = $Config{ivsize} * 8;

if($Config{ivtype} eq 'long' &&
   $Config{ivsize} == $Config{longsize}) { *MPFR_SET_IV      = \&Rmpfr_set_si;
                                           *MPFR_INIT_SET_IV = \&Rmpfr_init_set_si;
                                           *MPFR_SET_UV      = \&Rmpfr_set_ui;
                                           *MPFR_INIT_SET_UV = \&Rmpfr_init_set_ui;
                                           *MPFR_CMP_IV      = \&Rmpfr_cmp_si;
                                           *MPFR_CMP_UV      = \&Rmpfr_cmp_ui;
                                           warn "\nUsing *_set_ui,*_set_si _cmp_ui and cmp_si functions\n"; }

else                                     { *MPFR_SET_IV      = \&Rmpfr_set_sj;
                                           *MPFR_INIT_SET_IV = \&init_set_sj;          # provided below
                                           *MPFR_SET_UV      = \&Rmpfr_set_uj;
                                           *MPFR_INIT_SET_UV = \&init_set_uj;          # provided below
                                           *MPFR_CMP_IV      = \&Rmpfr_cmp_sj;
                                           *MPFR_CMP_UV      = \&Rmpfr_cmp_uj;
                                           warn "\nUsing set_uj and _set_sj functions\n"; }
Rmpfr_set_default_prec($bits);

my $x = '42.3';
my $y = ~0;
my $z = -1;

my @in = (0, 'inf', '-inf', 'nan', '-nan', 'hello', ~0, -1, sqrt(2), Math::MPFR->new(),
    Math::MPFR->new(-11), $x, \$x, "$y", "$z", 2 ** 32, 2 ** 64, 2 ** -1069, 2 ** -16300,
    ~0 * 2, ~0 * -2);

for(@in) {

  no warnings 'numeric';

  # Create copies of $_ - and use each copy only once
  # as perl might change the flags.
  my($c1, $c2, $c3, $c4, $c5, $c6) = ($_, $_, $_, $_, $_, $_);

  my($rop1, $rop2, $rop3, $rop4, $inex1, $inex2, $inex3, $inex4);
  my $rnd = int(rand(4));

  if(IOK_flag($c1)) {
    ($rop1, $inex1) = Rmpfr_init_set_IV($c1, $rnd);
  }
  else {
    eval { ($rop1, $inex1) = Rmpfr_init_set_IV($c1, $rnd);};
    like($@, qr/Arg provided to Rmpfr_set_IV is not an IV/, '$@ set as expected');
    next;
  }

  if($rop1 < (~0 >> 1)) {
    ($rop2, $inex2) = MPFR_INIT_SET_IV ($c2, $rnd);
  }
  else {
    ($rop2, $inex2) = MPFR_INIT_SET_UV ($c2, $rnd);
  }

  $rop3  = Math::MPFR->new();
  $rop4  = Math::MPFR->new();

  $inex3 = Rmpfr_set_IV($rop3, $c3, $rnd);

  if($rop1 < (~0 >> 1)) {
    $inex4 = MPFR_SET_IV ($rop4, $c4, $rnd);
  }
  else {
    $inex4 = MPFR_SET_UV ($rop4, $c4, $rnd);
  }

  cmp_ok($inex1, '==', $inex2, "$rnd: $_: \$inex1 == \$inex2");
  cmp_ok($inex1, '==', $inex3, "$rnd: $_: \$inex1 == \$inex3");
  cmp_ok($inex1, '==', $inex4, "$rnd: $_: \$inex1 == \$inex4");

  cmp_ok(Rmpfr_nan_p($rop1), '==', 0, "$rnd: $_: not a NaN");
  cmp_ok(Rmpfr_nan_p($rop2), '==', 0, "$rnd: $_: not a NaN");
  cmp_ok(Rmpfr_nan_p($rop3), '==', 0, "$rnd: $_: not a NaN");
  cmp_ok(Rmpfr_nan_p($rop4), '==', 0, "$rnd: $_: not a NaN");

  cmp_ok($rop1, '==', $rop2, "$rnd: $_: \$rop1 == \$rop2");
  cmp_ok($rop1, '==', $rop3, "$rnd: $_: \$rop1 == \$rop3");
  cmp_ok($rop1, '==', $rop4, "$rnd: $_: \$rop1 == \$rop2");
}

# We'll now run similar checks on Rmpfr_cmp_IV, using the
# values (in @in) that we've already used to check Rmpfr_set_IV.

for(@in) {

  no warnings 'numeric';

  # Create copies of $_ - and use each copy only once
  # as perl might change the flags.
  my($c1, $c2, $c3, $c4, $c5, $c6) = ($_, $_, $_, $_, $_, $_);

  my $rnd = int(rand(4));
  my $rop1 = Math::MPFR->new();
#  Rmpfr_set_IV($rop1, $c1, $rnd);

  if(IOK_flag($c1)) {
    Rmpfr_set_IV($rop1, $c1, $rnd);
  }
  else {
    eval { Rmpfr_set_IV($rop1, $c1, $rnd);};
    like($@, qr/Arg provided to Rmpfr_set_IV is not an IV/, '$@ set as expected');
    next;
  }

  if($rop1 < (~0 >> 1)) {
    if(Rmpfr_cmp_IV     ($rop1, $c2) < 0) {
      cmp_ok(MPFR_CMP_IV($rop1, $c6), '<', 0, "$rnd: $_: comparisons concur");
    }
    elsif(Rmpfr_cmp_IV($rop1, $c3) == 0) {
      cmp_ok(MPFR_CMP_IV($rop1, $c6), '==', 0, "$rnd: $_: comparisons concur");
    }
    else {
      cmp_ok(MPFR_CMP_IV($rop1, $c6), '>', 0, "$rnd: $_: comparisons concur");
    }
  }
  else {
    if(Rmpfr_cmp_IV     ($rop1, $c2) < 0) {
      cmp_ok(MPFR_CMP_UV($rop1, $c6), '<', 0, "$rnd: $_: comparisons concur");
    }
    elsif(Rmpfr_cmp_IV($rop1, $c3) == 0) {
      cmp_ok(MPFR_CMP_UV($rop1, $c6), '==', 0, "$rnd: $_: comparisons concur");
    }
    else {
      cmp_ok(MPFR_CMP_UV($rop1, $c6), '>', 0, "$rnd: $_: comparisons concur");
    }
  }
}

cmp_ok(POK_flag("$bits"), '==', 1, "POK_flag set as expected"  );
cmp_ok(POK_flag(2.3)    , '==', 0, "POK_flag unset as expected");

cmp_ok(NOK_flag(2.3)    , '==', 1, "NOK_flag set as expected"  );
cmp_ok(NOK_flag("2.3")  , '==', 0, "NOK_flag unset as expected");

done_testing();

sub init_set_sj {
  no warnings 'numeric';
  my $ret = Math::MPFR->new();
  my $inex = Rmpfr_set_sj($ret, $_[0], $_[1]);
  return ($ret, $inex);
}

sub init_set_uj {
  no warnings 'numeric';
  my $ret = Math::MPFR->new();
  my $inex = Rmpfr_set_uj($ret, $_[0], $_[1]);
  return ($ret, $inex);
}
