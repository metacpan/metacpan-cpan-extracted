use strict;
use warnings;
use Math::MPFR qw(:mpfr);

if(4 > MPFR_VERSION_MAJOR) {
  print "1..1\n";
  eval{ nvtoa(0.5) };

  if($@ =~ /^nvtoa function requires version 4\.0/) {
    warn "nvtoa() not supported because the mpfr library is too old\n";
    print "ok 1\n";
  }
  else {
    warn "\$\@: $@\n";
    print "not ok 1\n";
  }
}

else {

  my $ok = 1;
  my $p = $Math::MPFR::NV_properties{max_dig} - 1;
  my $min_pow = $Math::MPFR::NV_properties{min_pow};

  my $zero = 0.0;
  my $nzero = Rmpfr_get_NV(Math::MPFR->new('-0'), MPFR_RNDN);
  my $inf = 1e4950;
  my $ninf = $inf * -1;
  my $nan = Rmpfr_get_NV(Math::MPFR->new(), MPFR_RNDN);

  my $temp1 = Rmpfr_init2($Math::MPFR::NV_properties{bits});
  my $temp2 = Rmpfr_init2($Math::MPFR::NV_properties{bits});

  Rmpfr_set_ui($temp1, 1, MPFR_RNDN);
  Rmpfr_set_ui($temp2, 1, MPFR_RNDN);

  my $div2exp = -$Math::MPFR::NV_properties{min_pow}; # min_pow is -ve.

  Rmpfr_div_2exp($temp1, $temp1, $div2exp, MPFR_RNDN);
  Rmpfr_div_2exp($temp2, $temp2, $div2exp - 1, MPFR_RNDN);
  Rmpfr_add($temp2, $temp2, $temp1, MPFR_RNDN);

  my $denorm1 = Rmpfr_get_NV($temp1, MPFR_RNDN);
  my $denorm2 = Rmpfr_get_NV($temp2, MPFR_RNDN);

  my @in = ( 0.1 / 10, 1.4 / 10, 2 ** ($Math::MPFR::NV_properties{bits} - 1),
            atonv('6284685476686e5'), atonv('4501259036604e6'), atonv('1411252895572e-5'),
            atonv('9.047014579199e-57'), atonv('91630634264070293e0'),
            atonv('25922126328248069e0'), $denorm1, 2 ** 0.5, $denorm2, sqrt 3.0,
            atonv('2385059e-341'), atonv('-2385059e-341'), atonv('1e-9'),
            atonv('-7373243991138e5'));

  # @py3 is 'doubles' - can't be used to check 'long double' and '__float128' builds of perl.
  my @py3 = ('0.01', '0.13999999999999999', '4503599627370496.0', '6.284685476686e+17', '4.501259036604e+18',
             '14112528.95572', '9.047014579199e-57',
             '9.163063426407029e+16', '2.5922126328248068e+16', '5e-324', '1.4142135623730951',
             '1.5e-323', '1.7320508075688772', '0.0', '-0.0', '1e-09', '-7.373243991138e+17');

###############################################
################## 53 BIT #####################

  if($Math::MPFR::NV_properties{bits} == 53) {
    print "1..8\n";

    if(nvtoa(sqrt(2.0)) == sqrt(2.0)) { print "ok 1\n" }
    else {
      warn nvtoa(sqrt(2.0)), " != sqrt(2.0)\n";
      print "not ok 1\n";
    }

    if(nvtoa($zero) eq '0.0') { print "ok 2\n" }
    else {
      warn nvtoa($zero), " ne '0.0'\n";
      print "not ok 2\n";
    }


    if(nvtoa($nzero) eq '-0.0') { print "ok 3\n" }
    else {
      unless($nzero == 0 && $] < 5.01) {
        warn nvtoa($nzero), " ne '-0.0'\n";
        print "not ok 3\n";
      }
      else {
        warn "Ignoring that this perl doesn't accommodate signed zero\n";
        print "ok 3\n";
      }
    }

    if(nvtoa($inf) eq 'Inf') { print "ok 4\n" }
    else {
      warn nvtoa($inf), " ne 'Inf'\n";
     print "not ok 4\n";
    }

    if(nvtoa($ninf) eq '-Inf') { print "ok 5\n" }
    else {
      warn nvtoa($ninf), " ne '-Inf'\n";
      print "not ok 5\n";
    }

    if(nvtoa($nan) eq 'NaN') { print "ok 6\n" }
    else {
      warn nvtoa($nan), " ne 'NaN'\n";
      print "not ok 6\n";
    }

    my $t1 = Rmpfr_init2($Math::MPFR::NV_properties{bits});
    my $t2 = Rmpfr_init2($Math::MPFR::NV_properties{bits});
    my $orig_emin = Rmpfr_get_emin();
    my $orig_emax = Rmpfr_get_emax();

    for(@in) {
      if(abs($_) >= $Math::MPFR::NV_properties{normal_min}) {
        Rmpfr_strtofr($t1, nvtoa($_), 10, MPFR_RNDN);
        eval {Rmpfr_set_NV($t2, $_, MPFR_RNDN);};	# in case NV flag is unset
        if($@) {Rmpfr_strtofr($t2, $_, 10, MPFR_RNDN)}
        if($t1 != $t2) {
          $ok = 0;
          warn "$t1 != $t2\n";
        }
      }
      else {
        # We need to subnormalize the mpfr objects.
        my $s = nvtoa($_);
        Rmpfr_set_emin($Math::MPFR::NV_properties{emin}); #(-1073);
        Rmpfr_set_emax($Math::MPFR::NV_properties{emax}); #(1024);
        my $inex = Rmpfr_strtofr($t1, $s, 10, MPFR_RNDN);
        Rmpfr_subnormalize($t1, $inex, MPFR_RNDN);

        # Rmpfr_set_NV will croak if 2nd arg does not have the NV flag set
        # and some older perls might not set that flag - in which case
        # we can fall back to Rmpfr_strtofr.

        eval {$inex = Rmpfr_set_NV($t2, $_, MPFR_RNDN);};
        if($@) { $inex = Rmpfr_strtofr($t2, $_, 10, MPFR_RNDN) }
        Rmpfr_subnormalize($t2, $inex, MPFR_RNDN);

        if($t1 != $t2) {
          $ok = 0;
          warn "$t1 != $t2\n\n";
        }

        Rmpfr_set_emin($orig_emin);
        Rmpfr_set_emax($orig_emax);
      }

    }

    if($ok) { print "ok 7\n" }
    else { print "not ok 7\n" }

    $ok = 1;


    for(my $i = 0; $i < @in; $i++) {
      my $t = nvtoa($in[$i]);
      #if($t =~ /e\-0\d\d$/i) {$t =~ s/e\-0/e-/i} # I think this would be incorrect
      if($t ne $py3[$i]) {
        unless($in[$i] == 0 && $py3[$i] eq '-0.0' && $] < 5.01) {
          $ok = 0;
          warn "$t ne $py3[$i]\n";
        }
        else {
          warn "Ignoring that this perl doesn't accommodate signed zero\n";
        }
      }
    }

    if($ok) { print "ok 8\n" }
    else { print "not ok 8\n" }

    $ok = 1;
  }

