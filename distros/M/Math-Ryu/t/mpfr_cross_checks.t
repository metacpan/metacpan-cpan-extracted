use strict;
use warnings;
use Math::Ryu qw(:all);
use Config;

use Test::More;

my $skip = 0;
my $fmt = Math::Ryu::MAX_DEC_DIG;


if($fmt == 17) {
  if(2 ** -1074 == 0) {
    warn "  Seems that this \"double\" build of perl sets subnormals to 0.\n",
         "  Skipping tests that don't work around this bug - but a rewritten ",
         "  script that provides such a workaround would be gladly received\n";
    $skip = 1;
  }
}

if($fmt == 21) {
  if(2 ** -16445 == 0) {
    warn "  Seems that this \"long double\" build of perl has no powl() function.\n",
         "  Skipping tests that don't work around this bug - but a rewritten ",
         "  script that provides such a workaround would be gladly received\n";
    $skip = 1;
  }
}


if($fmt == 17) {

  if(!(2 ** -1075)) {
    cmp_ok(nv2s(2 ** -1075), '==', 0, "2 ** -1075 is zero on this system");
  }
  else {
    warn "Skipping rendition of 2**-1075 because this dumbarse perl thinks it's non-zero\n";
  }
  unless($skip) {
    cmp_ok(nv2s(2 ** -1074), 'eq', '5e-324', "2 ** -1074 is 5e-324");
    cmp_ok(nv2s(2 ** -1064), 'eq', '5.06e-321', "2 ** -1064 is 5.06e-321");
    cmp_ok(nv2s(2 ** -1064 + 2 ** -1074), 'eq', '5.064e-321', "2 ** -1064 + 2 ** -1074 is 5.064e-321");
  }

}
elsif($fmt == 21) {
  cmp_ok(nv2s(2 ** -16446), '==', 0, "2 ** -16446 is zero");
  unless($skip) {
    cmp_ok(nv2s(2 ** -16445), 'eq', '4e-4951', "2 ** -16445 is 4e-4951");
    cmp_ok(nv2s(2 ** -16444), 'eq', '7e-4951', "2 ** -16444 is 7e-4951");
    cmp_ok(nv2s(2 ** -16443), 'eq', '1.5e-4950', "2 ** -16443 is 1.5e-4950");
    cmp_ok(nv2s(2 ** -16442), 'eq', '3e-4950', "2 ** -16442 is 3e-4950");
    cmp_ok(nv2s(2 ** -16441), 'eq', '6e-4950', "2 ** -16441 is 6e-4950");
    cmp_ok(nv2s(2 ** -16436), 'eq', '1.866e-4948', "2 ** -16436 is 1.866e-4948");
    cmp_ok(nv2s(2 ** -16436 + 2 ** -16445), 'eq', '1.87e-4948', "2** -16436 + 2 ** -16445 is 1.87e-4948");
    cmp_ok(nv2s(0.0741598938131886598e21), 'eq', '74159893813188659800.0', "0.0741598938131886598e21 is 74159893813188659800.0");
  }
}
else {
  # Math::Ryu::MAX_DEC_DIG == 36
  cmp_ok(nv2s(2 ** -16494), 'eq', '6e-4966', "2 ** -16494 is 6e-4966");
  cmp_ok(nv2s(2 ** -16484), 'eq', '6.63e-4963', "2 ** -16484 is 6.63e-4963");
  cmp_ok(nv2s(2 ** -16484 + 2 ** -16494), 'eq', '6.64e-4963', "2 ** -16484 + 2 ** -16494 is 6.64e-4963");
}

my $mpfr = 1;
eval{require Math::MPFR;};
if($@) {
  warn "Skipping remaining tests - Math::MPFR has failed to load\n";
  done_testing();
  exit 0;
}

if($Math::MPFR::VERSION < 4.14) {
  warn "Skipping remaining tests - Math::MPFR needs to be at version 4.14 or later\n";
  done_testing();
  exit 0;
}

