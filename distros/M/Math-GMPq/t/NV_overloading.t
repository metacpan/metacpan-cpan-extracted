# Mainly want to test that:
# inf and nan are handled correctly when passed to overloaded subs (including when they're passed as strings)
# valid floating point NV's are handled correctly when passed to overloaded subs
# valid floating point values are a fatal error when passed as a string

use strict;
use warnings;
use Math::GMPq;

print "1..121\n";

my $inf  = 999 ** (999 ** 999);
my $ninf = $inf * -1;
my $nan  = $inf / $inf;
my $strinf = 999 ** (999 ** 999);
my $strninf = $strinf * -1;
my $strnan = $strinf / $strinf;
my ($ret, $x);

eval{$ret = Math::GMPq->new(10) *  $inf };
if($@ =~ /cannot coerce an Inf to a Math::GMP/) {print "ok 1\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 1\n";
}

eval{$ret = Math::GMPq->new(10) * "$strinf"};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_mul/) {print "ok 2\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 2\n";
}

eval{$ret = Math::GMPq->new(10) *  $nan };
if($@ =~ /cannot coerce a NaN to a Math::GMP/) {print "ok 3\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 3\n";
}

eval{$ret = Math::GMPq->new(10) * "$strnan"};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_mul/) {print "ok 4\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 4\n";
}

eval{$ret = Math::GMPq->new(10) * "61.2"};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_mul/) {print "ok 5\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 5\n";
}

if(Math::GMPq->new(10) * 61.2 == '21532835718365185/35184372088832' ||
   Math::GMPq->new(10) * 61.2 == '88198495102423793665/144115188075855872' ||
   Math::GMPq->new(10) * 61.2 == '387901083669838196857991180845055/633825300114114700748351602688' ||
   Math::GMPq->new(10) * 61.2 == '24825669354869644598911435574083585/40564819207303340847894502572032') {
  print "ok 6\n";
}
else {
  warn "\n Expected:\n   21532835718365185/35184372088832 or ",
                   "\n   88198495102423793665/144115188075855872 or ",
                   "\n   24825669354869644598911435574083585/40564819207303340847894502572032\nGot: ",
                    Math::GMPq->new(10) * 61.2, "\n";
  print "not ok 6\n";
}

eval{$ret = Math::GMPq->new(10) +  $inf };
if($@ =~ /cannot coerce an Inf to a Math::GMP/) {print "ok 7\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 7\n";
}

eval{$ret = Math::GMPq->new(10) + "$strinf"};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_add/) {print "ok 8\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 8\n";
}

eval{$ret = Math::GMPq->new(10) +  $nan };
if($@ =~ /cannot coerce a NaN to a Math::GMP/) {print "ok 9\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 9\n";
}

eval{$ret = Math::GMPq->new(10) + "$strnan"};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_add/) {print "ok 10\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 10\n";
}
eval{$ret = Math::GMPq->new(10) + "61.2"};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_add/) {print "ok 11\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 11\n";
}

if(Math::GMPq->new(10) + 61.2 == '5010254585449677/70368744177664' ||
   Math::GMPq->new(10) + 61.2 == '20522002782001876173/288230376151711744' ||
   Math::GMPq->new(10) + 61.2 == '90256722736249933386565268222771/1267650600228229401496703205376' ||
   Math::GMPq->new(10) + 61.2 == '5776430255119995736740177166257357/81129638414606681695789005144064') {
  print "ok 12\n";
}
else {
  warn "\n Expected:\n   5010254585449677/70368744177664 or ",
                   "\n   20522002782001876173/288230376151711744 or ",
                   "\n   90256722736249933386565268222771/1267650600228229401496703205376 or ",
                   "\n   5776430255119995736740177166257357/81129638414606681695789005144064\nGot: ",
                   Math::GMPq->new(10) + 61.2, "\n";
  print "not ok 12\n";
}

eval{$ret = Math::GMPq->new(10) /  $inf };
if($@ =~ /cannot coerce an Inf to a Math::GMP/) {print "ok 13\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 13\n";
}

eval{$ret = Math::GMPq->new(10) / "$strinf"};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_div/) {print "ok 14\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 14\n";
}

eval{$ret = Math::GMPq->new(10) /  $nan };
if($@ =~ /cannot coerce a NaN to a Math::GMP/) {print "ok 15\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 15\n";
}

eval{$ret = Math::GMPq->new(10) / "$strnan"};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_div/) {print "ok 16\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 16\n";
}

