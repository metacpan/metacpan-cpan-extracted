use strict;
use warnings;
use Math::Float128 qw(:all);

print "1..25\n";

my $uv = ~0;
my $iv = -21;
my $nv = -17.1;
my $str = "-17.1";
my $strp = "17.1";
my $obj = Math::Float128->new(19.0);
my $nan = F128toNV(Math::Float128->new());

my $zero = ZeroF128(-1);
my $one = UnityF128(1);
my $div;
my $ok = '';

# +

if($zero + $uv == $uv) {$ok .= 'a'}
else {warn "\n1a: ", $zero + $uv, "\n"}

if($zero + $iv == $iv) {$ok .= 'b'}
else {warn "\n1b: ", $zero + $iv, "\n"}

if($zero + $nv == $nv) {$ok .= 'c'}
else {warn "\n1c: ", $zero + $nv, "\n"}

if($zero + "$str" == "$str") {$ok .= 'd'}
else {warn "\n1d: ", $zero + "$str", "\n"}

if($zero + $obj == $obj) {$ok .= 'e'}
else {warn "\n1e: ", $zero + $obj, "\n"}

if($ok eq 'abcde') {print "ok 1\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 1\n";
}

$ok = '';

#############

# *

if($one * $uv == $uv) {$ok .= 'a'}
else {warn "\n2a: ", $one * $uv, "\n"}

if($one * $iv == $iv) {$ok .= 'b'}
else {warn "\n2b: ", $one * $iv, "\n"}

if($one * $nv == $nv) {$ok .= 'c'}
else {warn "\n2c: ", $one * $nv, "\n"}

if($one * "$str" == "$str") {$ok .= 'd'}
else {warn "\n2d: ", $one * "$str", "\n"}

if($one * $obj == $obj) {$ok .= 'e'}
else {warn "\n2e: ", $one * $obj, "\n"}

if($ok eq 'abcde') {print "ok 2\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 2\n";
}

$ok = '';

#############

# -

if(($zero - $uv) * -1 == $uv) {$ok .= 'a'}
else {warn "\n3a: ", $zero - $uv, "\n"}

if($zero - $iv == -$iv) {$ok .= 'b'}
else {warn "\n3b: ", $zero - $iv, "\n"}

if($zero - $nv == -$nv) {$ok .= 'c'}
else {warn "\n3c: ", $zero - $nv, "\n"}

if($zero - "$str" == "$strp") {$ok .= 'd'}
else {warn "\n3d: ", $zero - "$str", "\n"}

if($zero - $obj == -$obj) {$ok .= 'e'}
else {warn "\n3e: ", $zero - $obj, "\n"}

if($ok eq 'abcde') {print "ok 3\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 3\n";
}

$ok = '';

#############

# -

if($uv - $zero == $uv) {$ok .= 'a'}
else {warn "\n4a: ", $uv - $zero, "\n"}

if($iv - $zero == $iv) {$ok .= 'b'}
else {warn "\n4b: ", $iv - $zero, "\n"}

if($nv - $zero == $nv) {$ok .= 'c'}
else {warn "\n4c: ", $nv - $zero, "\n"}

if("$str" - $zero == "$str") {$ok .= 'd'}
else {warn "\n4d: ", "$str" - $zero, "\n"}

if($obj - $zero == $obj) {$ok .= 'e'}
else {warn "\n4e: ", $obj - $zero, "\n"}

if($ok eq 'abcde') {print "ok 4\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 4\n";
}

$ok = '';

#############

# /

if($uv / $one == $uv) {$ok .= 'a'}
else {warn "\n5a: ", $uv / $one, "\n"}

if($iv / $one == $iv) {$ok .= 'b'}
else {warn "\n5b: ", $iv / $one, "\n"}

if($nv / $one == $nv) {$ok .= 'c'}
else {warn "\n5c: ", $nv / $one, "\n"}

if("$str" / $one == "$str") {$ok .= 'd'}
else {warn "\n5d: ", "$str" / $one, "\n"}

if($obj / $one == $obj) {$ok .= 'e'}
else {warn "\n5e: ", $obj / $one, "\n"}

if($ok eq 'abcde') {print "ok 5\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 5\n";
}

$ok = '';

#############

# -

if(Math::Float128->new($uv) / $uv == 1) {$ok .= 'a'}
else {warn "\n6a: ", Math::Float128->new($uv) / $uv, "\n"}

if(Math::Float128->new($iv) / $iv == 1) {$ok .= 'b'}
else {warn "\n6b: ", Math::Float128->new($iv) / $iv, "\n"}

