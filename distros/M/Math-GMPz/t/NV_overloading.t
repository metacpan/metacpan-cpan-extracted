# Mainly want to test that:
# inf and nan are handled correctly when passed to overloaded subs (including when they're passed as strings)
# valid floating point NV's are handled correctly when passed to overloaded subs
# valid floating point values are a fatal error when passed as a string

use strict;
use warnings;
use Math::GMPz;

print "1..155\n";

my $inf  = 999 ** (999 ** 999);
my $ninf = $inf * -1;
my $nan  = $inf / $inf;
my $strinf = 999 ** (999 ** 999);
my $strninf = $strinf * -1;
my $strnan = $strinf / $strinf;
my ($ret, $x);

eval{$ret = Math::GMPz->new(10) *  $inf };
if($@ =~ /In Math::GMPz::overload_mul, cannot coerce an Inf to a Math::GMPz value/) {print "ok 1\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 1\n";
}

eval{$ret = Math::GMPz->new(10) * "$strinf"};
if($@ =~ /supplied to Math::GMPz::overload_mul/) {print "ok 2\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 2\n";
}

eval{$ret = Math::GMPz->new(10) *  $nan };
if($@ =~ /In Math::GMPz::overload_mul, cannot coerce a NaN to a Math::GMPz value/) {print "ok 3\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 3\n";
}

eval{$ret = Math::GMPz->new(10) * "$strnan"};
if($@ =~ /supplied to Math::GMPz::overload_mul/) {print "ok 4\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 4\n";
}

eval{$ret = Math::GMPz->new(10) * "61.2"};
if($@ =~ /supplied to Math::GMPz::overload_mul/) {print "ok 5\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 5\n";
}

if(Math::GMPz->new(10) * 61.2 == 610) {print "ok 6\n"}
else {
  warn "\n Expected 610\nGot: ", Math::GMPz->new(10) * 61.2, "\n";
  print "not ok 6\n";
}

eval{$ret = Math::GMPz->new(10) +  $inf };
if($@ =~ /In Math::GMPz::overload_add, cannot coerce an Inf to a Math::GMPz value/) {print "ok 7\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 7\n";
}

eval{$ret = Math::GMPz->new(10) + "$strinf"};
if($@ =~ /supplied to Math::GMPz::overload_add/) {print "ok 8\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 8\n";
}

eval{$ret = Math::GMPz->new(10) +  $nan };
if($@ =~ /In Math::GMPz::overload_add, cannot coerce a NaN to a Math::GMPz value/) {print "ok 9\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 9\n";
}

eval{$ret = Math::GMPz->new(10) + "$strnan"};
if($@ =~ /supplied to Math::GMPz::overload_add/) {print "ok 10\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 10\n";
}
eval{$ret = Math::GMPz->new(10) + "61.2"};
if($@ =~ /supplied to Math::GMPz::overload_add/) {print "ok 11\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 11\n";
}

if(Math::GMPz->new(10) + 61.2 == 71) {print "ok 12\n"}
else {
  warn "\n Expected 71\nGot: ", Math::GMPz->new(10) + 61.2, "\n";
  print "not ok 12\n";
}

eval{$ret = Math::GMPz->new(10) /  $inf };
if($@ =~ /In Math::GMPz::overload_div, cannot coerce an Inf to a Math::GMPz value/) {print "ok 13\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 13\n";
}

eval{$ret = Math::GMPz->new(10) / "$strinf"};
if($@ =~ /supplied to Math::GMPz::overload_div/) {print "ok 14\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 14\n";
}

eval{$ret = Math::GMPz->new(10) /  $nan };
if($@ =~ /In Math::GMPz::overload_div, cannot coerce a NaN to a Math::GMPz value/) {print "ok 15\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 15\n";
}

eval{$ret = Math::GMPz->new(10) / "$strnan"};
if($@ =~ /supplied to Math::GMPz::overload_div/) {print "ok 16\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 16\n";
}

eval{$ret = Math::GMPz->new(10) / "61.2"};
if($@ =~ /supplied to Math::GMPz::overload_div/) {print "ok 17\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 17\n";
}