eval{$ret = Math::GMPq->new(10) / "61.2"};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_div/) {print "ok 17\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 17\n";
}

if(Math::GMPq->new(10) / 61.2 == '703687441776640/4306567143673037' ||
   Math::GMPq->new(10) / 61.2 == '2882303761517117440/17639699020484758733' ||
   Math::GMPq->new(10) / 61.2 == '12676506002282294014967032053760/77580216733967639371598236169011' ||
   Math::GMPq->new(10) / 61.2 == '811296384146066816957890051440640/4965133870973928919782287114816717') {
  print "ok 18\n";
}
else {
  warn "\n Expected:\n   703687441776640/4306567143673037 or ",
                   "\n   2882303761517117440/17639699020484758733 or ",
                   "\n   12676506002282294014967032053760/77580216733967639371598236169011 or ",
                   "\n   811296384146066816957890051440640/4965133870973928919782287114816717\nGot: ",
                   Math::GMPq->new(10) / 61.2, "\n";
  print "not ok 18\n";
}

eval{$ret = Math::GMPq->new(10) -  $inf };
if($@ =~ /cannot coerce an Inf to a Math::GMP/) {print "ok 19\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 19\n";
}

eval{$ret = Math::GMPq->new(10) - "$strinf"};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_sub/) {print "ok 20\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 20\n";
}

eval{$ret = Math::GMPq->new(10) -  $nan };
if($@ =~ /cannot coerce a NaN to a Math::GMP/) {print "ok 21\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 21\n";
}

eval{$ret = Math::GMPq->new(10) - "$strnan"};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_sub/) {print "ok 22\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 22\n";
}

eval{$ret = Math::GMPq->new(10) - "61.2"};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_sub/) {print "ok 23\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 23\n";
}

if(Math::GMPq->new(10) - 61.2 == '-3602879701896397/70368744177664' ||
   Math::GMPq->new(10) - 61.2 == '-14757395258967641293/288230376151711744' ||
   Math::GMPq->new(10) - 61.2 == '-64903710731685345356631204115251/1267650600228229401496703205376' ||
   Math::GMPq->new(10) - 61.2 == '-4153837486827862102824397063376077/81129638414606681695789005144064') {
  print "ok 24\n";
}
else {
  warn "\n Expected:\n   -3602879701896397/70368744177664 or ",
                   "\n   -14757395258967641293/288230376151711744 or ",
                   "\n   -64903710731685345356631204115251/1267650600228229401496703205376 or ",
                   "\n   -4153837486827862102824397063376077/81129638414606681695789005144064\nGot: ",
                   Math::GMPq->new(10) - 61.2, "\n";
  print "not ok 24\n";
}

$ret = Math::GMPq->new(10);

eval{$ret *=  $inf };
if($@ =~ /cannot coerce an Inf to a Math::GMP/) {print "ok 25\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 25\n";
}

eval{$ret *= "$strinf"};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_mul_eq/) {print "ok 26\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 26\n";
}

eval{$ret *=  $nan };
if($@ =~ /cannot coerce a NaN to a Math::GMP/) {print "ok 27\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 27\n";
}

eval{$ret *= "$strnan"};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_mul_eq/) {print "ok 28\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 28\n";
}

eval{$ret *= "61.2"};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_mul_eq/) {print "ok 29\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 29\n";
}

$ret *= 61.2;

if($ret == '21532835718365185/35184372088832' ||
   $ret == '88198495102423793665/144115188075855872' ||
   $ret == '387901083669838196857991180845055/633825300114114700748351602688' ||
   $ret == '24825669354869644598911435574083585/40564819207303340847894502572032') {print "ok 30\n"}
else {
  warn "\n Expected:\n   21532835718365185/35184372088832 or ",
                   "\n   88198495102423793665/144115188075855872 or ",
                   "\n   387901083669838196857991180845055/633825300114114700748351602688 or ",
                   "\n   24825669354869644598911435574083585/40564819207303340847894502572032\nGot: $ret\n";
  print "not ok 30\n";
}

eval{$ret +=  $inf };
if($@ =~ /cannot coerce an Inf to a Math::GMP/) {print "ok 31\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 31\n";
}

eval{$ret += "$strinf"};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_add_eq/) {print "ok 32\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 32\n";
}

eval{$ret +=  $nan };
if($@ =~ /cannot coerce a NaN to a Math::GMP/) {print "ok 33\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 33\n";
}

