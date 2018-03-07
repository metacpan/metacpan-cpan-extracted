
#################################################################
# NOTE: Not everything that's new in mpfr-4.0.0 is tested here. #
# eg: MPFR_RNDF rounding and the new freeing of caches/pools    #
#     are tested elsewhere in the test suite.                   #
#################################################################

use warnings;
use strict;
use Math::MPFR qw(:mpfr);

print "1..36\n";

my $have_new = 1;
my @ret;
my $ret;

if(!defined(MPFR_VERSION) || 262144 > MPFR_VERSION) {$have_new = 0} # mpfr version is pre 3.2.0

my $x = Math::MPFR->new(200);
my $y = Math::MPFR->new(17);
my $rop = Math::MPFR->new();
my $rop1 = Math::MPFR->new();
my $rop2 = Math::MPFR->new();

eval {@ret = Rmpfr_fmodquo($rop, $x, $y, MPFR_RNDA);};

if($have_new) {
  if($rop == 13 && $ret[0] == 11 && $ret[1] == 0) {print "ok 1\n"}
  else {
    warn "\nExpected 13, 11, and 0\nGot $rop, $ret[0] and $ret[1]\n";
    print "not ok 1\n";
  }
}
else {
  if($@ =~ /^Rmpfr_fmodquo not implemented \- need at least mpfr\-4\.0\.0/) {print "ok 1\n"}
  else {
    warn "\n\$\@:\n$@\n";
    print "not ok 1\n";
  }
}

my $float = Math::MPFR->new(0.1);

my $write = open WR, '>', 'fpif.txt';

warn "Couldn't open export file for writing: $!"
  unless $write;

if($write) {
  binmode(WR);
  eval {$ret = Rmpfr_fpif_export(\*WR, $float);};
  if($@) {
    if($@ =~ /^Rmpfr_fpif_export not implemented \- need at least mpfr\-4\.0\.0/) {print "ok 2\n"}
    else {
      warn "\n\$\@:\n$@\n";
      print "not ok 2\n";
    }
  }
else {
  if($ret == 0) {print "ok 2\n"}
  else {
    warn "\nRmpfr_fpif_export failed\n";
    print "not ok 2\n";
  }
}

 close WR or warn "Could not close export file: $!";
}
else {
  warn "\n Skipping test 2: export file not created\n";
  print "ok 2\n";
}

my $retrieve = Math::MPFR->new();

my $read = open RD, '<', 'fpif.txt';

warn "Couldn't open export file for reading: $!"
  unless $read;

if($read) {
  binmode(RD);
  eval {$ret = Rmpfr_fpif_import($retrieve, \*RD);};
  if($@) {
    if($@ =~ /^Rmpfr_fpif_import not implemented \- need at least mpfr\-4\.0\.0/) {print "ok 3\n"}
    else {
      warn "\n\$\@:\n$@\n";
      print "not ok 3\n";
    }
  }
else {
  if($ret == 0 && $retrieve == $float) {print "ok 3\n"}
  else {
    warn "\n3: Got $ret and $retrieve\n";
    print "not ok 3\n";
  }
}

 close RD or warn "Could not close export file: $!";
}
else {
  warn "\n Skipping test 3: import file not readable\n";
  print "ok 3\n";
}