if(Math::GMPz->new(10) / 61.2 == 0) {print "ok 18\n"}
else {
  warn "\n Expected 0\nGot: ", Math::GMPz->new(10) / 61.2, "\n";
  print "not ok 18\n";
}

eval{$ret = Math::GMPz->new(10) -  $inf };
if($@ =~ /In Math::GMPz::overload_sub, cannot coerce an Inf to a Math::GMPz value/) {print "ok 19\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 19\n";
}

eval{$ret = Math::GMPz->new(10) - "$strinf"};
if($@ =~ /supplied to Math::GMPz::overload_sub/) {print "ok 20\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 20\n";
}

eval{$ret = Math::GMPz->new(10) -  $nan };
if($@ =~ /In Math::GMPz::overload_sub, cannot coerce a NaN to a Math::GMPz value/) {print "ok 21\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 21\n";
}

eval{$ret = Math::GMPz->new(10) - "$strnan"};
if($@ =~ /supplied to Math::GMPz::overload_sub/) {print "ok 22\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 22\n";
}

eval{$ret = Math::GMPz->new(10) - "61.2"};
if($@ =~ /supplied to Math::GMPz::overload_sub/) {print "ok 23\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 23\n";
}

if(Math::GMPz->new(10) - 61.2 == -51) {print "ok 24\n"}
else {
  warn "\n Expected -51\nGot: ", Math::GMPz->new(10) - 61.2, "\n";
  print "not ok 24\n";
}

$ret = Math::GMPz->new(10);

eval{$ret *=  $inf };
if($@ =~ /In Math::GMPz::overload_mul_eq, cannot coerce an Inf to a Math::GMPz value/) {print "ok 25\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 25\n";
}

eval{$ret *= "$strinf"};
if($@ =~ /supplied to Math::GMPz::overload_mul_eq/) {print "ok 26\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 26\n";
}

eval{$ret *=  $nan };
if($@ =~ /In Math::GMPz::overload_mul_eq, cannot coerce a NaN to a Math::GMPz value/) {print "ok 27\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 27\n";
}

eval{$ret *= "$strnan"};
if($@ =~ /supplied to Math::GMPz::overload_mul_eq/) {print "ok 28\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 28\n";
}

eval{$ret *= "61.2"};
if($@ =~ /supplied to Math::GMPz::overload_mul_eq/) {print "ok 29\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 29\n";
}

$ret *= 61.2;

if($ret == 610) {print "ok 30\n"}
else {
  warn "\n Expected 610\nGot: $ret\n";
  print "not ok 30\n";
}

eval{$ret +=  $inf };
if($@ =~ /In Math::GMPz::overload_add_eq, cannot coerce an Inf to a Math::GMPz value/) {print "ok 31\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 31\n";
}

eval{$ret += "$strinf"};
if($@ =~ /supplied to Math::GMPz::overload_add_eq/) {print "ok 32\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 32\n";
}

eval{$ret +=  $nan };
if($@ =~ /In Math::GMPz::overload_add_eq, cannot coerce a NaN to a Math::GMPz value/) {print "ok 33\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 33\n";
}

eval{$ret += "$strnan"};
if($@ =~ /supplied to Math::GMPz::overload_add_eq/) {print "ok 34\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 34\n";
}

eval{$ret += "61.2"};
if($@ =~ /supplied to Math::GMPz::overload_add_eq/) {print "ok 35\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 35\n";
}

$ret += 61.2;

if($ret == 671) {print "ok 36\n"}
else {
  warn "\n Expected 671\nGot: $ret\n";
  print "not ok 36\n";
}

eval{$ret -=  $inf };
if($@ =~ /In Math::GMPz::overload_sub_eq, cannot coerce an Inf to a Math::GMPz value/) {print "ok 37\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 37\n";
}

eval{$ret -= "$strinf"};
if($@ =~ /supplied to Math::GMPz::overload_sub_eq/) {print "ok 38\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 38\n";
}

