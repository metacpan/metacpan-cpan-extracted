# In an attempt to learn a little more about what's going awry with this
# test script re (eg):
# https://www.cpantesters.org/cpan/report/79772b92-31fa-11f1-9dde-ebd66d8775ea
# I'm testing without Test::More (to avoid perl's interpolation of Math::MPC
# objects), and adding a few more tests.
# For the last test, if it fails, then we try to print out the values using
# Rmpfr_fprintf().

use warnings;
use strict;
use Math::MPFR qw(:mpfr);
use Math::MPC qw(:mpc);

#use Test::More;
print "1..10\n";

my $mpfr_re1 = Math::MPFR->new();
my $mpfr_im1 = Math::MPFR->new();
my $mpfr_re2 = Math::MPFR->new();
my $mpfr_im2 = Math::MPFR->new();

my ($nok1, $nok2, $nok3, $nok4, $nok5,
    $nok6, $nok7, $nok8, $nok9, $nok10) = (0) x 10;

my $mpc_ = Rmpc_init2(64);
my $mpc__ = Rmpc_init2(64);
my $mpc0 = Rmpc_init2(64);
my $mpc0_copy = Rmpc_init2(64);
my $mpc1 = Rmpc_init2(64);
my $mpc1_copy = Rmpc_init2(64);

my $mpc2 = Rmpc_init3(100, 150);
my $mpc2_copy = Rmpc_init3(100, 150);
my $mpc3 = Rmpc_init3(90, 70);
my $mpc3_copy = Rmpc_init3(90, 70);

Rmpc_set_d_d($mpc_, 123.5, 123.75, MPC_RNDNN);
Rmpc_set_d_d($mpc__, 123.5, 123.75, MPC_RNDNN);
Rmpc_set_d_d($mpc0, 1.5, 1.75, MPC_RNDNN);
Rmpc_set_d_d($mpc1, 2.5, 2.625, MPC_RNDNN);
Rmpc_set_d_d($mpc2, 1.253, 1.1253, MPC_RNDNN);
Rmpc_set_d_d($mpc3, 8.5, 2.875, MPC_RNDNN);
Rmpc_set_d_d($mpc0_copy, 1.5, 1.75, MPC_RNDNN);
Rmpc_set_d_d($mpc1_copy, 2.5, 2.625, MPC_RNDNN);
Rmpc_set_d_d($mpc2_copy, 1.253, 1.1253, MPC_RNDNN);
Rmpc_set_d_d($mpc3_copy, 8.5, 2.875, MPC_RNDNN);

if($mpc_ == $mpc__) { print "ok 1\n" }
else { print "not ok 1\n";
       $nok1 = 1 }

Rmpc_swap($mpc__, $mpc_);

if($mpc_ == $mpc__) {print "ok 2\n"}
else { print "not ok 2\n";
       $nok2 = 1 }

if($mpc0 == $mpc0_copy) { print "ok 3\n" }
else { print "not ok 3\n";
       $nok3 = 1 }
if($mpc1 == $mpc1_copy) { print "ok 4\n" }
else { print "not ok 4\n";
       $nok4 = 1; }

Rmpc_swap($mpc0, $mpc1);

if($mpc0 == $mpc1_copy) { print "ok 5\n" }
else { print "not ok 5\n";
       $nok5 = 1 }
if($mpc1 == $mpc0_copy) { print "ok 6\n" }
else { print "not ok 6\n";
       $nok6 = 1 }

########################################################

if($mpc2 == $mpc2_copy) { print "ok 7\n" }
else { print "not ok 7\n";
       $nok7 = 1 }
if($mpc3 == $mpc3_copy) { print "ok 8\n" }
else { print "not ok 8\n";
       $nok8 = 1 }

Rmpc_swap($mpc2, $mpc3);

if($mpc2 == $mpc3_copy) { print "ok 9\n" }
else { print "not ok 9\n";
       $nok9 = 1 }
if($mpc3 == $mpc2_copy) { print "ok 10\n"}
else { print "not ok 10\n";
       RMPC_RE($mpfr_re1, $mpc3);
       RMPC_IM($mpfr_im1, $mpc3);
       RMPC_RE($mpfr_re2, $mpc2_copy);
       RMPC_IM($mpfr_im2, $mpc2_copy);

       Rmpfr_fprintf(*stderr, "Test 10:\n[%Ra ", $mpfr_re1);
       Rmpfr_fprintf(*stderr, "%Ra]\n !=\n", $mpfr_im1);
       Rmpfr_fprintf(*stderr, "[%Ra ", $mpfr_re2);
       Rmpfr_fprintf(*stderr, "%Ra]\n\n", $mpfr_im2);
       $nok10 = 1 }

#done_testing();

