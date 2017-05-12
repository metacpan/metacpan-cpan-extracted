use strict;
use warnings;
use Config;
use Math::GMPf qw(:mpf);

my $t = 26;

print "1..", $t * 2, "\n";

# Assuming that ivsize is either 4 or 8.

my $uv_max = ~0;
my $iv_max = $uv_max == 4294967295 ? 2147483647 : 9223372036854775807;
my $iv_min = ($iv_max * -1) - 1;
my $prec = $Config{ivsize} * 8;

my($uv_max_string, $iv_max_string, $iv_min_string, $con);

if($prec == 64) {
  $uv_max_string = '0.18446744073709551615e20';
  $iv_max_string = '0.9223372036854775807e19';
  $iv_min_string = '-0.9223372036854775808e19';
}
else {
  $uv_max_string = '0.4294967295e10';
  $iv_max_string = '0.2147483647e10';
  $iv_min_string = '-0.2147483648e10';
}

warn "\n # uv_max: $uv_max\n";
warn " # iv_max: $iv_max\n";
warn " # iv_min: $iv_min\n";

for my $it(0, $t) {

  Rmpf_set_default_prec($prec * $it);

  if($uv_max == Math::GMPf::MATH_GMPf_UV_MAX()) {print "ok ", 1 + $it, "\n"}
  else {
    warn "\n $uv_max != ", Math::GMPf::MATH_GMPf_UV_MAX(), "\n";
    print "not ok ", 1 + $it, "\n";
  }

  if($iv_max == Math::GMPf::MATH_GMPf_IV_MAX()) {print "ok ", 2 + $it, "\n"}
  else {
    warn "\n $iv_max != ", Math::GMPf::MATH_GMPf_IV_MAX(), "\n";
    print "not ok ", 2 + $it, "\n";
  }

  if($iv_min == Math::GMPf::MATH_GMPf_IV_MIN()) {print "ok ", 3 + $it, "\n"}
  else {
    warn "\n $iv_min != ", Math::GMPf::MATH_GMPf_IV_MIN(), "\n";
    print "not ok ", 3 + $it, "\n";
  }

  my $mpf_uv_max = Math::GMPf->new("$uv_max");
  my $mpf_iv_max = Math::GMPf->new("$iv_max");
  my $mpf_iv_min = Math::GMPf->new("$iv_min");

  if($uv_max == $mpf_uv_max) {print "ok ", 4 + $it, "\n"}
  else {
    warn "\n $uv_max != $mpf_uv_max\n";
    print "not ok ", 4 + $it, "\n";
  }

  if($iv_max == $mpf_iv_max) {print "ok ", 5 + $it, "\n"}
  else {
    warn "\n $iv_max != $mpf_iv_max\n";
    print "not ok ", 5 + $it, "\n";
  }

  if($iv_min == $mpf_iv_min) {print "ok ", 6 + $it, "\n"}
  else {
    warn "\n $iv_min != $mpf_iv_min\n";
    print "not ook ", 6 + $it, "\n";
  }

  if($uv_max_string eq "$mpf_uv_max") {print "ok ", 7 + $it, "\n"}
  else {
    warn "\n $uv_max_string ne $mpf_uv_max\n";
    print "not ok ", 7 + $it, "\n";
  }

  if($iv_max_string eq "$mpf_iv_max") {print "ok ", 8 + $it, "\n"}
  else {
    warn "\n $iv_max_string ne $mpf_iv_max\n";
    print "not ok ", 8 + $it, "\n";
  }

  if($iv_min_string eq "$mpf_iv_min") {print "ok ", 9 + $it, "\n"}
  else {
    warn "\n $iv_min_string ne $mpf_iv_min\n";
    print "not ok ", 9 + $it, "\n";
  }

  if(Rmpf_fits_UV_p($mpf_uv_max)) {print "ok ", 10 + $it, "\n"}
  else {
    warn "\n $mpf_uv_max doesn't fit into a UV\n";
    print "not ok ", 10 + $it, "\n";
  }

  if(!Rmpf_fits_UV_p($mpf_uv_max + 1)) {print "ok ", 11 + $it, "\n"}
  else {
    warn "\n ", $mpf_uv_max + 1, " fits into a UV\n";
    print "not ok ", 11 + $it, "\n";
  }

  if(Rmpf_fits_IV_p($mpf_iv_max)) {print "ok ", 12 + $it, "\n"}
  else {
    warn "\n $mpf_iv_max doesn't fit into an IV\n";
    print "not ok ", 12 + $it, "\n";
  }

  if(!Rmpf_fits_IV_p($mpf_iv_max + 1)) {print "ok ", 13 + $it, "\n"}
  else {
    warn "\n ", $mpf_iv_max + 1, " fits into an IV\n";
    print "not ok ", 13 + $it, "\n";
  }

  if(Rmpf_fits_IV_p($mpf_iv_min)) {print "ok ", 14 + $it, "\n"}
  else {
    warn "\n $mpf_iv_min doesn't fit into an IV\n";
    print "not ok ", 14 + $it, "\n";
  }

  if(!Rmpf_fits_IV_p($mpf_iv_min - 1)) {print "ok ", 15 + $it, "\n"}
  else {
    warn "\n ", $mpf_iv_min - 1, " fits into an IV\n";
   print "not ok ", 15 + $it, "\n";
  }

  my $check = Math::GMPf->new();

  Rmpf_set_IV($check, $uv_max);
  if($check == $mpf_uv_max) {print "ok ", 16 + $it, "\n"}
  else {
    warn "\n $check != $mpf_uv_max\n";
    print "not ok ", 16 + $it, "\n";
  }

  if(Rmpf_get_IV($check) == $uv_max) {print "ok ", 17 + $it, "\n"}
  else {
    warn "\n ", Rmpf_get_IV($check), " != $uv_max\n";
    print "not ok ", 17 + $it, "\n";
  }

  Rmpf_set_IV($check, $iv_max);
  if($check == $mpf_iv_max) {print "ok ", 18 + $it, "\n"}
  else {
    warn "\n $check != $mpf_iv_max\n";
    print "not ok ", 18 + $it, "\n";
  }

  if(Rmpf_get_IV($check) == $iv_max) {print "ok ", 19 + $it, "\n"}
  else {
    warn "\n ", Rmpf_get_IV($check), " != $iv_max\n";
    print "not ok ", 19 + $it, "\n";
  }

  Rmpf_set_IV($check, $iv_min);
  if($check == $mpf_iv_min) {print "ok ", 20 + $it, "\n"}
  else {
    warn "\n $check != $mpf_iv_min\n";
    print "not ok ", 20 + $it, "\n";
  }

  if(Rmpf_get_IV($check) == $iv_min) {print "ok ", 21 + $it, "\n"}
  else {
    warn "\n ", Rmpf_get_IV($check), " != $iv_min\n";
    print "not ok ", 21 + $it, "\n";
  }

  eval{$con = Rmpf_get_IV($mpf_uv_max + 22);};

  if($@ =~ /^Argument supplied to Rmpf_get_IV does not fit into a UV/) {print "ok ", 22 + $it, "\n"}
  else {
    warn "\n \$\@: $@\n";
    print "not ok ", 22 + $it, "\n";
  }

  $con = Rmpf_get_IV($mpf_uv_max + 0.99);

  if($con == $uv_max) {print "ok ", 23 + $it, "\n"}
  else {
    warn "\n $con != $uv_max\n";
    print "not ok ", 23 + $it, "\n";
  }

  eval{$con = Rmpf_get_IV($mpf_iv_min -1);};

  if($@ =~ /^Argument supplied to Rmpf_get_IV does not fit into an IV/) {print "ok ", 24 + $it, "\n"}
  else {
    warn "\n \$\@: $@\n";
    print "not ok ", 24 + $it, "\n";
  }

  $con = Rmpf_get_IV($mpf_iv_min - 0.99);

  if($con == $iv_min) {print "ok ", 25 + $it, "\n"}
  else {
    warn "\n $con != $iv_min\n";
    print "not ok ", 25 + $it, "\n";
  }

  $con = Rmpf_get_IV($mpf_iv_max + 1001);
  if($con == $iv_max + 1001) {print "ok ", 26 + $it, "\n"}
  else {
    warn "\n $con != ", $iv_max + 1001, "\n";
    print "not ok ", 26 + $it, "\n";
  }
}