if($have_new) {
  Rmpfr_clear_underflow();
  Rmpfr_clear_overflow();
  Rmpfr_clear_divby0();
  Rmpfr_clear_nanflag();
  Rmpfr_clear_inexflag();
  Rmpfr_clear_erangeflag();

  ######################
  Rmpfr_set_underflow();
  if(Rmpfr_underflow_p()) {print "ok 4\n"}
  else {
    warn "\nBug in at least one of Rmpfr_set_underflow() and Rmpfr_underflow_p()\n";
    print "not ok 4\n";
  }

  Rmpfr_flags_clear(MPFR_FLAGS_UNDERFLOW);

  if(Rmpfr_underflow_p()) {
    print "not ok 5\n";
  }
  else {print "ok 5\n"}
  ######################
  ######################
  Rmpfr_set_overflow();
  if(Rmpfr_overflow_p()) {print "ok 6\n"}
  else {
    warn "\nBug in at least one of Rmpfr_set_overflow() and Rmpfr_overflow_p()\n";
    print "not ok 6\n";
  }

  Rmpfr_flags_clear(MPFR_FLAGS_OVERFLOW);

  if(Rmpfr_overflow_p()) {
    print "not ok 7\n";
  }
  else {print "ok 7\n"}
  ######################
  ######################
  Rmpfr_set_nanflag();
  if(Rmpfr_nanflag_p()) {print "ok 8\n"}
  else {
    warn "\nBug in at least one of Rmpfr_set_nanflag() and Rmpfr_nanflag_p()\n";
    print "not ok 8\n";
  }

  Rmpfr_flags_clear(MPFR_FLAGS_NAN);

  if(Rmpfr_nanflag_p()) {
    print "not ok 9\n";
  }
  else {print "ok 9\n"}
  ######################
  ######################
  Rmpfr_set_inexflag();
  if(Rmpfr_inexflag_p()) {print "ok 10\n"}
  else {
    warn "\nBug in at least one of Rmpfr_set_inexflag() and Rmpfr_inexflag_p()\n";
    print "not ok 10\n";
  }

  Rmpfr_flags_clear(MPFR_FLAGS_INEXACT);

  if(Rmpfr_inexflag_p()) {
    print "not ok 11\n";
  }
  else {print "ok 11\n"}
  ######################
  ######################
  Rmpfr_set_erangeflag();
  if(Rmpfr_erangeflag_p()) {print "ok 12\n"}
  else {
    warn "\nBug in at least one of Rmpfr_set_erangeflag() and Rmpfr_erangeflag_p()\n";
    print "not ok 12\n";
  }

  Rmpfr_flags_clear(MPFR_FLAGS_ERANGE);

  if(Rmpfr_erangeflag_p()) {
    print "not ok 13\n";
  }
  else {print "ok 13\n"}
  ######################
  ######################
  Rmpfr_set_divby0();
  if(Rmpfr_divby0_p()) {print "ok 14\n"}
  else {
    warn "\nBug in at least one of Rmpfr_set_divby0() and Rmpfr_divby0_p()\n";
    print "not ok 14\n";
  }

  Rmpfr_flags_clear(MPFR_FLAGS_DIVBY0);

  if(Rmpfr_divby0_p()) {
    print "not ok 15\n";
  }
  else {print "ok 15\n"}
  ######################
  ######################
  Rmpfr_set_divby0();
  if(Rmpfr_divby0_p()) {print "ok 16\n"}
  else {
    warn "\nBug in at least one of Rmpfr_set_divby0() and Rmpfr_divby0_p()\n";
    print "not ok 16\n";
  }

  Rmpfr_flags_clear(MPFR_FLAGS_NAN);

  if(Rmpfr_divby0_p()) { # should have been untouched
    print "ok 17\n";
  }
  else {print "not ok 17\n"}
  ######################
  ######################
  Rmpfr_set_divby0();
  if(Rmpfr_divby0_p()) {print "ok 18\n"}
  else {
    warn "\nBug in at least one of Rmpfr_set_divby0() and Rmpfr_divby0_p()\n";
    print "not ok 18\n";
  }

  Rmpfr_flags_clear(MPFR_FLAGS_ALL);

  if(Rmpfr_divby0_p()) {
    print "not ok 19\n";
  }
  else {print "ok 19\n"}
  ######################
  ######################
  Rmpfr_set_divby0();
  Rmpfr_set_nanflag();

  my $mask = Rmpfr_flags_save();

  if($mask == 36) {print "ok 20\n"}
  else {
    warn "\n Expected 36\nGot $mask\n";
    print "not ok 20\n";
  }

  my $check = Rmpfr_flags_test(MPFR_FLAGS_ALL);

  if($check == 36) {print "ok 21\n"}
  else {
    warn "\nExpected 36\nGot $check\n";
    print "not ok 21\n";
  }

  Rmpfr_flags_set(24);

  $mask = Rmpfr_flags_save();

  if($mask == 60) {print "ok 22\n"}
  else {
    warn "\nExpected 60\nGot $mask\n";
    print "not ok 22\n";
  }

  Rmpfr_flags_restore(3, $mask);

  # print Rmpfr_flags_save(), "\n";

  if(Rmpfr_flags_save() == 0) {print "ok 23\n"}
  else {
    warn "\nExpected 0\nGot ", Rmpfr_flags_save(), "\n";
    print "not ok 23\n";
  }
}
else {
  eval{Rmpfr_flags_clear(1)     ;};

  if($@ =~ /^Rmpfr_flags_clear not implemented \- need at least mpfr\-4\.0\.0/) {print "ok 4\n"}
  else {
    warn "\n\$\@:\n$@\n";
    print "not ok 4\n";
  }

  eval{Rmpfr_flags_set(1)       ;};

  if($@ =~ /^Rmpfr_flags_set not implemented \- need at least mpfr\-4\.0\.0/) {print "ok 5\n"}
  else {
    warn "\n\$\@:\n$@\n";
    print "not ok 5\n";
  }

  eval{Rmpfr_flags_test(1)      ;};

  if($@ =~ /^Rmpfr_flags_test not implemented \- need at least mpfr\-4\.0\.0/) {print "ok 6\n"}
  else {
    warn "\n\$\@:\n$@\n";
    print "not ok 6\n";
  }

  eval{Rmpfr_flags_save()       ;};

  if($@ =~ /^Rmpfr_flags_save not implemented \- need at least mpfr\-4\.0\.0/) {print "ok 7\n"}
  else {
    warn "\n\$\@:\n$@\n";
    print "not ok 7\n";
  }

  eval{Rmpfr_flags_restore(2, 1);};

  if($@ =~ /^Rmpfr_flags_restore not implemented \- need at least mpfr\-4\.0\.0/) {print "ok 8\n"}
  else {
    warn "\n\$\@:\n$@\n";
    print "not ok 8\n";
  }

  warn "\n Skipping tests 9 to 23 for this version of the mpfr library\n";

  print "ok $_\n" for 9 .. 23;
}