eval{$ret -=  $nan };
if($@ =~ /In Math::GMPz::overload_sub_eq, cannot coerce a NaN to a Math::GMPz value/) {print "ok 39\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 39\n";
}

eval{$ret -= "$strnan"};
if($@ =~ /supplied to Math::GMPz::overload_sub_eq/) {print "ok 40\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 40\n";
}

eval{$ret -= "61.2"};
if($@ =~ /supplied to Math::GMPz::overload_sub_eq/) {print "ok 41\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 41\n";
}

$ret -= 61.2;

if($ret == 610) {print "ok 42\n"}
else {
  warn "\n Expected 610\nGot: $ret\n";
  print "not ok 42\n";
}

eval{$ret /=  $inf };
if($@ =~ /In Math::GMPz::overload_div_eq, cannot coerce an Inf to a Math::GMPz value/) {print "ok 43\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 43\n";
}

eval{$ret /= "$strinf"};
if($@ =~ /supplied to Math::GMPz::overload_div_eq/) {print "ok 44\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 44\n";
}

eval{$ret /=  $nan };
if($@ =~ /In Math::GMPz::overload_div_eq, cannot coerce a NaN to a Math::GMPz value/) {print "ok 45\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 45\n";
}

eval{$ret /= "$strnan"};
if($@ =~ /supplied to Math::GMPz::overload_div_eq/) {print "ok 46\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 46\n";
}

eval{$ret /= "61.2"};
if($@ =~ /supplied to Math::GMPz::overload_div_eq/) {print "ok 47\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 47\n";
}

$ret /= 61.2;

if($ret == 10) {print "ok 48\n"}
else {
  warn "\n Expected 10\nGot: $ret\n";
  print "not ok 48\n";
}

if(Math::GMPz->new(10) ==  $inf ) {
  warn "\n 10 == $inf\n";
  print "not ok 49\n";
}
else {print "ok 49\n"}

if(Math::GMPz->new(10) ==  $ninf ) {
  warn "\n 10 == $ninf\n";
  print "not ok 50\n";
}
else {print "ok 50\n"}

if("$strinf" =~ /^inf/i || $^O =~ /MSWin/) {
  if(Math::GMPz->new(10) == "$strinf") {
    warn "\n 10 == infinity\n";
    print "not ok 51\n";
  }
  else {print "ok 51\n"}
}
else {
  eval {$x = (Math::GMPz->new(10) == "$strinf")};
  if($@ =~ /supplied to Math::GMPz::overload_equiv/) {print "ok 51\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 51\n";
  }
}

eval{$x = (Math::GMPz->new(10) ==  $nan )};
if($@ =~ /In Math::GMPz::overload_equiv, cannot compare a NaN to a Math::GMPz value/) {print "ok 52\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 52\n";
}
eval{$x = (Math::GMPz->new(10) == "$strnan")};
if($@ =~ /supplied to Math::GMPz::overload_equiv/) {print "ok 53\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 53\n";
}

eval{$x = (Math::GMPz->new(10) == "61.2")};
if($@ =~ /supplied to Math::GMPz::overload_equiv/) {print "ok 54\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 54\n";
}

my $dec = 10.0;
if(Math::GMPz->new(10) == $dec) {print "ok 55\n"}
else {
  warn "\n ", Math::GMPz->new(10), " != $dec\n";
  print "not ok 55\n";
}

if(Math::GMPz->new(10) !=  $inf ) {print "ok 56\n"}
else {
  warn "\n 10 == $inf\n";
  print "not ok 56\n";
}

if(Math::GMPz->new(10) !=  $ninf ) {print "ok 57\n"}
else {
  warn "\n 10 == $ninf\n";
  print "not ok 57\n";
}

if("$strinf" =~ /^inf/i || $^O =~ /MSWin/) {
  if(Math::GMPz->new(10) != "$strinf") {print "ok 58\n"}
  else {
    warn "\n 10 == infinity\n";
    print "not ok 58\n";
  }
}
else {
  eval{$x = (Math::GMPz->new(10) != "$strinf")};
  if($@ =~ /supplied to Math::GMPz::overload_not_equiv/) {print "ok 58\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 58\n";
  }
}