eval{$ret += "$strnan"};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_add_eq/) {print "ok 34\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 34\n";
}

eval{$ret += "61.2"};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_add_eq/) {print "ok 35\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 35\n";
}

# $ret is 612
$ret += 61.2;

if($ret == '47372238580403407/70368744177664' ||
   $ret == '194036689225332346063/288230376151711744' ||
   $ret == '853382384073644033087580597859121/1267650600228229401496703205376' ||
   $ret == '54616472580713218117605158262983887/81129638414606681695789005144064') {print "ok 36\n"}
else {
  warn "\n Expected:\n   47372238580403407/70368744177664 or ",
                   "\n   194036689225332346063/288230376151711744 or ",
                   "\n   853382384073644033087580597859121/1267650600228229401496703205376 or ",
                   "\n   54616472580713218117605158262983887/81129638414606681695789005144064\nGot: $ret\n";
  print "not ok 36\n";
}

eval{$ret -=  $inf };
if($@ =~ /cannot coerce an Inf to a Math::GMP/) {print "ok 37\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 37\n";
}

eval{$ret -= "$strinf"};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_sub_eq/) {print "ok 38\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 38\n";
}

eval{$ret -=  $nan };
if($@ =~ /cannot coerce a NaN to a Math::GMP/) {print "ok 39\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 39\n";
}

eval{$ret -= "$strnan"};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_sub_eq/) {print "ok 40\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 40\n";
}

eval{$ret -= "61.2"};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_sub_eq/) {print "ok 41\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 41\n";
}

$ret -= 61.2;

if($ret == '21532835718365185/35184372088832' ||
   $ret == '88198495102423793665/144115188075855872' ||
   $ret == '387901083669838196857991180845055/633825300114114700748351602688' ||
   $ret == '24825669354869644598911435574083585/40564819207303340847894502572032') {print "ok 42\n"}
else {
  warn "\n Expected:\n   21532835718365185/35184372088832 or ",
                   "\n   88198495102423793665/144115188075855872 or ",
                   "\n   387901083669838196857991180845055/633825300114114700748351602688 or ",
                   "\n   24825669354869644598911435574083585/40564819207303340847894502572032\nGot: $ret\n";
  print "not ok 42\n";
}

eval{$ret /=  $inf };
if($@ =~ /cannot coerce an Inf to a Math::GMP/) {print "ok 43\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 43\n";
}

eval{$ret /= "$strinf"};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_div_eq/) {print "ok 44\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 44\n";
}

eval{$ret /=  $nan };
if($@ =~ /cannot coerce a NaN to a Math::GMP/) {print "ok 45\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 45\n";
}

eval{$ret /= "$strnan"};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_div_eq/) {print "ok 46\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 46\n";
}

eval{$ret /= "61.2"};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_div_eq/) {print "ok 47\n"}
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

if(Math::GMPq->new(10) ==  $inf ) {
  warn "\n 10 == $inf\n";
  print "not ok 49\n";
}
else {print "ok 49\n"}

if(Math::GMPq->new(10) ==  $ninf ) {
  warn "\n 10 == $ninf\n";
  print "not ok 50\n";
}
else {print "ok 50\n"}

if("$strinf" =~ /^inf/i || $^O =~ /MSWin/) {
  if(Math::GMPq->new(10) == "$strinf") {
    warn "\n 10 == infinity\n";
    print "not ok 51\n";
  }
  else {print "ok 51\n"}
}
else {
  eval {$x = (Math::GMPq->new(10) == "$strinf")};
  if($@ =~ /Invalid string supplied to Math::GMPq::overload_equiv/) {print "ok 51\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 51\n";
  }
}

eval{$x = (Math::GMPq->new(10) ==  $nan )};
if($@ =~ /In Math::GMPq::overload_equiv, cannot compare a NaN to a Math::GMPq value/) {print "ok 52\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 52\n";
}
eval{$x = (Math::GMPq->new(10) == "$strnan")};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_equiv/) {print "ok 53\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 53\n";
}

eval{$x = (Math::GMPq->new(10) == "61.2")};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_equiv/) {print "ok 54\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 54\n";
}

my $dec = 10.0;
if(Math::GMPq->new(10) == $dec) {print "ok 55\n"}
else {
  warn "\n ", Math::GMPq->new(10), " != $dec\n";
  print "not ok 55\n";
}