if(Math::MPFR::MPFR_VERSION_MAJOR() < 3 || (Math::MPFR::MPFR_VERSION_MAJOR() == 3  && Math::MPFR::MPFR_VERSION_PATCHLEVEL() < 6)) {
  warn "Skipping remaining tests - Math::MPFR needs to have been built against mpfr-3.1.6 or later\n";
  done_testing();
  exit 0;
}

my $obj = Math::MPFR->new();
Math::MPFR::Rmpfr_set_inf($obj, 1);
my $inf = Math::MPFR::Rmpfr_get_NV($obj, 0);

for(1190 .. 1205, 590 .. 605,  90 .. 105, 0 .. 40) {
   my $mant = rand();
   $mant = (split /e/i, "$mant")[0];
   my $exp = $_;
   $exp = "-$exp" if $_ % 3;
   my $n = $mant . 'e' . $exp;
   if(!ryu_lln($n)) {
     warn "Non-numeric: $mant $exp => $n\n";
   }
   if(nv2s($n) + 0 == $inf) {
     # Avoid getting bogged down in differences between representation of infinity.
     cmp_ok(nv2s($n) + 0, '==', Math::MPFR::nvtoa($n) + 0, "Inf == inf");
   }
   else {
     cmp_ok(nv2s($n), 'eq', Math::MPFR::nvtoa($n), "$n renders ok");
   }
}

cmp_ok(nv2s(0.0741598938131886598e21), 'eq', Math::MPFR::nvtoa(0.0741598938131886598e21), '0.0741598938131886598e21 renders consistently');

if($mpfr) {
  for my $iteration (1..10) {
    my $sign = $iteration & 1 ? '-' : '';
    for my $p(0..50) {
      my $exp = $p;
      $exp = "-$exp" if $iteration & 1;
      my $rand =  $sign . rand();
      $rand .= "e$exp" unless $rand =~ /e/i;
      my $num = $rand + 0;
      cmp_ok(nv2s($num), 'eq', Math::MPFR::nvtoa($num), "fmtpy() format agrees with nvtoa(): " . sprintf("%.${fmt}g", $num));
    }
  }

  for my $num(0.1, 0.12, 0.123, 0.1234, 0.12345, 0.123456, 0.1234567, 0.12345678, 0.123456789, 0.1234567890, 0.12345678901, 0.123456789012,
             0.1234567890123, 0.12345678901234, 0.123456789012345, 0.1234567890123456, 0.12345678901234567, 0.123456789012345678,
             0.1234567890123456789, 0.12345678901234567894) {
    cmp_ok(nv2s($num), 'eq', Math::MPFR::nvtoa($num), "fmtpy() format agrees with nvtoa(): " . sprintf("%.${fmt}g", $num));
  }

  my $nvprec = Math::Ryu::MAX_DEC_DIG - 2;
  my $nv = ('6' . ('0' x $nvprec) . '.0') + 0;
  cmp_ok(nv2s($nv),  'eq', Math::MPFR::nvtoa($nv), "6e+${nvprec} ok");
  cmp_ok(nv2s(-$nv),  'eq', Math::MPFR::nvtoa(-$nv), "-6e+${nvprec} ok");

  $nv = ('6125' . ('0' x ($nvprec - 3)) . '.0') + 0;
  cmp_ok(nv2s($nv),  'eq', Math::MPFR::nvtoa($nv), "6.125e+${nvprec} ok");
  cmp_ok(nv2s(-$nv),  'eq', Math::MPFR::nvtoa(-$nv), "-6.125e+${nvprec} ok");

  $nvprec++;
  $nv = ('6' . ('0' x $nvprec) . '.0') + 0;
  cmp_ok(nv2s($nv),  'eq', Math::MPFR::nvtoa($nv), "6e+${nvprec}  ok");
  cmp_ok(nv2s(-$nv),  'eq', Math::MPFR::nvtoa(-$nv), "-6e+${nvprec}  ok");

  $nv = ('6125' . ('0' x ($nvprec - 3)) . '.0') + 0;
  cmp_ok(nv2s($nv),  'eq', Math::MPFR::nvtoa($nv), "6.125e+${nvprec} ok");
  cmp_ok(nv2s(-$nv),  'eq', Math::MPFR::nvtoa(-$nv), "-6.125e+${nvprec} ok");

}

done_testing();