eval{$x = (Math::GMPz->new(10) !=  $nan )};
if($@ =~ /In Math::GMPz::overload_not_equiv, cannot compare a NaN to a Math::GMPz value/) {print "ok 59\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 59\n";
}

eval{$x = (Math::GMPz->new(10) != "$strnan")};
if($@ =~ /supplied to Math::GMPz::overload_not_equiv/) {print "ok 60\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 60\n";
}

eval{$x = (Math::GMPz->new(10) != "61.2")};
if($@ =~ /supplied to Math::GMPz::overload_not_equiv/) {print "ok 61\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 61\n";
}

$dec += 0.9;;
if(Math::GMPz->new(10) != $dec) {print "ok 62\n"}
else {
  warn "\n ", Math::GMPz->new(10), " == $dec\n";
  print "not ok 62\n";
}

if(Math::GMPz->new(10) <  $inf ) {print "ok 63\n"}
else {
  warn "\n 10 >= $inf\n";
  print "not ok 63\n";
}

if(Math::GMPz->new(10) <  $ninf ) {
  warn "\n10 < $ninf\n";
  print "not ok 64\n";
}
else {print "ok 64\n"}

if("$strinf" =~ /^inf/i || $^O =~ /MSWin/) {
  if(Math::GMPz->new(10) < "$strinf") {print "ok 65\n"}
  else {
    warn "\n 10 >= infinity\n";
    print "not ok 65\n";
  }
}
else {
  eval{$x = (Math::GMPz->new(10) < "$strinf")};
  if($@ =~ /supplied to Math::GMPz::overload_lt/) {print "ok 65\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 65\n";
  }
}

eval{$x = (Math::GMPz->new(10) <  $nan )};
if($@ =~ /In Rmpz_cmp_NV, cannot compare a NaN to a Math::GMPz value/) {print "ok 66\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 66\n";
}

eval{$x = (Math::GMPz->new(10) < "$strnan")};
if($@ =~ /supplied to Math::GMPz::overload_lt/) {print "ok 67\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 67\n";
}

eval{$x = (Math::GMPz->new(10) < "61.2")};
if($@ =~ /supplied to Math::GMPz::overload_lt/) {print "ok 68\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 68\n";
}


$dec += 2.0;;
if(Math::GMPz->new(10) < $dec) {print "ok 69\n"}
else {
  warn "\n ", Math::GMPz->new(10), " !< $dec\n";
  print "not ok 69\n";
}

if(Math::GMPz->new(10) <=  $inf ) {print "ok 70\n"}
else {
  warn "\n 10 > $inf\n";
  print "not ok 70\n";
}

if(Math::GMPz->new(10) <=  $ninf ) {
  warn "\n10 <= $ninf\n";
  print "not ok 71\n";
}
else {print "ok 71\n"}

if("$strinf" =~ /^inf/i || $^O =~ /MSWin/) {
  if(Math::GMPz->new(10) <= "$strinf") {print "ok 72\n"}
  else {
    warn "\n 10 > infinity\n";
    print "not ok 72\n";
  }
}
else {
  eval{$x = (Math::GMPz->new(10) <= "$strinf")};
  if($@ =~ /supplied to Math::GMPz::overload_lte/) {print "ok 72\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 72\n";
  }
}

eval{$x = (Math::GMPz->new(10) <=  $nan )};
if($@ =~ /In Rmpz_cmp_NV, cannot compare a NaN to a Math::GMPz value/) {print "ok 73\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 73\n";
}

eval{$x = (Math::GMPz->new(10) <= "$strnan")};
if($@ =~ /supplied to Math::GMPz::overload_lte/) {print "ok 74\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 74\n";
}

eval{$x = (Math::GMPz->new(10) <= "61.2")};
if($@ =~ /supplied to Math::GMPz::overload_lte/) {print "ok 75\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 75\n";
}

$dec -= 2.0;
if(Math::GMPz->new(10) <= $dec) {print "ok 76\n"}
else {
  warn "\n ", Math::GMPz->new(10), " > $dec\n";
  print "not ok 76\n";
}