if(Math::Float128->new($nv) / $nv == 1) {$ok .= 'c'}
else {warn "\n6c: ", Math::Float128->new($nv) / $nv, "\n"}

if(Math::Float128->new("$str") / "$str" == 1) {$ok .= 'd'}
else {warn "\n6d: ", Math::Float128->new("$str") / "$str", "\n"}

if(Math::Float128->new($obj) / $obj == 1) {$ok .= 'e'}
else {warn "\n6e: ", Math::Float128->new($obj) / $obj, "\n"}

if($ok eq 'abcde') {print "ok 6\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 6\n";
}

$ok = '';

#############

# +=

$zero += $uv;
if($zero == $uv) {$ok .= 'a'}
else {warn "\n7a: ", $zero + $uv, "\n"}
$zero = ZeroF128(-1);

$zero += $iv;
if($zero == $iv) {$ok .= 'b'}
else {warn "\n7b: ", $zero + $iv, "\n"}
$zero = ZeroF128(-1);

$zero += $nv;
if($zero == $nv) {$ok .= 'c'}
else {warn "\n7c: ", $zero + $nv, "\n"}
$zero = ZeroF128(-1);

$zero += "$str";
if($zero == "$str") {$ok .= 'd'}
else {warn "\n7d: ", $zero + "$str", "\n"}
$zero = ZeroF128(-1);

$zero += $obj;
if($zero == $obj) {$ok .= 'e'}
else {warn "\n7e: ", $zero + $obj, "\n"}
$zero = ZeroF128(-1);

if($ok eq 'abcde') {print "ok 7\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 7\n";
}

$ok = '';

#############

# *=

$one *= $uv;
if($one == $uv) {$ok .= 'a'}
else {warn "\n8a: ", $one, "\n"}
$one = UnityF128(1);

$one *= $iv;
if($one == $iv) {$ok .= 'b'}
else {warn "\n8b: ", $one, "\n"}
$one = UnityF128(1);

$one *= $nv;
if($one == $nv) {$ok .= 'c'}
else {warn "\n8c: ", $one, "\n"}
$one = UnityF128(1);

$one *= "$str";
if($one == "$str") {$ok .= 'd'}
else {warn "\n8d: ", $one, "\n"}
$one = UnityF128(1);

$one *= $obj;
if($one == $obj) {$ok .= 'e'}
else {warn "\n8e: ", $one, "\n"}
$one = UnityF128(1);

if($ok eq 'abcde') {print "ok 8\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 8\n";
}

$ok = '';

#############

# -=

$zero -= $uv;
if($zero * -1 == $uv) {$ok .= 'a'}
else {warn "\n9a: ", $zero, "\n"}
$zero = ZeroF128(-1);

$zero -= $iv;
if($zero == -$iv) {$ok .= 'b'}
else {warn "\n9b: ", $zero, "\n"}
$zero = ZeroF128(-1);

$zero -= $nv;
if($zero == -$nv) {$ok .= 'c'}
else {warn "\n9c: ", $zero, "\n"}
$zero = ZeroF128(-1);

$zero -= "$str";
if($zero == "$strp") {$ok .= 'd'}
else {warn "\n9d: ", $zero, "\n"}
$zero = ZeroF128(-1);

$zero -= $obj;
if($zero == -$obj) {$ok .= 'e'}
else {warn "\n9e: ", $zero, "\n"}
$zero = ZeroF128(-1);

if($ok eq 'abcde') {print "ok 9\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 9\n";
}

$ok = '';

#############

# /=

$div = Math::Float128->new($uv);
$div /= $uv;
if($div == 1) {$ok .= 'a'}
else {warn "\n10a: ", $div, "\n"}

$div = Math::Float128->new($iv);
$div /= $iv;
if($div == 1) {$ok .= 'b'}
else {warn "\n10b: ", $div, "\n"}

$div = Math::Float128->new($nv);
$div /= $nv;
if($div == 1) {$ok .= 'c'}
else {warn "\n10c: ", $div, "\n"}

$div = Math::Float128->new("$str");
$div /= "$str";
if($div == 1) {$ok .= 'd'}
else {warn "\n10d: ", $div, "\n"}

$div = Math::Float128->new($obj);
$div /= $obj;
if($div == 1) {$ok .= 'e'}
else {warn "\n10e: ", $div, "\n"}

if($ok eq 'abcde') {print "ok 10\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 10\n";
}

$ok = '';

#############

# !=