if(Math::GMPq->new(10) !=  $inf ) {print "ok 56\n"}
else {
  warn "\n 10 == $inf\n";
  print "not ok 56\n";
}

if(Math::GMPq->new(10) !=  $ninf ) {print "ok 57\n"}
else {
  warn "\n 10 == $ninf\n";
  print "not ok 57\n";
}

if("$strinf" =~ /^inf/i || $^O =~ /MSWin/) {
  if(Math::GMPq->new(10) != "$strinf") {print "ok 58\n"}
  else {
    warn "\n 10 == infinity\n";
    print "not ok 58\n";
  }
}
else {
  eval{$x = (Math::GMPq->new(10) != "$strinf")};
  if($@ =~ /Invalid string supplied to Math::GMPq::overload_not_equiv/) {print "ok 58\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 58\n";
  }
}

eval{$x = (Math::GMPq->new(10) !=  $nan )};
if($@ =~ /In Math::GMPq::overload_not_equiv, cannot compare a NaN to a Math::GMPq value/) {print "ok 59\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 59\n";
}

eval{$x = (Math::GMPq->new(10) != "$strnan")};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_not_equiv/) {print "ok 60\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 60\n";
}

eval{$x = (Math::GMPq->new(10) != "61.2")};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_not_equiv/) {print "ok 61\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 61\n";
}

$dec += 0.9;;
if(Math::GMPq->new(10) != $dec) {print "ok 62\n"}
else {
  warn "\n ", Math::GMPq->new(10), " == $dec\n";
  print "not ok 62\n";
}

if(Math::GMPq->new(10) <  $inf ) {print "ok 63\n"}
else {
  warn "\n 10 >= $inf\n";
  print "not ok 63\n";
}

if(Math::GMPq->new(10) <  $ninf ) {
  warn "\n10 < $ninf\n";
  print "not ok 64\n";
}
else {print "ok 64\n"}

if("$strinf" =~ /^inf/i || $^O =~ /MSWin/) {
  if(Math::GMPq->new(10) < "$strinf") {print "ok 65\n"}
  else {
    warn "\n 10 >= infinity\n";
    print "not ok 65\n";
  }
}
else {
  eval{$x = (Math::GMPq->new(10) < "$strinf")};
  if($@ =~ /Invalid string supplied to Math::GMPq::overload_lt/) {print "ok 65\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 65\n";
  }
}

eval{$x = (Math::GMPq->new(10) <  $nan )};
if($@ =~ /cannot coerce a NaN to a Math::GMP/) {print "ok 66\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 66\n";
}

eval{$x = (Math::GMPq->new(10) < "$strnan")};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_lt/) {print "ok 67\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 67\n";
}

eval{$x = (Math::GMPq->new(10) < "61.2")};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_lt/) {print "ok 68\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 68\n";
}

$dec += 2.0;

if(Math::GMPq->new(10) < $dec) {print "ok 69\n"}
else {
  warn "\n ", Math::GMPq->new(10), " !< $dec\n";
  print "not ok 69\n";
}

if(Math::GMPq->new(10) <=  $inf ) {print "ok 70\n"}
else {
  warn "\n 10 > $inf\n";
  print "not ok 70\n";
}

if(Math::GMPq->new(10) <=  $ninf ) {
  warn "\n10 <= $ninf\n";
  print "not ok 71\n";
}
else {print "ok 71\n"}

if("$strinf" =~ /^inf/i || $^O =~ /MSWin/) {
  if(Math::GMPq->new(10) <= "$strinf") {print "ok 72\n"}
  else {
    warn "\n 10 > infinity\n";
    print "not ok 72\n";
  }
}
else {
  eval{$x = (Math::GMPq->new(10) <= "$strinf")};
  if($@ =~ /Invalid string supplied to Math::GMPq::overload_lte/) {print "ok 72\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 72\n";
  }
}

eval{$x = (Math::GMPq->new(10) <=  $nan )};
if($@ =~ /cannot coerce a NaN to a Math::GMP/) {print "ok 73\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 73\n";
}

eval{$x = (Math::GMPq->new(10) <= "$strnan")};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_lte/) {print "ok 74\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 74\n";
}

eval{$x = (Math::GMPq->new(10) <= "61.2")};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_lte/) {print "ok 75\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 75\n";
}

$dec -= 2.0;
if(Math::GMPq->new(10) <= $dec) {print "ok 76\n"}
else {
  warn "\n ", Math::GMPq->new(10), " > $dec\n";
  print "not ok 76\n";
}