if(Math::GMPz->new(10) >=  $inf ) {
  warn "\n 10 >= $inf\n";
  print "not ok 77\n";
}
else {print "ok 77\n"}

if(Math::GMPz->new(10) >= $ninf) {print "ok 78\n"}
else {
  warn "\n 10 < $ninf\n";
  print "not ok 78\n";
}

if("$strinf" =~ /^inf/i || $^O =~ /MSWin/) {
  if(Math::GMPz->new(10) >= "$strinf") {
    warn "\n 10 >= infinity\n";
    print "not ok 79\n";
  }
  else {print "ok 79\n"}
}
else {
  eval{$x = (Math::GMPz->new(10) >= "$strinf")};
  if($@ =~ /supplied to Math::GMPz::overload_gte/) {print "ok 79\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 79\n";
  }
}

eval{$x = (Math::GMPz->new(10) >=  $nan )};
if($@ =~ /In Rmpz_cmp_NV, cannot compare a NaN to a Math::GMPz value/) {print "ok 80\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 80\n";
}

eval{$x = (Math::GMPz->new(10) >= "$strnan")};
if($@ =~ /supplied to Math::GMPz::overload_gte/) {print "ok 81\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 81\n";
}

eval{$x = (Math::GMPz->new(10) >= "61.2")};
if($@ =~ /supplied to Math::GMPz::overload_gte/) {print "ok 82\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 82\n";
}

$dec -= 1.0;
if(Math::GMPz->new(10) >= $dec) {print "ok 83\n"}
else {
  warn "\n ", Math::GMPz->new(10), " < $dec\n";
  print "not ok 83\n";
}

if(Math::GMPz->new(10) >  $inf ) {
  warn "\n 10 > $inf\n";
  print "not ok 84\n";
}
else {print "ok 84\n"}

if(Math::GMPz->new(10) > $ninf) {print "ok 85\n"}
else {
  warn "\n 10 <= $ninf\n";
  print "not ok 85\n";
}

if("$strinf" =~ /^inf/i || $^O =~ /MSWin/) {
  if(Math::GMPz->new(10) > "$strinf") {
    warn "\n 10 > infinity\n";
    print "not ok 86\n";
  }
  else {print "ok 86\n"}
}
else {
  eval{$x = (Math::GMPz->new(10) > "$strinf")};
  if($@ =~ /supplied to Math::GMPz::overload_gt/) {print "ok 86\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 86\n";
  }
}

eval{$x = (Math::GMPz->new(10) >  $nan )};
if($@ =~ /In Rmpz_cmp_NV, cannot compare a NaN to a Math::GMPz value/) {print "ok 87\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 87\n";
}

eval{$x = (Math::GMPz->new(10) > "$strnan")};
if($@ =~ /supplied to Math::GMPz::overload_gt/) {print "ok 88\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 88\n";
}

eval{$x = (Math::GMPz->new(10) > "61.2")};
if($@ =~ /supplied to Math::GMPz::overload_gt/) {print "ok 89\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 89\n";
}

$dec -= 1.0;
if(Math::GMPz->new(10) > $dec) {print "ok 90\n"}
else {
  warn "\n ", Math::GMPz->new(10), " !> $dec\n";
  print "not ok 90\n";
}

if(Math::GMPz->new(6) < 6.5) {print  "ok 91\n"}
else {
  warn "\n 6 >= 6.5\n";
  print "not ok 91\n";
}

if(Math::GMPz->new(6) <= 6.5) {print  "ok 92\n"}
else {
  warn "\n 6 > 6.5\n";
  print "not ok 92\n";
}

if(Math::GMPz->new(-6) > -6.5) {print  "ok 93\n"}
else {
  warn "\n -6 <= -6.5\n";
  print "not ok 93\n";
}

if(Math::GMPz->new(-6) >= -6.5) {print  "ok 94\n"}
else {
  warn "\n -6 < -6.5\n";
  print "not ok 94\n";
}