$div = Math::Float128->new($uv) - 1;
if($div != $uv) {$ok .= 'a'}
else {warn "\n11a: ", $div, "\n"}

$div = Math::Float128->new($iv) + 0.1;
if($div != $iv) {$ok .= 'b'}
else {warn "\n11b: ", $div, "\n"}

$div = Math::Float128->new($nv) + 0.1;
if($div != $nv) {$ok .= 'c'}
else {warn "\n11c: ", $div, "\n"}

$div = Math::Float128->new("$str") + 0.1;
if($div != "$str") {$ok .= 'd'}
else {warn "\n11d: ", $div, "\n"}

$div = Math::Float128->new($obj) + 0.1;
if($div != $obj) {$ok .= 'e'}
else {warn "\n11e: ", $div, "\n"}

unless($div == $nan) {$ok .= 'f'}
else {warn "\n11f: ", $div == $nan, "\n"}

if($div != $nan) {$ok .= 'g'}
else {warn "\n11g: ", $div != $nan, "\n"}

if($ok eq 'abcdefg') {print "ok 11\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 11\n";
}

$ok = '';

#############

# <=

$div = Math::Float128->new($uv) - 0.1;
if($div <= $uv) {$ok .= 'a'}
else {warn "\n12a: ", $div, "\n"}

$div = Math::Float128->new($iv) - 0.1;
if($div <= $iv) {$ok .= 'b'}
else {warn "\n12b: ", $div, "\n"}

$div = Math::Float128->new($nv) - 0.1;
if($div <= $nv) {$ok .= 'c'}
else {warn "\n12c: ", $div, "\n"}

$div = Math::Float128->new("$str") - 0.1;
if($div <= "$str") {$ok .= 'd'}
else {warn "\n12d: ", $div, "\n"}

$div = Math::Float128->new($obj) - 0.1;
if($div <= $obj) {$ok .= 'e'}
else {warn "\n12e: ", $div, "\n"}

if($ok eq 'abcde') {print "ok 12\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 12\n";
}

$ok = '';

#############

# <=

$div = Math::Float128->new($uv);
if($div <= $uv) {$ok .= 'a'}
else {warn "\n13a: ", $div, "\n"}

$div = Math::Float128->new($iv);
if($div <= $iv) {$ok .= 'b'}
else {warn "\n13b: ", $div, "\n"}

$div = Math::Float128->new($nv);
if($div <= $nv) {$ok .= 'c'}
else {warn "\n13c: ", $div, "\n"}

$div = Math::Float128->new("$str");
if($div <= "$str") {$ok .= 'd'}
else {warn "\n13d: ", $div, "\n"}

$div = Math::Float128->new($obj);
if($div <= $obj) {$ok .= 'e'}
else {warn "\n13e: ", $div, "\n"}

unless($div <= $nan) {$ok .= 'f'}
else {warn "\n13f: ", $div <= $nan, "\n"}

if($ok eq 'abcdef') {print "ok 13\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 13\n";
}

$ok = '';

#############

# <

$div = Math::Float128->new($uv) - 1;
if($div < $uv) {$ok .= 'a'}
else {warn "\n14a: ", $div, "\n"}

$div = Math::Float128->new($iv) - 0.1;
if($div < $iv) {$ok .= 'b'}
else {warn "\n14b: ", $div, "\n"}

$div = Math::Float128->new($nv) - 0.1;
if($div < $nv) {$ok .= 'c'}
else {warn "\n14c: ", $div, "\n"}

$div = Math::Float128->new("$str") - 0.1;
if($div < "$str") {$ok .= 'd'}
else {warn "\n14d: ", $div, "\n"}

$div = Math::Float128->new($obj) - 0.1;
if($div < $obj) {$ok .= 'e'}
else {warn "\n14e: ", $div, "\n"}

unless($div < $nan) {$ok .= 'f'}
else {warn "\n14f: ", $div < $nan, "\n"}

if($ok eq 'abcdef') {print "ok 14\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 14\n";
}

$ok = '';

#############

# >=

$div = Math::Float128->new($uv) + 0.1;
if($div >= $uv) {$ok .= 'a'}
else {warn "\n15a: ", $div, "\n"}

$div = Math::Float128->new($iv) + 0.1;
if($div >= $iv) {$ok .= 'b'}
else {warn "\n15b: ", $div, "\n"}

$div = Math::Float128->new($nv) + 0.1;
if($div >= $nv) {$ok .= 'c'}
else {warn "\n15c: ", $div, "\n"}

