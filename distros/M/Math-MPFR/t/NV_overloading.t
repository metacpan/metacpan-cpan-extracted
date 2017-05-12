# Mainly want to test that:
# inf and nan are handled correctly when passed to overloaded subs (including when they're passed as strings)
# valid floating point NV's are handled correctly when passed to overloaded subs
# invalid floating point values are a fatal error when passed as a string

use strict;
use warnings;
use Math::MPFR qw(:mpfr);

print "1..119\n";

my $inf  = 999 ** (999 ** 999);
my $ninf = $inf * -1;
my $nan  = $inf / $inf;
my $strinf = 999 ** (999 ** 999);
my $strninf = $strinf * -1;
my $strnan = $strinf / $strinf;
my ($ret, $x);

$ret = Math::MPFR->new(10) *  $inf;
if($ret > 0 && Rmpfr_inf_p($ret)) {print "ok 1\n"}
else {
  warn "\n Expected '\@Inf\@'\n Got $ret\n";
  print "not ok 1\n";
}

$ret = Math::MPFR->new(10) * "$strinf";
if($ret > 0 && Rmpfr_inf_p($ret)) {print "ok 2\n"}
else {
  warn "\n Expected '\@Inf\@'\n Got $ret\n";
  print "not ok 2\n";
}


$ret = Math::MPFR->new(10) *  $nan;
if(Rmpfr_nan_p($ret)) {print "ok 3\n"}
else {
  warn "\n Expected '\@NaN\@'\n Got $ret\n";
  print "not ok 3\n";
}

$ret = Math::MPFR->new(10) * "$strnan";
if(Rmpfr_nan_p($ret)) {print "ok 4\n"}
else {
  warn "\n Expected '\@NaN\@'\n Got $ret\n";
  print "not ok 4\n";
}

$ret = Math::MPFR->new(10) * "61.2";
if($ret == 612) {print "ok 5\n"}
else {
  warn "\n Expected '612'\n Got $ret\n";
  print "not ok 5\n";
}

if(Math::MPFR->new(10) * 61.2 == 612) {
  print "ok 6\n";
}
else {
  warn "\n Expected:\n   612\n Got: ",
                    Math::MPFR->new(10) * 61.2, "\n";
  print "not ok 6\n";
}

$ret = Math::MPFR->new(10) +  $inf;
if($ret > 0 && Rmpfr_inf_p($ret)) {print "ok 7\n"}
else {
  warn "\n Expected '\@Inf\@'\n Got $ret\n";
  print "not ok 7\n";
}

$ret = Math::MPFR->new(10) + "$strinf";
if($ret > 0 && Rmpfr_inf_p($ret)) {print "ok 8\n"}
else {
  warn "\n Expected '\@Inf\@'\n Got $ret\n";
  print "not ok 8\n";
}

$ret = Math::MPFR->new(10) +  $nan;
if(Rmpfr_nan_p($ret)) {print "ok 9\n"}
else {
  warn "\n Expected '\@NaN\@'\n Got $ret\n";
  print "not ok 9\n";
}

$ret = Math::MPFR->new(10) + "$strnan";
if(Rmpfr_nan_p($ret)) {print "ok 10\n"}
else {
  warn "\n Expected '\@NaN\@'\n Got $ret\n";
  print "not ok 10\n";
}

eval{$ret = Math::MPFR->new(10) + "61.2"};
if($ret > 71.19999999 && $ret < 71.20000001) {print "ok 11\n"}
else {
  warn "\n Expected approx 71.2\n Got ", Math::MPFR->new(10) + "61.2", "\n";
  print "not ok 11\n";
}

if(Math::MPFR->new(10) + 61.2 == '71.2') {
  print "ok 12\n";
}
else {
  warn "\n Expected: 71.2\n Got: ",
                   Math::MPFR->new(10) + 61.2, "\n";
  print "not ok 12\n";
}

$ret = Math::MPFR->new(10) /  $inf;
if($ret == 0 && !Rmpfr_signbit($ret)) {print "ok 13\n"}
else {
  warn "\n Expected 0\n Got $ret\n";
  print "not ok 13\n";
}

$ret = Math::MPFR->new(10) / "$strinf";
if($ret == 0 && !Rmpfr_signbit($ret)) {print "ok 14\n"}
else {
  warn "\n Expected 0\n Got $ret\n";
  print "not ok 14\n";
}