$x += 0.5; # 200.5

eval {Rmpfr_rint_roundeven($rop, $x, MPFR_RNDN);};

if($have_new) {
  if($rop == 200) {print "ok 24\n"}
  else {
    warn "\nExpected 200\nGot $rop\n";
    print "not ok 24\n";
  }
}
else {
  if($@ =~ /^Rmpfr_rint_roundeven not implemented \- need at least mpfr\-4\.0\.0/) {print "ok 24\n"}
  else {
    warn "\n\$\@:\n$@\n";
    print "not ok 24\n";
  }
}

$x += 1.0; # 201.5

eval {Rmpfr_rint_roundeven($rop, $x, MPFR_RNDN);};

if($have_new) {
  if($rop == 202) {print "ok 25\n"}
  else {
    warn "\nExpected 202\nGot $rop\n";
    print "not ok 25\n";
  }
}
else {
  if($@ =~ /^Rmpfr_rint_roundeven not implemented \- need at least mpfr\-4\.0\.0/) {print "ok 25\n"}
  else {
    warn "\n\$\@:\n$@\n";
    print "not ok 25\n";
  }
}

eval {Rmpfr_roundeven($rop, $x);};

if($have_new) {
  if($rop == 202) {print "ok 26\n"}
  else {
    warn "\nExpected 202\nGot $rop\n";
    print "not ok 26\n";
  }
}
else {
  if($@ =~ /^Rmpfr_roundeven not implemented \- need at least mpfr\-4\.0\.0/) {print "ok 26\n"}
  else {
    warn "\n\$\@:\n$@\n";
    print "not ok 26\n";
  }
}

$x += 1.0; # 202.5

eval {Rmpfr_roundeven($rop, $x);};

if($have_new) {
  if($rop == 202) {print "ok 27\n"}
  else {
    warn "\nExpected 202\nGot $rop\n";
    print "not ok 27\n";
  }
}
else {
  if($@ =~ /^Rmpfr_roundeven not implemented \- need at least mpfr\-4\.0\.0/) {print "ok 27\n"}
  else {
    warn "\n\$\@:\n$@\n";
    print "not ok 27\n";
  }
}

my $state = Rmpfr_randinit_mt();

if($have_new) {
  Rmpfr_nrandom($rop,  $state, MPFR_RNDN);
  Rmpfr_nrandom($rop2, $state, MPFR_RNDN);

  if($rop != $rop2) {print "ok 28\n"}
  else {print "not ok 28\n"}
}
else {
  eval {Rmpfr_nrandom($rop, $state, MPFR_RNDN);};

  if($@ =~ /^Rmpfr_nrandom not implemented \- need at least mpfr\-4\.0\.0/) {print "ok 28\n"}
  else {
    warn "\n\$\@:\n$@\n";
    print "not ok 28\n";
  }
}