if(Math::GMPq->new(10) >=  $inf ) {
  warn "\n 10 >= $inf\n";
  print "not ok 77\n";
}
else {print "ok 77\n"}

if(Math::GMPq->new(10) >= $ninf) {print "ok 78\n"}
else {
  warn "\n 10 < $ninf\n";
  print "not ok 78\n";
}

if("$strinf" =~ /^inf/i || $^O =~ /MSWin/) {
  if(Math::GMPq->new(10) >= "$strinf") {
    warn "\n 10 >= infinity\n";
    print "not ok 79\n";
  }
  else {print "ok 79\n"}
}
else {
  eval{$x = (Math::GMPq->new(10) >= "$strinf")};
  if($@ =~ /Invalid string supplied to Math::GMPq::overload_gte/) {print "ok 79\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 79\n";
  }
}

eval{$x = (Math::GMPq->new(10) >=  $nan )};
if($@ =~ /cannot coerce a NaN to a Math::GMP/) {print "ok 80\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 80\n";
}

eval{$x = (Math::GMPq->new(10) >= "$strnan")};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_gte/) {print "ok 81\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 81\n";
}

eval{$x = (Math::GMPq->new(10) >= "61.2")};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_gte/) {print "ok 82\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 82\n";
}

$dec -= 1.0;

if(Math::GMPq->new(10) >= $dec) {print "ok 83\n"}
else {
  warn "\n ", Math::GMPq->new(10), " < $dec\n";
  print "not ok 83\n";
}

if(Math::GMPq->new(10) >  $inf ) {
  warn "\n 10 > $inf\n";
  print "not ok 84\n";
}
else {print "ok 84\n"}

if(Math::GMPq->new(10) > $ninf) {print "ok 85\n"}
else {
  warn "\n 10 <= $ninf\n";
  print "not ok 85\n";
}

if("$strinf" =~ /^inf/i || $^O =~ /MSWin/) {
  if(Math::GMPq->new(10) > "$strinf") {
    warn "\n 10 > infinity\n";
    print "not ok 86\n";
  }
  else {print "ok 86\n"}
}
else {
  eval{$x = (Math::GMPq->new(10) > "$strinf")};
  if($@ =~ /Invalid string supplied to Math::GMPq::overload_gt/) {print "ok 86\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 86\n";
  }
}

eval{$x = (Math::GMPq->new(10) >  $nan )};
if($@ =~ /cannot coerce a NaN to a Math::GMP/) {print "ok 87\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 87\n";
}

eval{$x = (Math::GMPq->new(10) > "$strnan")};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_gt/) {print "ok 88\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 88\n";
}

eval{$x = (Math::GMPq->new(10) > "61.2")};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_gt/) {print "ok 89\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 89\n";
}

$dec -= 1.0;
if(Math::GMPq->new(10) > $dec) {print "ok 90\n"}
else {
  warn "\n ", Math::GMPq->new(10), " !> $dec\n";
  print "not ok 90\n";
}

if(Math::GMPq->new(6) < 6.5) {print  "ok 91\n"}
else {
  warn "\n 6 >= 6.5\n";
  print "not ok 91\n";
}

if(Math::GMPq->new(6) <= 6.5) {print  "ok 92\n"}
else {
  warn "\n 6 > 6.5\n";
  print "not ok 92\n";
}

if(Math::GMPq->new(-6) > -6.5) {print  "ok 93\n"}
else {
  warn "\n -6 <= -6.5\n";
  print "not ok 93\n";
}

if(Math::GMPq->new(-6) >= -6.5) {print  "ok 94\n"}
else {
  warn "\n -6 < -6.5\n";
  print "not ok 94\n";
}

if(Math::GMPq->new(10) == $inf * -1) {
  warn "\n 10 == -inf\n";
  print "ok 95\n";
}
else {print "ok 95\n"}

if(Math::GMPq->new(10) < $inf * -1) {
  warn "\n 10 < -inf\n";
  print "ok 96\n";
}
else {print "ok 96\n"}

if(Math::GMPq->new(10) <= $inf * -1) {
  warn "\n 10 <= -inf\n";
  print "ok 97\n";
}
else {print "ok 97\n"}

if(Math::GMPq->new(10) > $inf * -1) {print "ok 98\n"}
else {
  warn "\n 10 <= -inf\n";
  print "ok 98\n";
}