if(Math::GMPz->new(10) == $inf * -1) {
  warn "\n 10 == -inf\n";
  print "ok 95\n";
}
else {print "ok 95\n"}

if(Math::GMPz->new(10) < $inf * -1) {
  warn "\n 10 < -inf\n";
  print "ok 96\n";
}
else {print "ok 96\n"}

if(Math::GMPz->new(10) <= $inf * -1) {
  warn "\n 10 <= -inf\n";
  print "ok 97\n";
}
else {print "ok 97\n"}

if(Math::GMPz->new(10) > $inf * -1) {print "ok 98\n"}
else {
  warn "\n 10 <= -inf\n";
  print "ok 98\n";
}

if(Math::GMPz->new(10) >= $inf * -1) {print "ok 99\n"}
else {
  warn "\n 10 < -inf\n";
  print "ok 99\n";
}

if(Math::GMPz->new(10) != $inf * -1) {print "ok 100\n"}
else {
  warn "\n 10 == -inf\n";
  print "ok 100\n";
}

#########################
#########################

if("$strinf" =~ /^inf/i || $^O =~ /MSWin/) {
  if((Math::GMPz->new(10) <=> "$strinf") < 0) {print "ok 101\n"}
  else {
    warn "\n 10 !< inf\n";
    print "not ok 101\n";
  }
}
else {
  eval{$x = (Math::GMPz->new(10) <=> "$strinf")};
  if($@ =~ /supplied to Math::GMPz::overload_spaceship/) {print "ok 101\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 101\n";
  }
}

eval{$x = (Math::GMPz->new(10) <=>  $nan )};
if($@ =~ /In Rmpz_cmp_NV, cannot compare a NaN to a Math::GMPz value/) {print "ok 102\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 102\n";
}

eval{$x = (Math::GMPz->new(10) <=> "$strnan")};
if($@ =~ /supplied to Math::GMPz::overload_spaceship/) {print "ok 103\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 103\n";
}

eval{$x = (Math::GMPz->new(10) <=> "61.2")};
if($@ =~ /supplied to Math::GMPz::overload_spaceship/) {print "ok 104\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 104\n";
}

if((Math::GMPz->new(10) <=> $inf) < 0){print "ok 105\n"}
else {
  warn "\n 10 !< inf\n";
  print "not ok 105\n";
}

if((Math::GMPz->new(10) <=> $inf * -1) > 0){print "ok 106\n"}
else {
  warn "\n 10 !> inf\n";
  print "not ok 106\n";
}

##########################
##########################

eval{$ret = Math::GMPz->new(10) &  $inf };
if($@ =~ /In Math::GMPz::overload_and, cannot coerce an Inf to a Math::GMPz value/) {print "ok 107\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 107\n";
}

eval{$ret = Math::GMPz->new(10) &  -$inf };
if($@ =~ /In Math::GMPz::overload_and, cannot coerce an Inf to a Math::GMPz value/) {print "ok 108\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 108\n";
}

eval{$ret = Math::GMPz->new(10) & "$strinf"};
if($@ =~ /supplied to Math::GMPz::overload_and/) {print "ok 109\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 109\n";
}

eval{$ret = Math::GMPz->new(10) &  $nan };
if($@ =~ /In Math::GMPz::overload_and, cannot coerce a NaN to a Math::GMPz value/) {print "ok 110\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 110\n";
}

eval{$ret = Math::GMPz->new(10) & "$strnan"};
if($@ =~ /supplied to Math::GMPz::overload_and/) {print "ok 111\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 111\n";
}

eval{$ret = Math::GMPz->new(10) & "61.2"};
if($@ =~ /supplied to Math::GMPz::overload_and/) {print "ok 112\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 112\n";
}

eval{$ret = Math::GMPz->new(10) |  $inf };
if($@ =~ /In Math::GMPz::overload_ior, cannot coerce an Inf to a Math::GMPz value/) {print "ok 113\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 113\n";
}

eval{$ret = Math::GMPz->new(10) |  -$inf };
if($@ =~ /In Math::GMPz::overload_ior, cannot coerce an Inf to a Math::GMPz value/) {print "ok 114\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 114\n";
}