###############################################
################## 64 BIT #####################

  elsif($Math::MPFR::NV_properties{bits} == 64) {
    print "1..8\n";

    if(nvtoa(sqrt(2.0)) == sqrt(2.0)) { print "ok 1\n" }
    else {
      warn nvtoa(sqrt(2.0)), " != sqrt(2.0)\n";
      print "not ok 1\n";
    }

    if(nvtoa($zero) eq '0.0') { print "ok 2\n" }
    else {
      warn nvtoa($zero), " ne '0.0'\n";
      print "not ok 2\n";
    }

    if(nvtoa($nzero) eq '-0.0') { print "ok 3\n" }
    else {
      unless($nzero == 0 && $] < 5.01) {
        warn nvtoa($nzero), " ne '-0.0'\n";
        print "not ok 3\n";
      }
      else {
        warn "Ignoring that this perl doesn't accommodate signed zero\n";
        print "ok 3\n";
      }
    }

    if(nvtoa($inf) eq 'Inf') { print "ok 4\n" }
    else {
      warn nvtoa($inf), " ne 'Inf'\n";
     print "not ok 4\n";
    }

    if(nvtoa($ninf) eq '-Inf') { print "ok 5\n" }
    else {
      warn nvtoa($ninf), " ne '-Inf'\n";
      print "not ok 5\n";
    }

    if(nvtoa($nan) eq 'NaN') { print "ok 6\n" }
    else {
      warn nvtoa($nan), " ne 'NaN'\n";
      print "not ok 6\n";
    }

    my $t1 = Rmpfr_init2($Math::MPFR::NV_properties{bits});
    my $t2 = Rmpfr_init2($Math::MPFR::NV_properties{bits});
    my $orig_emin = Rmpfr_get_emin();
    my $orig_emax = Rmpfr_get_emax();

    push @in, 2 ** $Math::MPFR::NV_properties{min_pow},
              2 ** ($Math::MPFR::NV_properties{min_pow} + 3)  +
              2 ** ($Math::MPFR::NV_properties{min_pow} + 13) +
              2 ** ($Math::MPFR::NV_properties{min_pow} + 33);

    for(@in) {
      if(abs($_) >= $Math::MPFR::NV_properties{normal_min}) {
        Rmpfr_strtofr($t1, nvtoa($_), 10, MPFR_RNDN);
        eval {Rmpfr_set_NV($t2, $_, MPFR_RNDN);};	# in case NV flag is unset
        if($@) {Rmpfr_strtofr($t2, $_, 10, MPFR_RNDN)}
        if($t1 != $t2) {
          $ok = 0;
          warn "$t1 != $t2\n";
        }
      }
      else {
        # We need to subnormalize the mpfr objects.
        my $s = nvtoa($_);
        Rmpfr_set_emin($Math::MPFR::NV_properties{emin}); #(-16444);
        Rmpfr_set_emax($Math::MPFR::NV_properties{emax}); #(16384);
        my $inex = Rmpfr_strtofr($t1, $s, 10, MPFR_RNDN);
        Rmpfr_subnormalize($t1, $inex, MPFR_RNDN);
        $inex = Rmpfr_set_NV($t2, $_, MPFR_RNDN);
        Rmpfr_subnormalize($t2, $inex, MPFR_RNDN);

        if($t1 != $t2) {
          $ok = 0;
          warn "$t1 != $t2\n";
        }

        Rmpfr_set_emin($orig_emin);
        Rmpfr_set_emax($orig_emax);
      }

    }

    if($ok) { print "ok 7\n" }
    else { print "not ok 7\n" }

    $ok = 1;

    my @correct = qw(0.01 0.14 9223372036854775808.0 628468547668600000.0 4501259036604000000.0 14112528.95572
                     9.047014579199e-57 91630634264070293.0 25922126328248069.0 4e-4951 1.4142135623730950488
                     1e-4950 1.7320508075688772936 2.385059e-335 -2.385059e-335 1e-09 -737324399113800000.0
                     4e-4951 3.1312055444e-4941);

    for(my $i = 0; $i < @in; $i++) {
      my $t = nvtoa($in[$i]);
      if($t ne $correct[$i]) {
        unless($in[$i] == 0 && $correct[$i] eq '-0.0' && $] < 5.01) {
          $ok = 0;
          warn "$t ne $correct[$i]\n";
        }
        else {
          warn "Ignoring that this perl doesn't accommodate signed zero\n";
        }
      }
    }

    if($ok) { print "ok 8\n" }
    else { print "not ok 8\n" }

    $ok = 1;

  }