$div = Math::Float128->new("$str") + 0.1;
if($div >= "$str") {$ok .= 'd'}
else {warn "\n15d: ", $div, "\n"}

$div = Math::Float128->new($obj) + 0.1;
if($div >= $obj) {$ok .= 'e'}
else {warn "\n15e: ", $div, "\n"}

if($ok eq 'abcde') {print "ok 15\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 15\n";
}

$ok = '';

#############

# >=

$div = Math::Float128->new($uv);
if($div >= $uv) {$ok .= 'a'}
else {warn "\n16a: ", $div, "\n"}

$div = Math::Float128->new($iv);
if($div >= $iv) {$ok .= 'b'}
else {warn "\n16b: ", $div, "\n"}

$div = Math::Float128->new($nv);
if($div >= $nv) {$ok .= 'c'}
else {warn "\n16c: ", $div, "\n"}

$div = Math::Float128->new("$str");
if($div >= "$str") {$ok .= 'd'}
else {warn "\n16d: ", $div, "\n"}

$div = Math::Float128->new($obj);
if($div >= $obj) {$ok .= 'e'}
else {warn "\n16e: ", $div, "\n"}

unless($div >= $nan) {$ok .= 'f'}
else {warn "\n16f: ", $div >= $nan, "\n"}

if($ok eq 'abcdef') {print "ok 16\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 16\n";
}

$ok = '';

#############

# >

$div = Math::Float128->new($uv) + 1;
if($div > $uv) {$ok .= 'a'}
else {warn "\n17a: ", $div, "\n"}

$div = Math::Float128->new($iv) + 0.1;
if($div > $iv) {$ok .= 'b'}
else {warn "\n17b: ", $div, "\n"}

$div = Math::Float128->new($nv) + 0.1;
if($div > $nv) {$ok .= 'c'}
else {warn "\n17c: ", $div, "\n"}

$div = Math::Float128->new("$str") + 0.1;
if($div > "$str") {$ok .= 'd'}
else {warn "\n17d: ", $div, "\n"}

$div = Math::Float128->new($obj) + 0.1;
if($div > $obj) {$ok .= 'e'}
else {warn "\n17e: ", $div, "\n"}

unless($div > $nan) {$ok .= 'f'}
else {warn "\n17f: ", $div > $nan, "\n"}

if($ok eq 'abcdef') {print "ok 17\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 17\n";
}

$ok = '';

#############

# <=>

$div = Math::Float128->new($uv) + 1;
if(($div <=> $uv) > 0) {$ok .= 'a'}
else {warn "\n18a: ", $div, "\n"}

$div = Math::Float128->new($iv) + 0.1;
if(($div <=> $iv) > 0) {$ok .= 'b'}
else {warn "\n18b: ", $div, "\n"}

$div = Math::Float128->new($nv) + 0.1;
if(($div <=> $nv) > 0) {$ok .= 'c'}
else {warn "\n18c: ", $div, "\n"}

$div = Math::Float128->new("$str") + 0.1;
if(($div <=> "$str") > 0) {$ok .= 'd'}
else {warn "\n18d: ", $div, "\n"}

$div = Math::Float128->new($obj) + 0.1;
if(($div <=> $obj) > 0) {$ok .= 'e'}
else {warn "\n18e: ", $div, "\n"}

if($ok eq 'abcde') {print "ok 18\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 18\n";
}

$ok = '';

#############

# <=>

$div = Math::Float128->new($uv) - 1;
if(($div <=> $uv) < 0) {$ok .= 'a'}
else {warn "\n19a: ", $div, "\n"}

$div = Math::Float128->new($iv) - 0.1;
if(($div <=> $iv) < 0) {$ok .= 'b'}
else {warn "\n19b: ", $div, "\n"}

$div = Math::Float128->new($nv) - 0.1;
if(($div <=> $nv) < 0) {$ok .= 'c'}
else {warn "\n19c: ", $div, "\n"}

$div = Math::Float128->new("$str") - 0.1;
if(($div <=> "$str") < 0) {$ok .= 'd'}
else {warn "\n19d: ", $div, "\n"}

$div = Math::Float128->new($obj) - 0.1;
if(($div <=> $obj) < 0) {$ok .= 'e'}
else {warn "\n19e: ", $div, "\n"}

if($ok eq 'abcde') {print "ok 19\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 19\n";
}

$ok = '';

#############

# <=>

$div = Math::Float128->new($uv);
if(defined($div <=> $uv) && ($div <=> $uv) == 0) {$ok .= 'a'}
else {warn "\n20a: ", $div, "\n"}