eval{$ret = Math::GMPz->new(10) | "$strinf"};
if($@ =~ /supplied to Math::GMPz::overload_ior/) {print "ok 115\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 115\n";
}

eval{$ret = Math::GMPz->new(10) |  $nan };
if($@ =~ /In Math::GMPz::overload_ior, cannot coerce a NaN to a Math::GMPz value/) {print "ok 116\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 116\n";
}

eval{$ret = Math::GMPz->new(10) | "$strnan"};
if($@ =~ /supplied to Math::GMPz::overload_ior/) {print "ok 117\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 117\n";
}

eval{$ret = Math::GMPz->new(10) | "61.2"};
if($@ =~ /supplied to Math::GMPz::overload_ior/) {print "ok 118\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 118\n";
}

eval{$ret = Math::GMPz->new(10) ^  $inf };
if($@ =~ /In Math::GMPz::overload_xor, cannot coerce an Inf to a Math::GMPz value/) {print "ok 119\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 119\n";
}

eval{$ret = Math::GMPz->new(10) ^  -$inf };
if($@ =~ /In Math::GMPz::overload_xor, cannot coerce an Inf to a Math::GMPz value/) {print "ok 120\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 120\n";
}

eval{$ret = Math::GMPz->new(10) ^ "$strinf"};
if($@ =~ /supplied to Math::GMPz::overload_xor/) {print "ok 121\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 121\n";
}

eval{$ret = Math::GMPz->new(10) ^  $nan };
if($@ =~ /In Math::GMPz::overload_xor, cannot coerce a NaN to a Math::GMPz value/) {print "ok 122\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 122\n";
}

eval{$ret = Math::GMPz->new(10) ^ "$strnan"};
if($@ =~ /supplied to Math::GMPz::overload_xor/) {print "ok 123\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 123\n";
}

eval{$ret = Math::GMPz->new(10) ^ "61.2"};
if($@ =~ /supplied to Math::GMPz::overload_xor/) {print "ok 124\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 124\n";
}

eval{$ret &=  $inf };
if($@ =~ /In Math::GMPz::overload_and_eq, cannot coerce an Inf to a Math::GMPz value/) {print "ok 125\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 125\n";
}

eval{$ret &=  -$inf };
if($@ =~ /In Math::GMPz::overload_and_eq, cannot coerce an Inf to a Math::GMPz value/) {print "ok 126\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 126\n";
}

eval{$ret &= "$strinf"};
if($@ =~ /supplied to Math::GMPz::overload_and_eq/) {print "ok 127\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 127\n";
}

eval{$ret &=  $nan };
if($@ =~ /In Math::GMPz::overload_and_eq, cannot coerce a NaN to a Math::GMPz value/) {print "ok 128\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 128\n";
}

eval{$ret &= "$strnan"};
if($@ =~ /supplied to Math::GMPz::overload_and_eq/) {print "ok 129\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 129\n";
}

eval{$ret &= "61.2"};
if($@ =~ /supplied to Math::GMPz::overload_and_eq/) {print "ok 130\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 130\n";
}

eval{$ret |=  $inf };
if($@ =~ /In Math::GMPz::overload_ior_eq, cannot coerce an Inf to a Math::GMPz value/) {print "ok 131\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 131\n";
}

eval{$ret |=  -$inf };
if($@ =~ /In Math::GMPz::overload_ior_eq, cannot coerce an Inf to a Math::GMPz value/) {print "ok 132\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 132\n";
}

eval{$ret |= "$strinf"};
if($@ =~ /supplied to Math::GMPz::overload_ior_eq/) {print "ok 133\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 133\n";
}

eval{$ret |=  $nan };
if($@ =~ /In Math::GMPz::overload_ior_eq, cannot coerce a NaN to a Math::GMPz value/) {print "ok 134\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 134\n";
}

eval{$ret |= "$strnan"};
if($@ =~ /supplied to Math::GMPz::overload_ior_eq/) {print "ok 135\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 135\n";
}