###############################################
################## 113 BIT ####################

  elsif($Math::MPFR::NV_properties{bits} == 113) {
    print "1..8\n";

    if(nvtoa(sqrt(2.0)) == sqrt(2.0)) { print "ok 1\n" }
    else {
      warn nvtoa(sqrt(2.0)), " != sqrt(2.0)\n";
      print "not ok 1\n";
    }

    if(nvtoa($zero) eq '0.0') { print "ok 2\n" }
    else {
      warn nvtoa($zero), " ne '0.0'\n";
      print "not ok 2\n";
    }


    if(nvtoa($nzero) eq '-0.0') { print "ok 3\n" }
    else {
      warn nvtoa($nzero), " ne '-0.0'\n";
      print "not ok 3\n";
    }


    if(nvtoa($inf) eq 'Inf') { print "ok 4\n" }
    else {
      warn nvtoa($inf), " ne 'Inf'\n";
     print "not ok 4\n";
    }

    if(nvtoa($ninf) eq '-Inf') { print "ok 5\n" }
    else {
      warn nvtoa($ninf), " ne '-Inf'\n";
      print "not ok 5\n";
    }

    if(nvtoa($nan) eq 'NaN') { print "ok 6\n" }
    else {
      warn nvtoa($nan), " ne 'NaN'\n";
      print "not ok 6\n";
    }

    my $t1 = Rmpfr_init2($Math::MPFR::NV_properties{bits});
    my $t2 = Rmpfr_init2($Math::MPFR::NV_properties{bits});
    my $orig_emin = Rmpfr_get_emin();
    my $orig_emax = Rmpfr_get_emax();

    push @in, 2 ** $Math::MPFR::NV_properties{min_pow},
              2 ** ($Math::MPFR::NV_properties{min_pow} + 3)  +
              2 ** ($Math::MPFR::NV_properties{min_pow} + 13) +
              2 ** ($Math::MPFR::NV_properties{min_pow} + 33);

    for(@in) {
      if(abs($_) >= $Math::MPFR::NV_properties{normal_min}) {
        Rmpfr_strtofr($t1, nvtoa($_), 10, MPFR_RNDN);
        Rmpfr_set_NV($t2, $_, MPFR_RNDN);
        if($t1 != $t2) {
          $ok = 0;
          warn "$t1 != $t2\n";
        }
      }
      else {
        # We need to subnormalize the mpfr objects.
        my $s = nvtoa($_);
        Rmpfr_set_emin($Math::MPFR::NV_properties{emin}); #(-16493);
        Rmpfr_set_emax($Math::MPFR::NV_properties{emax}); #(16384);
        my $inex = Rmpfr_strtofr($t1, $s, 10, MPFR_RNDN);
        Rmpfr_subnormalize($t1, $inex, MPFR_RNDN);
        $inex = Rmpfr_set_NV($t2, $_, MPFR_RNDN);
        Rmpfr_subnormalize($t2, $inex, MPFR_RNDN);

        if($t1 != $t2) {
          $ok = 0;
          warn "$t1 != $t2\n";
        }

        Rmpfr_set_emin($orig_emin);
        Rmpfr_set_emax($orig_emax);
      }

    }

    if($ok) { print "ok 7\n" }
    else { print "not ok 7\n" }

    $ok = 1;

    my @correct = qw(0.01 0.13999999999999999999999999999999999 5192296858534827628530496329220096.0
                     628468547668600000.0 4501259036604000000.0 14112528.95572 9.047014579199e-57
                     91630634264070293.0 25922126328248069.0 7e-4966 1.4142135623730950488016887242096982
                     2e-4965 1.7320508075688772935274463415058723 2.385059e-335 -2.385059e-335 1e-09
                    -737324399113800000.0 7e-4966 5.5621383844e-4956);

    for(my $i = 0; $i < @in; $i++) {
      my $t = nvtoa($in[$i]);
      if($t ne $correct[$i]) {
        $ok = 0;
        warn "$t ne $correct[$i]\n";
      }
    }

    if($ok) { print "ok 8\n" }
    else { print "not ok 8\n" }

    $ok = 1;
  }