if(Math::GMPq->new(10) >= $inf * -1) {print "ok 99\n"}
else {
  warn "\n 10 < -inf\n";
  print "ok 99\n";
}

if(Math::GMPq->new(10) != $inf * -1) {print "ok 100\n"}
else {
  warn "\n 10 == -inf\n";
  print "ok 100\n";
}

#########################
#########################

if("$strinf" =~ /^inf/i || $^O =~ /MSWin/) {
  if((Math::GMPq->new(10) <=> "$strinf") < 0) {print "ok 101\n"}
  else {
    warn "\n 10 !< inf\n";
    print "not ok 101\n";
  }
}
else {
  eval{$x = (Math::GMPq->new(10) <=> "$strinf")};
  if($@ =~ /Invalid string supplied to Math::GMPq::overload_spaceship/) {print "ok 101\n"}
  else {
    warn "\n\$\@: $@\n";
    print "not ok 101\n";
  }
}

eval{$x = (Math::GMPq->new(10) <=>  $nan )};
if($@ =~ /cannot coerce a NaN to a Math::GMP/) {print "ok 102\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 102\n";
}

eval{$x = (Math::GMPq->new(10) <=> "$strnan")};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_spaceship/) {print "ok 103\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 103\n";
}

eval{$x = (Math::GMPq->new(10) <=> "61.2")};
if($@ =~ /Invalid string supplied to Math::GMPq::overload_spaceship/) {print "ok 104\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 104\n";
}

if((Math::GMPq->new(10) <=> $inf) < 0){print "ok 105\n"}
else {
  warn "\n 10 !< inf\n";
  print "not ok 105\n";
}

if((Math::GMPq->new(10) <=> $inf * -1) > 0){print "ok 106\n"}
else {
  warn "\n 10 !> inf\n";
  print "not ok 106\n";
}

##########################
##########################


if("$strninf" =~ /^\-inf/i || $^O =~ /MSWin/) {
  my $z = Math::GMPq->new(-3);

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
}
else {
  warn "\n Skipping tests 107..113 (not MSWin, and -iNf !~ /^\\-inf/i)\n";
  for(107 .. 113 ) {print "ok $_\n"}
}

if(Math::GMPq->new(0.005859375) == '3/512') {print "ok 114\n"}
else {
   warn "\nExpected 3/512, Got ", Math::GMPq->new(0.005859375);
   print "not ok 114\n";
}


if(Math::GMPq->new(585937.5e-8) == '3/512') {print "ok 115\n"}
else {
   warn "\nExpected 3/512, Got ", Math::GMPq->new(585937.5e-8);
   print "not ok 115\n";
}

if(Math::GMPq->new(-86.0009765625) == '-88065/1024') {print "ok 116\n"}
else {
   warn "\nExpected -88065/1024, Got ", Math::GMPq->new(-86.0009765625);
   print "not ok 116\n";
}

my $big_nv = 2**1015;

if(Math::GMPq->new($big_nv) == '351111940402796075728379920075981393284761128699669252487168127261196632432619068618571244770327218791250222421623815151677323767215657465806342637967722899175327916845440400930277772658683777577056802640791026892262013051450122815378736544025053197584668966180832613749896964723593195907881555331297312768') {
  print "ok 117\n";
}
else {
  warn "\n Expected:\n351111940402796075728379920075981393284761128699669252487168127261196632432619068618571244770327218791250222421623815151677323767215657465806342637967722899175327916845440400930277772658683777577056802640791026892262013051450122815378736544025053197584668966180832613749896964723593195907881555331297312768\n",
       "Got:\n", Math::GMPq->new($big_nv);
  print "not ok 117\n";
}

if(Math::GMPq->new(0.0) == '0') {print "ok 118\n"}
else {
  warn "\n ", Math::GMPq->new(0.0), "!= 0\n";
  print "not ok 118\n";
}

if(Math::GMPq->new(-0.0) == '0') {print "ok 119\n"}
else {
  warn "\n ", Math::GMPq->new(-0.0), "!= 0\n";
  print "not ok 119\n";
}

if(Math::GMPq->new(0.1) == 0.1) {print "ok 120\n" }
else {
  warn "\n ", Math::GMPq->new(0.1), "!= 0.1\n";
  print "not ok 120\n";
}

my $s1 = sprintf "%.5g", Math::GMPq->new(0.625);

if($s1 == 0.625) {print "ok 121\n"}
else {
  warn "\n $s1 != 0.625\n";
  print "not ok 121\n";
}