$div = Math::Float128->new($iv);
if(defined($div <=> $iv) && ($div <=> $iv) == 0) {$ok .= 'b'}
else {warn "\n20b: ", $div, "\n"}

$div = Math::Float128->new($nv);
if(defined($div <=> $nv) && ($div <=> $nv) == 0) {$ok .= 'c'}
else {warn "\n20c: ", $div, "\n"}

$div = Math::Float128->new("$str");
if(defined($div <=> "$str") && ($div <=> "$str") == 0) {$ok .= 'd'}
else {warn "\n20d: ", $div, "\n"}

$div = Math::Float128->new($obj);
if(defined($div <=> $obj) && ($div <=> $obj) == 0) {$ok .= 'e'}
else {warn "\n20e: ", $div, "\n"}

if(!defined($div <=> $nan)) {$ok .= 'f'}
else {warn "\n20f: ", $div <=> $nan, "\n"}


if($ok eq 'abcdef') {print "ok 20\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 20\n";
}

$ok = '';

#############

# <=>

if(!defined(NaNF128() <=> $uv)) {$ok .= 'a'}
else {warn "\n21a: ", NaNF128() <=> $uv, "\n"}

if(!defined(NaNF128() <=> $iv)) {$ok .= 'b'}
else {warn "\n21b: ", NaNF128() <=> $iv, "\n"}

if(!defined(NaNF128() <=> $nv)) {$ok .= 'c'}
else {warn "\n21c: ", NaNF128() <=> $nv, "\n"}

if(!defined(NaNF128() <=> "$str")) {$ok .= 'd'}
else {warn "\n21d: ", NaNF128() <=> "$str", "\n"}

if(!defined(NaNF128() <=> $obj)) {$ok .= 'e'}
else {warn "\n21e: ", NaNF128() <=> $obj, "\n"}

if($ok eq 'abcde') {print "ok 21\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 21\n";
}

$ok = '';

#############

if($nan != $nan) {print "ok 22\n"}
else {
  warn "\$nan: $nan\n";
  print "not ok 22\n";
}

if($nan ** ZeroF128(1) == 1) {print "ok 23\n"}
else {
  warn "\n23: ", $nan ** ZeroF128(1), "\n";
  print "not ok 23\n";
}

#############

# **

if(approx(Math::Float128->new(0.9) ** 2, 0.9 ** 2)) {$ok .= 'a'}
else {warn "\n24a: ", Math::Float128->new(0.9) ** 2, "\n"}

if(approx(Math::Float128->new(0.9) ** 2.1, 0.9 ** 2.1)) {$ok .= 'b'}
else {warn "\n24b: ", Math::Float128->new(0.9) ** 2.1, "\n"}

if(approx(Math::Float128->new(0.9) ** "2.1", 0.9 ** 2.1)) {$ok .= 'c'}
else {warn "\n24c: ", Math::Float128->new(0.9) ** "2.1", "\n"}

if(approx(Math::Float128->new(0.9) ** Math::Float128->new("2.1"), 0.9 ** 2.1)) {$ok .= 'd'}
else {warn "\n24d: ", Math::Float128->new(0.9) ** "2.1", "\n"}

if($ok eq 'abcd') {print "ok 24\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 24\n";
}

$ok = '';

#############

# **=

$div = Math::Float128->new(0.9);
$div **= 2;
if(approx($div, 0.9 ** 2)) {$ok .= 'a'}
else {warn "\n25a: ", $div, "\n"}

$div = Math::Float128->new(0.9);
$div **= 2.1;
if(approx($div, 0.9 ** 2.1)) {$ok .= 'b'}
else {warn "\n25b: ", $div, "\n"}

$div = Math::Float128->new(0.9);
$div **= "2.1";
if(approx($div, 0.9 ** 2.1)) {$ok .= 'c'}
else {warn "\n25c: ", $div, "\n"}

$div = Math::Float128->new(0.9);
$div **= Math::Float128->new(2.1);
if(approx($div, 0.9 ** 2.1)) {$ok .= 'd'}
else {warn "\n25de: ", $div, "\n"}

if($ok eq 'abcd') {print "ok 25\n"}
else {
  warn "\n\$ok: $ok\n";
  print "not ok 25\n";
}

$ok = '';

#############


sub approx {
    my $eps = abs($_[0] - Math::Float128->new($_[1]));
    return 0 if  $eps > Math::Float128->new(0.000000001);
    return 1;
}

