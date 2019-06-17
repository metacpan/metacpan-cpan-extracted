

use strict;
use warnings;
use Math::NV qw(:all);
use Config;

my $tests = 17;

print "1..$tests\n";

my $arb = 1021;
Math::MPFR::Rmpfr_set_default_prec($arb);

my $val = nv_mpfr('1e+127', 106);

if(lc((@$val)[0]) eq "5a4d8ba7f519c84f") {print "ok 1\n"}
else {
  warn "expected \"5a4d8ba7f519c84f\", got ", lc((@$val)[0]), "\n";
  print "not ok 1\n";
}

if(lc((@$val)[1]) eq "56e7fd1f28f89c56") {print "ok 2\n"}
else {
  warn "expected \"56e7fd1f28f89c56\", got ", lc((@$val)[1]), "\n";
  print "not ok 2\n";
}

$val = nv_mpfr('1e+129', 106);

if(lc((@$val)[0]) eq "5ab7151b377c247e") {print "ok 3\n"}
else {
  warn "expected \"5ab7151b377c247e\", got ", lc((@$val)[0]), "\n";
  print "not ok 3\n";
}

if(lc((@$val)[1]) eq "5707b80b0047445d") {print "ok 4\n"}
else {
  warn "expected \"5707b80b0047445d\", got ", lc((@$val)[1]), "\n";
  print "not ok 4\n";
}

eval {$val = nv_mpfr('1.3', 1000);};

if($@ =~ /^Unrecognized value for bits/) {print "ok 5\n"}
else {
  warn "\n\$\@: $@";
  print "not ok 5\n";
}

eval {$val = nv_mpfr('1.3', 10);};
if($@ =~ /^Unrecognized value for bits/) {print "ok 6\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 6\n";
}

#####################################

$val =     nv_mpfr('2.3', mant_dig());
my $val2 = nv_mpfr('2.3');

if(mant_dig == 106) {
  if("@$val" eq "@$val2") {print "ok 7\n"}
  else {
    warn "\nexpected\n@$val eq\n@$val2\n";
    print "not ok 7\n";
  }
}
else {
  if($val eq $val2) {print "ok 7\n"}
  else {
    warn "\nexpected $val, got $val2\n";
    print "not ok 7\n";
  }
}

$val = nv_mpfr('1e+127', 53);

if(lc($val) eq "5a4d8ba7f519c84f") {print "ok 8\n"}
else {
  warn "expected \"5a4d8ba7f519c84f\", got ", lc($val), "\n";
  print "not ok 8\n";
}

if(106 == mant_dig()) {
  warn "\nSkipping tests 9 and 10 for double-double platform\n";
  print "ok 9\nok 10\n";
}

else {
  eval{$val = nv_mpfr('1e+127', 64);};

  if($@) {
    warn "\n Skipping test 9 as _ld_bytes() is unsupported\n";
    print "ok 9\n";
  }
  else {
    if($val =~ /^(0+)?41a4ec5d3fa8ce427b00$/i) {print "ok 9\n"}
    else {
      warn "expected \"41a4ec5d3fa8ce427b00\", got ", lc($val), "\n";
      print "not ok 9\n";
    }
  }

  eval {$val = nv_mpfr('1e+127', 113);};

  if(!$@) {
    if(lc($val) eq "41a4d8ba7f519c84f5ff47ca3e27156a") {print "ok 10\n"}
    else {
      warn "expected \"41a4d8ba7f519c84f5ff47ca3e27156a\", got ", lc($val), "\n";
      print "not ok 10\n";
    }
  }
  else {
    warn "\n Skipping test 10 as _f128_bytes() is unsupported\n";
    print "ok 10\n";
  }
}


# Check that default precison hasn't been altered
my $now = Math::MPFR::Rmpfr_get_default_prec();
if($now == $arb) {print "ok 11\n"}
else {
  warn "Default precision changed from $arb to $now\n";
  print "not ok 11\n";
}

eval { is_inexact('0.5') };

if($Math::NV::mpfr_strtofr_bug && $@ && $@ =~ /is_inexact\(\) requires/) {
  warn "\nskipping tests 12 to $tests - mpfr-3.1.6 or later is needed\n";
  for(12 .. $tests) { print "ok $_\n" }

}
elsif($@) {
  warn "\n\$\@: $@\n";
  print "not ok 12\n";
  warn "\nskipping tests 13 to $tests - test 12 failed\n";
  for(13 .. $tests) { print "ok $_\n" }

}
else {
  my $ok = 1;

  for('0.1', '0.01', '1.3', '0.7', '10.81') {
    my $inex1 = is_inexact($_);
    my $inex2 = is_inexact('-' . $_);

    unless(($inex1 < 0 && $inex2 > 0) || ($inex1 > 0 && $inex2 < 0)) {
      warn "\nFor $_: \$inex1: $inex1 \$inex2: $inex2\n";
      $ok = 0;
    }
  }

  if($ok) { print "ok 12\n" }
  else { print "not ok 12\n" }

  $ok = 1;

  for('0.125', '0.625', '121.5', '0.75', '10.375') {
    my $inex1 = is_inexact($_);
    my $inex2 = is_inexact('-' . $_);

    if($inex1 || $inex2) {
      warn "\nFor $_: \$inex1: $inex1 \$inex2: $inex2\n";
      $ok = 0;
    }
  }

  if($ok) { print "ok 13\n" }
  else { print "not ok 13\n" }

  $ok = 1;

  for('nan', '0', 'inf', '-inf') {
    my $inex = is_inexact($_);
    if($inex) {
      warn "\nis_inexact($_): expected 0, got $inex\n";
      $ok = 0;
    }

  }

  if($ok) { print "ok 14\n" }
  else { print "not ok 14\n" }

  my @res;

  for('1e5000', '-1e5000', '1e-5000', '-1e-5000') {
    push @res, is_inexact($_);
  }

  if($res[0] <= 0 || $res[1] >= 0 || $res[2] >= 0 || $res[3] <= 0) { $ok = 0 }

  if($ok) { print "ok 15\n" }
  else {
    warn "\n In test 15, \@res = @res\n";
    print "not ok 15\n";
  }

  if(mant_dig() % 53 == 0) { # 53-bit or 106-bit (DoubleDouble) NVs only.
    my $inex = is_inexact('4.9e-324');

    if($inex > 0) { print "ok 16\n" }
    else {
      warn "\n in test 16, got $inex\n";
      print "not ok 16\n";
    }

    $inex = is_inexact('5e-324');

    if($inex < 0) { print "ok 17\n" }
    else {
      warn "\n in test 17, got $inex\n";
      print "not ok 17\n";
    }

  }
  else {
    warn "\nSkipping tests 16 to $tests - nvtype is neither double nor doubledouble\n";
    print "ok $_\n" for 16 .. $tests;
  }
}


__END__

For all builds:

1e-5000 should assign to an NV of zero - though will be non-zero when assigned to a Math::MPFR object.
1e+5000 should assign to an NV of infinity - though will be finite when assigned to a Math::MPFR object.