$ret = Math::MPFR->new(10) /  $nan;
if(Rmpfr_nan_p($ret)) {print "ok 15\n"}
else {
  warn "\n Expected '\@NaN\@'\n Got $ret\n";
  print "not ok 15\n";
}

$ret = Math::MPFR->new(10) / "$strnan";
if(Rmpfr_nan_p($ret)) {print "ok 16\n"}
else {
  warn "\n Expected '\@NaN\@'\n Got $ret\n";
  print "not ok 16\n";
}
$ret = Math::MPFR->new(10) / "61.2";
if($ret > 0.1633986928104575 && $ret < 0.16339869281045754) {print "ok 17\n"}
else {
  warn "\n 17: Got $ret\n";
  print "not ok 17\n";
}

if(Math::MPFR->new(10) / 61.2 > '0.1633986928104575' &&
   Math::MPFR->new(10) / 61.2 < '0.16339869281045754') {
  print "ok 18\n";
}
else {
  warn "\n 18: Got: ", Math::MPFR->new(10) / 61.2, "\n";
  print "not ok 18\n";
}

$ret = Math::MPFR->new(10) -  $inf;
if($ret < 0 && Rmpfr_inf_p($ret)) {print "ok 19\n"}
else {
  warn "\n Expected '\@Inf\@'\n Got $ret\n";
  print "not ok 19\n";
}

$ret = Math::MPFR->new(10) - "$strinf";
if($ret < 0 && Rmpfr_inf_p($ret)) {print "ok 20\n"}
else {
  warn "\n Expected '\@Inf\@'\n Got $ret\n";
  print "not ok 20\n";
}

$ret = Math::MPFR->new(10) -  $nan;
if(Rmpfr_nan_p($ret)) {print "ok 21\n"}
else {
  warn "\n Expected '\@NaN\@'\n Got $ret\n";
  print "not ok 21\n";
}

$ret = Math::MPFR->new(10) - "$strnan";
if(Rmpfr_nan_p($ret)) {print "ok 22\n"}
else {
  warn "\n Expected '\@NaN\@'\n Got $ret\n";
  print "not ok 22\n";
}

$ret = Math::MPFR->new(10) - "61.2";
if($ret > -51.20000001 && $ret < -51.19999999) {print "ok 23\n"}
else {
  warn "\n 23: Got $ret\n";
  print "not ok 23\n";
}

if(Math::MPFR->new(10) - 61.2 == '-51.2') {
  print "ok 24\n";
}
else {
  warn "\n 24: Got $ret\n";
  print "not ok 24\n";
}

$ret = Math::MPFR->new(10);

$ret *=  $inf;
if($ret > 0 && Rmpfr_inf_p($ret)) {print "ok 25\n"}
else {
  warn "\n Expected '\@Inf\@'\n Got $ret\n";
  print "not ok 25\n";
}

$ret *= "$strinf";
if($ret > 0 && Rmpfr_inf_p($ret)) {print "ok 26\n"}
else {
  warn "\n Expected '\@Inf\@'\n Got $ret\n";
  print "not ok 26\n";
}

$ret *=  $nan;
if(Rmpfr_nan_p($ret)) {print "ok 27\n"}
else {
  warn "\n Expected '\@NaN\@'\n Got $ret\n";
  print "not ok 27\n";
}

$ret *= "$strnan";
if(Rmpfr_nan_p($ret)) {print "ok 28\n"}
else {
  warn "\n Expected '\@NaN\@'\n Got $ret\n";
  print "not ok 28\n";
}

Rmpfr_set_ui($ret, 10, MPFR_RNDN);

$ret *= "61.2";
if($ret == 612) {print "ok 29\n"}
else {
  warn "\n 29: Got $ret\n";
  print "not ok 29\n";
}

Rmpfr_set_ui($ret, 10, MPFR_RNDN);

$ret *= 61.2;

if($ret == '612') {print "ok 30\n"}
else {
  warn "\n Expected:\n 612\nGot: $ret\n";
  print "not ok 30\n";
}

$ret +=  $inf;
if($ret > 0 && Rmpfr_inf_p($ret)) {print "ok 31\n"}
else {
  warn "\n Expected '\@Inf\@'\n Got $ret\n";
  print "not ok 31\n";
}

$ret += "$strinf";
if($ret > 0 && Rmpfr_inf_p($ret)) {print "ok 32\n"}
else {
  warn "\n Expected '\@Inf\@'\n Got $ret\n";
  print "not ok 32\n";
}