if($have_new) {
  Rmpfr_erandom($rop,  $state, MPFR_RNDN);
  Rmpfr_erandom($rop2, $state, MPFR_RNDN);

  if($rop != $rop2) {print "ok 29\n"}
  else {print "not ok 29\n"}
}
else {
  eval {Rmpfr_erandom($rop, $state, MPFR_RNDN);};

  if($@ =~ /^Rmpfr_erandom not implemented \- need at least mpfr\-4\.0\.0/) {print "ok 29\n"}
  else {
    warn "\n\$\@:\n$@\n";
    print "not ok 29\n";
  }
}

my $op1 = Math::MPFR->new(10);
my $op2 = Math::MPFR->new(15);
my $op3 = Math::MPFR->new(10);
my $op4 = Math::MPFR->new(14);

eval {Rmpfr_fmma($rop, $op1, $op2, $op3, $op4, MPFR_RNDN);};

if($have_new) {
  if($rop == 290) {print "ok 30\n"}
  else {
    warn "\nExpected 190\nGot $rop\n";
    print "not ok 30\n";
  }
}
else {
  if($@ =~ /^Rmpfr_fmma not implemented \- need at least mpfr\-4\.0\.0/) {print "ok 30\n"}
  else {
    warn "\n\$\@:\n$@\n";
    print "not ok 30\n";
  }
}

eval {Rmpfr_fmms($rop, $op1, $op2, $op3, $op4, MPFR_RNDN);};

if($have_new) {
  if($rop == 10) {print "ok 31\n"}
  else {
    warn "\nExpected 10\nGot $rop\n";
    print "not ok 31\n";
  }
}
else {
  if($@ =~ /^Rmpfr_fmms not implemented \- need at least mpfr\-4\.0\.0/) {print "ok 31\n"}
  else {
    warn "\n\$\@:\n$@\n";
    print "not ok 31\n";
  }
}


eval {Rmpfr_log_ui($rop, $op1, MPFR_RNDN);};

if($have_new) {
  if($rop > 2.302585 && $rop < 2.3025851) {print "ok 32\n"}
  else {
    warn "\nExpected approx 2.3025851\nGot $rop\n";
    print "not ok 32\n";
  }
}
else {
  if($@ =~ /^Rmpfr_log_ui not implemented \- need at least mpfr\-4\.0\.0/) {print "ok 32\n"}
  else {
    warn "\n\$\@:\n$@\n";
    print "not ok 32\n";
  }
}

eval {Rmpfr_gamma_inc($rop, Math::MPFR->new(-1), Math::MPFR->new(0), MPFR_RNDN);};

if($have_new) {
  if(Rmpfr_nan_p($rop)) {print "ok 33\n"}
  else {
    warn "\nExpected NaN\nGot $rop\n";
    print "not ok 33\n";
  }
}
else {
  if($@ =~ /^Rmpfr_gamma_inc not implemented \- need at least mpfr\-4\.0\.0/) {print "ok 33\n"}
  else {
    warn "\n\$\@:\n$@\n";
    print "not ok 33\n";
  }
}

if($have_new) {
  my $inex1 = Rmpfr_beta($rop1, Math::MPFR->new(21), Math::MPFR->new(31), MPFR_RNDN);
  my $inex2 = Rmpfr_beta($rop2, Math::MPFR->new(31), Math::MPFR->new(21), MPFR_RNDN);

  if($inex1 == $inex2) {print "ok 34\n"}
  else {
    warn "\n \$inex1: $inex1\n\ $inex2: $inex2\n";
    print "not ok 34\n";
  }

  if($rop1 == $rop2) {print "ok 35\n"}
  else {
    warn "\n \$rop1: $rop1\n\ $rop2: $rop2\n";
    print "not ok 35\n";
  }

  Rmpfr_beta($rop1, Math::MPFR->new(5), Math::MPFR->new(6), MPFR_RNDN);

  if($rop1 = Math::MPFR->new(24) / Math::MPFR->new(30240)) {print "ok 36\n"}
  else {
    warn "\n Expected ", Math::MPFR->new(24) / Math::MPFR->new(30240), "\n Got: $rop1\n";
    print "not ok 36\n";
  }
}
else {
  eval{Rmpfr_beta($rop2, Math::MPFR->new(31), Math::MPFR->new(21), MPFR_RNDN);};

  if($@ =~ /^Rmpfr_beta not implemented \- need at least mpfr\-4\.0\.0/) {print "ok 34\n"}
  else {
    warn "\n\$\@:\n$@\n";
    print "not ok 34\n";
  }

  warn "\n Skipping tests 35 & 36 - nothing to test\n";
  print "ok 35\n";
  print "ok 36\n";
}

