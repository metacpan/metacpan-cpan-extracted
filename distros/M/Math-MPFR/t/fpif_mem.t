# Testing of Rmpfr_fpif_export_mem() and Rmpfr_fpif_import_mem
# which were added mpfr-4.3.0-dev.
# Testing of Rmpfr_fpif_export() and Rmpfr_fpif_import(), which
# were added in mpfr-4.0.0, is performed in new_in_4.0.0.t

use strict;
use warnings;

use Math::MPFR qw(:mpfr);

use Test::More;

*PV_CUR = \&Math::MPFR::_SvCUR;

my $len = 16;
my $string;

my $zero_obj = Math::MPFR->new(0);
my $op = Rmpfr_init2(100);   # 100-bit precision;

my $rop = Math::MPFR->new(); # 53-bit precision

Rmpfr_const_pi($op, MPFR_RNDN);

if(262912 > MPFR_VERSION) {
  eval { my $ret = Rmpfr_fpif_export_mem($string, $len, $op);};
  like($@, qr/^Rmpfr_fpif_export_mem not implemented/, "Test 1 ok");

  eval{ my $ret = Rmpfr_fpif_import_mem($rop, $string, $len);};
  like($@, qr/^Rmpfr_fpif_import_mem not implemented/, "Test 2 ok");
}
else {
  my $ret = Rmpfr_fpif_export_mem($string, $len, $op);
  cmp_ok($ret, '==', 0, "Test 1 export ok");

  cmp_ok(PV_CUR($string) + 1, '==', $len, "Test 2 import string CUR ok");
  $ret = Rmpfr_fpif_import_mem($rop, $string, $len);
  cmp_ok($ret, '==', 0, "Test 2 import ok");

  cmp_ok(ref($rop), 'eq', 'Math::MPFR', "Test 3 import returned a Math::MPFR object");
  cmp_ok(Rmpfr_get_prec($rop), '==', 100, "Test 4 precision altered to 100");
  cmp_ok($rop, '==', $rop, "Test 5 value survived round trip");

  # Check that this string equates with what gets written to file by Rmpfr_fpif_export.

  my $file = 'fpif_mem.txt';
  my $check = '';

  my $success = open my $wr, '>', $file;
  if($success) {
    binmode($wr);

    $ret = Rmpfr_fpif_export($wr, $op);
    cmp_ok($ret, '==', 0, "Test 5 - Export to file ok");

    $success = open my $rd, '<', $file;
    if($success) {

      $check = <$rd>;

      #########################################################
      # Remove the NULL padding which perl can see that $string
      # might contain before comparing $check with $string.
      while ( length($string) > length($check) ) {
        if( substr($string, -1, 1) eq chr(0)) {chop $string}
        else {last}
      }
      #########################################################

      cmp_ok($string, 'eq', $check, "Test 6 - buffer content matches file content");
    }
    else { warn "Failed to open $file for reading: $!" };
  }
  else {
    warn "Failed to open $file for writing: $!";
  }

  #####################################################
  my $emin = Rmpfr_get_emin();
  my @exps = ($emin);
  while ($emin < -5) {
    $emin = int($emin / (3 + int(rand(4))) ); #
    push @exps, $emin;
  }

  #my $emax = Rmpfr_get_emax();
  #my @exps = ($emax);
  #while ($emax > 5) {
  #  $emax = int($emax / 5);
  #  push @exps, $emax;
  #}

  my $max_prec = 1e8;
  $max_prec = RMPFR_PREC_MAX if RMPFR_PREC_MAX < $max_prec;
  my @precs = ($max_prec);

  while ($max_prec > 5) {
    $max_prec = int($max_prec / (3 + int(rand(4))) ); #
    push @precs, $max_prec;
  }

  my $irregular_size = 7; # The size, including the terminating NULL byte
                          # that's being allocated for Infs, NaNs and zeros.)

  for(my $i = scalar(@precs) - 1; $i >= 0; $i--) {
  #for(my $i = 0; $i < scalar(@precs); $i++) {
    my $obj = Rmpfr_init2($precs[$i]);
    my $ret = Rmpfr_fpif_export_mem(my $irregular_string, $irregular_size, $obj);
    cmp_ok($ret, '==', 0, "7 OK for NaN prec $precs[$i] and exponent " . Rmpfr_get_exp($obj));

    if(!$ret) {
      cmp_ok(PV_CUR($irregular_string) + 1, '==', $irregular_size, "NaN import string CUR ok");
      cmp_ok(PV_CUR($irregular_string), '==', length($irregular_string), "NaN import string length ok");
      $ret = Rmpfr_fpif_import_mem($rop, $irregular_string, $irregular_size);
      cmp_ok($ret, '==', 0, "Import OK for NaN: prec $precs[$i] and exponent " . Rmpfr_get_exp($obj));
      if(!$ret) {
        cmp_ok(Rmpfr_nan_p($rop), '!=', 0, "Imported value is a NaN: prec $precs[$i] and exponent " . Rmpfr_get_exp($obj));
        cmp_ok(Rmpfr_get_prec($rop), '==', $precs[$i], "NaN Precision preserved: $precs[$i]");
      }
    }

    Rmpfr_set_inf($obj, 1);

    $ret = Rmpfr_fpif_export_mem($irregular_string, $irregular_size, $obj);
    cmp_ok($ret, '==', 0, "7 OK for +Inf prec $precs[$i] and exponent " . Rmpfr_get_exp($obj));

    if(!$ret) {
      cmp_ok(PV_CUR($irregular_string) + 1, '==', $irregular_size, "+Inf import string CUR ok");
      cmp_ok(PV_CUR($irregular_string), '==', length($irregular_string), "+Inf import string length ok");
      $ret = Rmpfr_fpif_import_mem($rop, $irregular_string, $irregular_size);
      cmp_ok($ret, '==', 0, "Import OK for +Inf: prec $precs[$i] and exponent " . Rmpfr_get_exp($obj));
      if(!$ret) {
        cmp_ok($rop, '>', 0, "Imported value is +ve: prec $precs[$i] and exponent " . Rmpfr_get_exp($obj));
        cmp_ok(Rmpfr_inf_p($rop), '!=', 0, "Imported value is an Inf: prec $precs[$i] and exponent " . Rmpfr_get_exp($obj));
        cmp_ok(Rmpfr_get_prec($rop), '==', $precs[$i], "+Inf Precision preserved: $precs[$i]");
      }
    }

    Rmpfr_set_inf($obj, -1);
    $ret = Rmpfr_fpif_export_mem($irregular_string, $irregular_size, $obj);
    cmp_ok($ret, '==', 0, "7 OK for -Inf prec $precs[$i] and exponent " . Rmpfr_get_exp($obj));

    if(!$ret) {
      cmp_ok(PV_CUR($irregular_string) + 1, '==', $irregular_size, "-Inf import string CUR ok");
      cmp_ok(PV_CUR($irregular_string), '==', length($irregular_string), "-Inf import string length ok");
      $ret = Rmpfr_fpif_import_mem($rop, $irregular_string, $irregular_size);
      cmp_ok($ret, '==', 0, "Import OK for -Inf: prec $precs[$i] and exponent " . Rmpfr_get_exp($obj));
      if(!$ret) {
        cmp_ok($rop, '<', 0, "Imported value is -ve: prec $precs[$i] and exponent " . Rmpfr_get_exp($obj));
        cmp_ok(Rmpfr_inf_p($rop), '!=', 0, "Imported value is an Inf: prec $precs[$i] and exponent " . Rmpfr_get_exp($obj));
        cmp_ok(Rmpfr_get_prec($rop), '==', $precs[$i], "-Inf Precision preserved: $precs[$i]");
      }
    }

    Rmpfr_set_zero($obj, 1);
    $ret = Rmpfr_fpif_export_mem($irregular_string, $irregular_size, $obj);
    cmp_ok($ret, '==', 0, "7 OK for +0 prec $precs[$i] and exponent " . Rmpfr_get_exp($obj));

    if(!$ret) {
      cmp_ok(PV_CUR($irregular_string) + 1, '==', $irregular_size, "+0 import string CUR ok");
      cmp_ok(PV_CUR($irregular_string), '==', length($irregular_string), "+0 import string length ok");
      $ret = Rmpfr_fpif_import_mem($rop, $irregular_string, $irregular_size);
      cmp_ok($ret, '==', 0, "Import OK for +0: prec $precs[$i] and exponent " . Rmpfr_get_exp($obj));
      if(!$ret) {
        cmp_ok(Rmpfr_signbit($rop), '==', 0, "Imported value is +ve: prec $precs[$i] and exponent " . Rmpfr_get_exp($obj));
        cmp_ok(Rmpfr_zero_p($rop), '!=', 0, "Imported value is a zero: prec $precs[$i] and exponent " . Rmpfr_get_exp($obj));
        cmp_ok(Rmpfr_get_prec($rop), '==', $precs[$i], "+0 Precision preserved: $precs[$i]");
      }
    }

    Rmpfr_set_zero($obj, -1);
    $ret = Rmpfr_fpif_export_mem($irregular_string, $irregular_size, $obj);
    cmp_ok($ret, '==', 0, "7 OK for -0 prec $precs[$i] and exponent " . Rmpfr_get_exp($obj));

    if(!$ret) {
      cmp_ok(PV_CUR($irregular_string) + 1, '==', $irregular_size, "-0 import string CUR ok");
      cmp_ok(PV_CUR($irregular_string), '==', length($irregular_string), "-0 import string length ok");
      $ret = Rmpfr_fpif_import_mem($rop, $irregular_string, $irregular_size);
      cmp_ok($ret, '==', 0, "Import OK for -0: prec $precs[$i] and exponent " . Rmpfr_get_exp($obj));
      if(!$ret) {
        cmp_ok(Rmpfr_signbit($rop), '!=', 0, "Imported value is -ve: prec $precs[$i] and exponent " . Rmpfr_get_exp($obj));
        cmp_ok(Rmpfr_zero_p($rop), '!=', 0, "Imported value is a zero: prec $precs[$i] and exponent " . Rmpfr_get_exp($obj));
        cmp_ok(Rmpfr_get_prec($rop), '==', $precs[$i], "-0 Precision preserved: $precs[$i]");
      }
    }

    my $input;
    if( int(rand(2)) ) { $input = rand() }
    else {$input = 0.1 }
    Rmpfr_strtofr($obj, "$input", 10, MPFR_RNDN);

    for(my $j = scalar(@exps) - 1; $j >= 0; $j--) {
    #for(my $j = 0; $j < scalar(@exps); $j++) {
      Rmpfr_set_exp($obj, $exps[$j]);
      die "Inf or Nan ($obj) encountered in test script" if( Rmpfr_inf_p($obj) || Rmpfr_nan_p($obj) );
      if(Rmpfr_zero_p($obj)) { Rmpfr_nextbelow($obj) }
      else { Rmpfr_nexttoward($obj, $zero_obj) }
      my $size = Rmpfr_fpif_size($obj) + 1;
      my $exported = Rmpfr_fpif_export_mem(my $s, $size, $obj);
      cmp_ok($exported, '==', 0, "$size OK for $input, prec $precs[$i] and exponent $exps[$j]");

      if(!$exported) {
        cmp_ok(PV_CUR($s) + 1, '==', $size, "$input, prec $precs[$i] and exponent $exps[$j]: import string CUR ok");
        cmp_ok(PV_CUR($s), '==', length($s), "$input, prec $precs[$i] and exponent $exps[$j]: import string length ok");
        my $imported = Rmpfr_fpif_import_mem($rop, $s, $size);
        cmp_ok($imported, '==', 0, "Successful import reported: $input, prec $precs[$i] and exponent $exps[$j]");
        $rop = Math::MPFR->new(1) if Rmpfr_nan_p($rop);
        if(!$imported) {
          cmp_ok(Rmpfr_get_prec($rop), '==', Rmpfr_get_prec($obj), "Precisions match for $input, prec $precs[$i] and exponent $exps[$j]");
          cmp_ok($rop, '==', $obj, "Values match for $input, prec $precs[$i] and exponent $exps[$j]");
        }
      }
    }
  }
  # print "@precs\n@exps\n";
#####################
}
done_testing();
#####################