$ret +=  $nan;
if(Rmpfr_nan_p($ret)) {print "ok 33\n"}
else {
  warn "\n Expected '\@NaN\@'\n Got $ret\n";
  print "not ok 33\n";
}

$ret += "$strnan";
if(Rmpfr_nan_p($ret)) {print "ok 34\n"}
else {
  warn "\n Expected '\@NaN\@'\n Got $ret\n";
  print "not ok 34\n";
}

Rmpfr_set_ui($ret, 10, MPFR_RNDN);

$ret += "61.2";
if($ret > 71.19999999 && $ret < 71.20000001) {print "ok 35\n"}
else {
  warn "\n Expected approx 71.2\n Got $ret\n";
  print "not ok 35\n";
}

Rmpfr_set_ui($ret, 10, MPFR_RNDN);

$ret += 61.2;

if($ret == '71.2') {print "ok 36\n"}
else {
  warn "\n Expected 71.2\n Got $ret\n";
  print "not ok 36\n";
}

$ret -=  $inf;
if($ret < 0 && Rmpfr_inf_p($ret)) {print "ok 37\n"}
else {
  warn "\n Expected '\@Inf\@'\n Got $ret\n";
  print "not ok 37\n";
}

$ret -= "$strinf";
if($ret < 0 && Rmpfr_inf_p($ret)) {print "ok 38\n"}
else {
  warn "\n Expected '\@Inf\@'\n Got $ret\n";
  print "not ok 38\n";
}

$ret -=  $nan;
if(Rmpfr_nan_p($ret)) {print "ok 39\n"}
else {
  warn "\n Expected '\@NaN\@'\n Got $ret\n";
  print "not ok 39\n";
}

$ret -= "$strnan";
if(Rmpfr_nan_p($ret)) {print "ok 40\n"}
else {
  warn "\n Expected '\@NaN\@'\n Got $ret\n";
  print "not ok 40\n";
}

Rmpfr_set_ui($ret, 10, MPFR_RNDN);

$ret -= "61.2";
if($ret > -51.20000001 && $ret < -51.19999999) {print "ok 41\n"}
else {
  warn "\n Expected -51.2\n Got $ret\n";
  print "not ok 41\n";
}

Rmpfr_set_ui($ret, 10, MPFR_RNDN);

$ret -= 61.2;

if($ret == '-51.2') {print "ok 42\n"}
else {
  warn "\n Expected: -51.2\n Got: $ret\n";
  print "not ok 42\n";
}

$ret /=  $inf;
if(Rmpfr_zero_p($ret) && Rmpfr_signbit($ret)) {print "ok 43\n"}
else {
  warn "\n Expected -0\n Got $ret\n";
  print "not ok 43\n";
}

eval{$ret /= "$strinf"};
if(Rmpfr_zero_p($ret) && Rmpfr_signbit($ret)) {print "ok 44\n"}
else {
  warn "\n Expected -0\n Got $ret\n";
  print "not ok 44\n";
}

$ret /=  $nan;
if(Rmpfr_nan_p($ret)) {print "ok 45\n"}
else {
  warn "\n Expected '\@NaN\@'\n Got $ret\n";
  print "not ok 45\n";
}

$ret /= "$strnan";
if(Rmpfr_nan_p($ret)) {print "ok 46\n"}
else {
  warn "\n Expected '\@NaN\@'\n Got $ret\n";
  print "not ok 46\n";
}

Rmpfr_set_ui($ret, 10, MPFR_RNDN);

$ret /= "61.2";
if($ret > 0.1633986928104575 && $ret < 0.16339869281045754) {print "ok 47\n"}
else {
  warn "\n 17: Got $ret\n";
  print "not ok 47\n";
}

Rmpfr_set_ui($ret, 10, MPFR_RNDN);

$ret /= 61.2;
if($ret > '0.1633986928104575' && $ret < '0.16339869281045754') {print "ok 48\n"}
else {
  warn "\n 17: Got $ret\n";
  print "not ok 48\n";
}

if(Math::MPFR->new(10) ==  $inf ) {
  warn "\n 10 == $inf\n";
  print "not ok 49\n";
}
else {print "ok 49\n"}

if(Math::MPFR->new(10) ==  $ninf ) {
  warn "\n 10 == $ninf\n";
  print "not ok 50\n";
}
else {print "ok 50\n"}

if("$strinf" =~ /^inf/i || $^O =~ /MSWin/) {
  if(Math::MPFR->new(10) == "$strinf") {
    warn "\n 10 == infinity\n";
    print "not ok 51\n";
  }
  else {print "ok 51\n"}
}
else {
  $x = (Math::MPFR->new(10) == "$strinf");
  if(!$x) {print "ok 51\n"}
  else {
    warn "\n 10 == inf\n";
    print "not ok 51\n";
  }
}