eval{$ret |= "61.2"};
if($@ =~ /supplied to Math::GMPz::overload_ior_eq/) {print "ok 136\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 136\n";
}

eval{$ret ^=  $inf };
if($@ =~ /In Math::GMPz::overload_xor_eq, cannot coerce an Inf to a Math::GMPz value/) {print "ok 137\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 137\n";
}

eval{$ret ^=  -$inf };
if($@ =~ /In Math::GMPz::overload_xor_eq, cannot coerce an Inf to a Math::GMPz value/) {print "ok 138\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 138\n";
}

eval{$ret ^= "$strinf"};
if($@ =~ /supplied to Math::GMPz::overload_xor_eq/) {print "ok 139\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 139\n";
}

eval{$ret ^=  $nan };
if($@ =~ /In Math::GMPz::overload_xor_eq, cannot coerce a NaN to a Math::GMPz value/) {print "ok 140\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 140\n";
}

eval{$ret ^= "$strnan"};
if($@ =~ /supplied to Math::GMPz::overload_xor_eq/) {print "ok 141\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 141\n";
}

eval{$ret ^= "61.2"};
if($@ =~ /supplied to Math::GMPz::overload_xor_eq/) {print "ok 142\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 142\n";
}


if((Math::GMPz->new(50) & 40.1) == (50 & 40)) {print "ok 143\n"}
else {
  warn "\n Expected ", 50 & 40, "\n Got ", Math::GMPz->new(50) & 40.1,"\n";
  print "not ok 143\n";
}

if((Math::GMPz->new(50) | 40.9) == (50 | 40)) {print "ok 144\n"}
else {
  warn "\n Expected ", 50 | 40, "\n Got ", Math::GMPz->new(50) | 40.9,"\n";
  print "not ok 144\n";
}

if((Math::GMPz->new(50) ^ 40.1) == (50 ^ 40)) {print "ok 145\n"}
else {
  warn "\n Expected ", 50 ^ 40, "\n Got ", Math::GMPz->new(50) ^ 40.1,"\n";
  print "not ok 145\n";
}

my $z = Math::GMPz->new('1234567');
my $i  = 1234567;

$z &= 699999.6;
$i &= 699999;

if($z == $i) {print "ok 146\n"}
else {
  warn "\n Expected $i\n Got $z\n";
  print "not ok 146\n";
}

$z |= 233333.6;
$i |= 233333;

if($z == $i) {print "ok 147\n"}
else {
  warn "\n Expected $i\n Got $z\n";
  print "not ok 147\n";
}

$z ^= 101010.6;
$i ^= 101010;

if($z == $i) {print "ok 148\n"}
else {
  warn "\n Expected $i\n Got $z\n";
  print "not ok 148\n";
}

if("$strninf" =~ /^\-inf/i || $^O =~ /MSWin/) {
  my $z = Math::GMPz->new(-3);

  if($z == "$strninf") {
    warn "\n $z == infinity\n";
    print "not ok 149\n";
  }
  else {print "ok 149\n"}

  if($z != "$strninf") {print "ok 150\n"}
  else {
    warn "\n $z == infinity\n";
    print "not ok 150\n";
  }

  if($z > "$strninf") {print "ok 151\n"}
  else {
    warn "\n $z <= infinity\n";
    print "not ok 151\n";
  }

  if($z >= "$strninf") {print "ok 152\n"}
  else {
    warn "\n $z < infinity\n";
    print "not ok 152\n";
  }

  if($z < "$strninf") {
    warn "\n $z < infinity\n";
    print "not ok 153\n";
  }
  else {print "ok 153\n"}

  if($z <= "$strninf") {
    warn "\n $z <= infinity\n";
    print "not ok 154\n";
  }
  else {print "ok 154\n"}

  if(($z <=> "$strninf") > 0) {print "ok 155\n"}
  else {
    warn "\n $z !> infinity\n";
    print "not ok 155\n";
  }

}
else {
  warn "\n Skipping tests 149..155 (not MSWin, and -iNf !~ /^\\-inf/i)\n";
  for(149 .. 155 ) {print "ok $_\n"}
}