###############################################
################## 2098 BIT ###################

  elsif($Math::MPFR::NV_properties{bits} == 2098) {
    print "1..8\n";

    if(nvtoa(sqrt(2.0)) == sqrt(2.0)) { print "ok 1\n" }
    else {
      warn nvtoa(sqrt(2.0)), " != sqrt(2.0)\n";
      print "not ok 1\n";
    }

    if(nvtoa($zero) eq '0.0') { print "ok 2\n" }
    else {
      warn nvtoa($zero), " ne '0.0'\n";
      print "not ok 2\n";
    }

    if(nvtoa($nzero) eq '-0.0') { print "ok 3\n" }
    else {
      unless($nzero == 0 && $] < 5.01) {
        warn nvtoa($nzero), " ne '-0.0'\n";
        print "not ok 3\n";
      }
      else {
        warn "Ignoring that this perl doesn't accommodate -0\n";
        print "ok 3\n";
      }
    }

    if(nvtoa($inf) eq 'Inf') { print "ok 4\n" }
    else {
      warn nvtoa($inf), " ne 'Inf'\n";
     print "not ok 4\n";
    }

    if(nvtoa($ninf) eq '-Inf') { print "ok 5\n" }
    else {
      warn nvtoa($ninf), " ne '-Inf'\n";
      print "not ok 5\n";
    }

    if(nvtoa($nan) eq 'NaN') { print "ok 6\n" }
    else {
      warn nvtoa($nan), " ne 'NaN'\n";
      print "not ok 6\n";
    }

    my $t1 = Rmpfr_init2($Math::MPFR::NV_properties{bits});
    my $t2 = Rmpfr_init2($Math::MPFR::NV_properties{bits});
    my $orig_emin = Rmpfr_get_emin();
    my $orig_emax = Rmpfr_get_emax();

    unshift @in, 2 ** 52, 8 + 2 ** - 100, 8 - 2 ** -100;

    push @in, 2 ** $Math::MPFR::NV_properties{min_pow},
              2 ** ($Math::MPFR::NV_properties{min_pow} + 3)  +
              2 ** ($Math::MPFR::NV_properties{min_pow} + 13) +
              2 ** ($Math::MPFR::NV_properties{min_pow} + 33);

    for(@in) {
      if(abs($_) >= $Math::MPFR::NV_properties{normal_min}) {
        Rmpfr_strtofr($t1, nvtoa($_), 10, MPFR_RNDN);
        Rmpfr_set_NV($t2, $_, MPFR_RNDN);
        my $ld1 = Rmpfr_get_NV($t1, MPFR_RNDN);
        my $ld2 = Rmpfr_get_NV($t2, MPFR_RNDN);
        if($ld1 != $ld2) {
          $ok = 0;
          warn "$_\n", scalar(reverse(unpack "h*", (pack "F<", $ld1))), " ne ",
                       scalar(reverse(unpack "h*", (pack "F<", $ld2))), "\n\n";
        }
      }
      else {
        # We need to subnormalize the mpfr objects.
        my $s = nvtoa($_);
        Rmpfr_set_emin($Math::MPFR::NV_properties{emin}); #(-16493);
        Rmpfr_set_emax($Math::MPFR::NV_properties{emin}); #(16384);
        my $inex = Rmpfr_strtofr($t1, $s, 10, MPFR_RNDN);
        Rmpfr_subnormalize($t1, $inex, MPFR_RNDN);
        $inex = Rmpfr_set_NV($t2, $_, MPFR_RNDN);
        Rmpfr_subnormalize($t2, $inex, MPFR_RNDN);

        if($t1 != $t2) {
          $ok = 0;
          warn "$t1 != $t2\n";
        }

        Rmpfr_set_emin($orig_emin);
        Rmpfr_set_emax($orig_emax);
      }

    }

    if($ok) { print "ok 7\n" }
    else { print "not ok 7\n" }

    $ok = 1;

    my @correct = ('4503599627370496.0', '8.0000000000000000000000000000007888609052210118',
                   '7.9999999999999999999999999999992111390947789882',
                   '0.00999999999999999999999999999999996', '0.14', 'Inf', '628468547668600000.0',
                   '4501259036604000000.0', '14112528.95572', '9.047014579199e-57',
                   '91630634264070293.0', '25922126328248069.0', '5e-324', '1.4142135623730950488016887242097',
                   '1.5e-323', '1.73205080756887729352744634150586', '0.0', '-0.0', '1e-09',
                   '-737324399113800000.0', '5e-324', '4.2439956333e-314');

    for(my $i = 0; $i < @in; $i++) {
      my $t = nvtoa($in[$i]);
      if($t ne $correct[$i]) {
        $ok = 0;
        warn "$t ne $correct[$i]\n";
      }
    }

    if($ok) { print "ok 8\n" }
    else { print "not ok 8\n" }

    $ok = 1;

  }

  else {
    print "1..1\n";
    warn "Error: Unrecognized nvtype\n";
    print "not ok 1\n";
  }
}

__END__


for(@in) {
   my $for_python = sprintf("%.${p}e", $_);
   my $py = `python3 -c \"print($for_python)\"`;
   chomp $py;
   push @py3, $py;
}

print join "', ", @py3;