$x = (Math::MPFR->new(10) ==  $nan );
if(!$x) {print "ok 52\n"}
else {
  warn "\n 10 == nan\n";
  print "not ok 52\n";
}

$x = (Math::MPFR->new(10) == "$strnan");
if(!$x) {print "ok 53\n"}
else {
  warn "\n 10 == nan\n";
  print "not ok 53\n";
}

$x = (Math::MPFR->new(10) == "61.2");
if(!$x) {print "ok 54\n"}
else {
  warn "\n 10 == nan\n";
  print "not ok 54\n";
}

my $dec = 10.0;
if(Math::MPFR->new(10) == $dec) {print "ok 55\n"}
else {
  warn "\n ", Math::MPFR->new(10), " != $dec\n";
  print "not ok 55\n";
}

if(Math::MPFR->new(10) !=  $inf ) {print "ok 56\n"}
else {
  warn "\n 10 == $inf\n";
  print "not ok 56\n";
}

if(Math::MPFR->new(10) !=  $ninf ) {print "ok 57\n"}
else {
  warn "\n 10 == $ninf\n";
  print "not ok 57\n";
}

if("$strinf" =~ /^inf/i || $^O =~ /MSWin/) {
  if(Math::MPFR->new(10) != "$strinf") {print "ok 58\n"}
  else {
    warn "\n 10 == infinity\n";
    print "not ok 58\n";
  }
}
else {
  eval{$x = (Math::MPFR->new(10) != "$strinf")};
  if($@ =~ /Invalid string supplied to Math::MPFR::overload_not_equiv/) {print "ok 58\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 58\n";
  }
}

$x = (Math::MPFR->new(10) !=  $nan );
if($x) {print "ok 59\n"}
else {
  warn "\n 10 == NaN\n";
  print "not ok 59\n";
}

$x = (Math::MPFR->new(10) != "$strnan");
if($x) {print "ok 60\n"}
else {
  warn "\n 10 == NaN\n";
  print "not ok 60\n";
}

$x = (Math::MPFR->new(10) != "61.2");
if($x) {print "ok 61\n"}
else {
  warn "\n 10 == 61.2\n";
  print "not ok 61\n";
}

$dec += 0.9;;
if(Math::MPFR->new(10) != $dec) {print "ok 62\n"}
else {
  warn "\n ", Math::MPFR->new(10), " == $dec\n";
  print "not ok 62\n";
}

if(Math::MPFR->new(10) <  $inf ) {print "ok 63\n"}
else {
  warn "\n 10 >= $inf\n";
  print "not ok 63\n";
}

if(Math::MPFR->new(10) <  $ninf ) {
  warn "\n10 < $ninf\n";
  print "not ok 64\n";
}
else {print "ok 64\n"}

if(Math::MPFR->new(10) < "$strinf") {print "ok 65\n"}
else {
  warn "\n 10 >= $strinf\n";
  print "not ok 65\n";
}

$x = (Math::MPFR->new(10) <  $nan );
if(!$x) {print "ok 66\n"}
else {
  warn "\n 10 < NaN\n";
  print "not ok 66\n";
}

$x = (Math::MPFR->new(10) < "$strnan");
if(!$x) {print "ok 67\n"}
else {
  warn "\n 10 < NaN\n";
  print "not ok 67\n";
}

$x = (Math::MPFR->new(10) < "61.2");
if($x) {print "ok 68\n"}
else {
  warn "\n 10 >= 61.2\n";
  print "not ok 68\n";
}

$dec += 2.0;

if(Math::MPFR->new(10) < $dec) {print "ok 69\n"}
else {
  warn "\n ", Math::MPFR->new(10), " !< $dec\n";
  print "not ok 69\n";
}

if(Math::MPFR->new(10) <=  $inf ) {print "ok 70\n"}
else {
  warn "\n 10 > $inf\n";
  print "not ok 70\n";
}

if(Math::MPFR->new(10) <=  $ninf ) {
  warn "\n10 <= $ninf\n";
  print "not ok 71\n";
}
else {print "ok 71\n"}

if(Math::MPFR->new(10) <= "$strinf") {print "ok 72\n"}
else {
  warn "\n 10 > infinity\n";
  print "not ok 72\n";
}

$x = (Math::MPFR->new(10) <=  $nan );
if(!$x) {print "ok 73\n"}
else {
  warn "\n 10 > NaN\n";
  print "not ok 73\n";
}

$x = (Math::MPFR->new(10) <= "$strnan");
if(!$x) {print "ok 74\n"}
else {
  warn "\n 10 > NaN\n";
  print "not ok 74\n";
}

$x = (Math::MPFR->new(10) <= "61.2");
if($x) {print "ok 75\n"}
else {
  warn "\n 10 > 61.2\n";
  print "not ok 75\n";
}

$dec -= 2.0;
if(Math::MPFR->new(10) <= $dec) {print "ok 76\n"}
else {
  warn "\n ", Math::MPFR->new(10), " > $dec\n";
  print "not ok 76\n";
}

if(Math::MPFR->new(10) >=  $inf ) {
  warn "\n 10 >= $inf\n";
  print "not ok 77\n";
}
else {print "ok 77\n"}

if(Math::MPFR->new(10) >= $ninf) {print "ok 78\n"}
else {
  warn "\n 10 < $ninf\n";
  print "not ok 78\n";
}

if(Math::MPFR->new(10) >= "$strinf") {
  warn "\n 10 >= infinity\n";
  print "not ok 79\n";
}
else {print "ok 79\n"}

$x = (Math::MPFR->new(10) >=  $nan );
if(!$x) {print "ok 80\n"}
else {
  warn "\n 10 >= NaN\n";
  print "not ok 80\n";
}

$x = (Math::MPFR->new(10) >= "$strnan");
if(!$x) {print "ok 81\n"}
else {
  warn "\n 10 >= NaN\n";
  print "not ok 81\n";
}

$x = (Math::MPFR->new(10) >= "61.2");
if(!$x) {print "ok 82\n"}
else {
  warn "\n 10 >= 61.2\n";
  print "not ok 82\n";
}

$dec -= 1.0;

if(Math::MPFR->new(10) >= $dec) {print "ok 83\n"}
else {
  warn "\n ", Math::MPFR->new(10), " < $dec\n";
  print "not ok 83\n";
}

if(Math::MPFR->new(10) >  $inf ) {
  warn "\n 10 > $inf\n";
  print "not ok 84\n";
}
else {print "ok 84\n"}

if(Math::MPFR->new(10) > $ninf) {print "ok 85\n"}
else {
  warn "\n 10 <= $ninf\n";
  print "not ok 85\n";
}

if(Math::MPFR->new(10) > "$strinf") {
  warn "\n 10 > infinity\n";
  print "not ok 86\n";
}
else {print "ok 86\n"}

$x = (Math::MPFR->new(10) >  $nan );
if(!$x) {print "ok 87\n"}
else {
  warn "\n 10 > NaN\n";
  print "not ok 87\n";
}

$x = (Math::MPFR->new(10) > "$strnan");
if(!$x) {print "ok 88\n"}
else {
  warn "\n 10 > NaN\n";
  print "not ok 88\n";
}

$x = (Math::MPFR->new(10) > "61.2");
if(!$x) {print "ok 89\n"}
else {
  warn "\n 10 > 61.2\n";
  print "not ok 89\n";
}

$dec -= 1.0;
if(Math::MPFR->new(10) > $dec) {print "ok 90\n"}
else {
  warn "\n ", Math::MPFR->new(10), " !> $dec\n";
  print "not ok 90\n";
}

if(Math::MPFR->new(6) < 6.5) {print  "ok 91\n"}
else {
  warn "\n 6 >= 6.5\n";
  print "not ok 91\n";
}

if(Math::MPFR->new(6) <= 6.5) {print  "ok 92\n"}
else {
  warn "\n 6 > 6.5\n";
  print "not ok 92\n";
}

if(Math::MPFR->new(-6) > -6.5) {print  "ok 93\n"}
else {
  warn "\n -6 <= -6.5\n";
  print "not ok 93\n";
}

if(Math::MPFR->new(-6) >= -6.5) {print  "ok 94\n"}
else {
  warn "\n -6 < -6.5\n";
  print "not ok 94\n";
}

if(Math::MPFR->new(10) == $inf * -1) {
  warn "\n 10 == -inf\n";
  print "ok 95\n";
}
else {print "ok 95\n"}

if(Math::MPFR->new(10) < $inf * -1) {
  warn "\n 10 < -inf\n";
  print "ok 96\n";
}
else {print "ok 96\n"}

if(Math::MPFR->new(10) <= $inf * -1) {
  warn "\n 10 <= -inf\n";
  print "ok 97\n";
}
else {print "ok 97\n"}

if(Math::MPFR->new(10) > $inf * -1) {print "ok 98\n"}
else {
  warn "\n 10 <= -inf\n";
  print "ok 98\n";
}

if(Math::MPFR->new(10) >= $inf * -1) {print "ok 99\n"}
else {
  warn "\n 10 < -inf\n";
  print "ok 99\n";
}

if(Math::MPFR->new(10) != $inf * -1) {print "ok 100\n"}
else {
  warn "\n 10 == -inf\n";
  print "ok 100\n";
}

#########################
#########################

if((Math::MPFR->new(10) <=> "$strinf") < 0) {print "ok 101\n"}
else {
  warn "\n 10 >= inf\n";
  print "not ok 101\n";
}

$x = (Math::MPFR->new(10) <=>  $nan );
if(!defined($x)) {print "ok 102\n"}
else {
  warn "\n \$x: $x\n";
  print "not ok 102\n";
}

$x = (Math::MPFR->new(10) <=> "$strnan");
if(!defined($x)) {print "ok 103\n"}
else {
  warn "\n \$x: $x\n";
  print "not ok 103\n";
}

$x = (Math::MPFR->new(10) <=> "61.2");
if($x < 0) {print "ok 104\n"}
else {
  warn "\n \$x: $x\n";
  print "not ok 104\n";
}

if((Math::MPFR->new(10) <=> $inf) < 0){print "ok 105\n"}
else {
  warn "\n 10 !< inf\n";
  print "not ok 105\n";
}

if((Math::MPFR->new(10) <=> $inf * -1) > 0){print "ok 106\n"}
else {
  warn "\n 10 !> inf\n";
  print "not ok 106\n";
}

##########################
##########################


my $z = Math::MPFR->new(-3);

if($z == "$strninf") {
  warn "\n $z == infinity\n";
  print "not ok 107\n";
}
else {print "ok 107\n"}

if($z != "$strninf") {print "ok 108\n"}
else {
  warn "\n $z == infinity\n";
  print "not ok 108\n";
}

if($z > "$strninf") {print "ok 109\n"}
else {
  warn "\n $z <= infinity\n";
  print "not ok 109\n";
}

if($z >= "$strninf") {print "ok 110\n"}
else {
  warn "\n $z < infinity\n";
  print "not ok 110\n";
}

if($z < "$strninf") {
  warn "\n $z < infinity\n";
  print "not ok 111\n";
}
else {print "ok 111\n"}

if($z <= "$strninf") {
  warn "\n $z <= infinity\n";
  print "not ok 112\n";
}
else {print "ok 112\n"}

if(($z <=> "$strninf") > 0) {print "ok 113\n"}
else {
  warn "\n $z !> infinity\n";
  print "not ok 113\n";
}

if(Math::MPFR->new(0.005859375) == 3 / 512) {print "ok 114\n"}
else {
   print "not ok 114\n";
}

if(Math::MPFR->new(585937.5e-8) == 3 / 512) {print "ok 115\n"}
else {
   print "not ok 115\n";
}

if(Math::MPFR->new(-86.0009765625) == -88065 / 1024) {print "ok 116\n"}
else {
   print "not ok 116\n";
}

my $big_nv = 2**1015;

if(Math::MPFR->new($big_nv) == '351111940402796075728379920075981393284761128699669252487168127261196632432619068618571244770327218791250222421623815151677323767215657465806342637967722899175327916845440400930277772658683777577056802640791026892262013051450122815378736544025053197584668966180832613749896964723593195907881555331297312768') {
  print "ok 117\n";
}
else {
  warn "\n Expected:\n351111940402796075728379920075981393284761128699669252487168127261196632432619068618571244770327218791250222421623815151677323767215657465806342637967722899175327916845440400930277772658683777577056802640791026892262013051450122815378736544025053197584668966180832613749896964723593195907881555331297312768\n",
       "Got:\n", Math::MPFR->new($big_nv);
  print "not ok 117\n";
}

if(Math::MPFR->new(0.0) == '0') {print "ok 118\n"}
else {
  warn "\n ", Math::MPFR->new(0.0), "!= 0\n";
  print "not ok 118\n";
}

if(Math::MPFR->new(-0.0) == '0') {print "ok 119\n"}
else {
  warn "\n ", Math::MPFR->new(-0.0), "!= 0\n";
  print "not ok 119\n";
}
