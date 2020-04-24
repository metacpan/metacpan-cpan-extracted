use warnings;
use strict;
use Math::Float128 qw(:all);

print "1..20\n";

my($uv, $iv, $nv, $pv, $pv_copy1, $pv_copy2);

$uv = Math::Float128->new(~0);
if($uv == UVtoF128(~0)) {print "ok 1\n"}
else {
  warn "New: $uv\nUVtoF128: ", UVtoF128(~0), "\n";
  print "not ok 1\n";
}

$iv = Math::Float128->new(-23);
$pv = Math::Float128->new('-23');

if($pv == $iv){print "ok 2\n"}
else {
  warn "\$pv: $pv\n\$iv: $iv\n";
  print "not ok 2\n";
}

$pv += Math::Float128->new(0.5);
$nv = Math::Float128->new(-22.5);

if($pv == $nv) {print "ok 3\n"}
else {
  warn "\$pv: $pv\n\$nv: $nv\n";
  print "not ok 3\n";
}

$pv_copy1 = $pv;

if($pv == $pv_copy1) {print "ok 4\n"}
else {
  warn "\$pv: $pv\n\$pv_copy1: $pv_copy1\n";
  print "not ok 4\n";
}

$pv_copy2 = Math::Float128->new($pv);

if($pv == $pv_copy2) {print "ok 5\n"}
else {
  warn "\$pv: $pv\n\$pv_copy2: $pv_copy2\n";
  print "not ok 5\n";
}

$uv = Math::Float128::new(~0);
if($uv == UVtoF128(~0)) {print "ok 6\n"}
else {
  warn "New: $uv\nUVtoF128: ", UVtoF128(~0), "\n";
  print "not ok 6\n";
}

$iv = Math::Float128::new(-23);
$pv = Math::Float128::new('-23');

if($pv == $iv){print "ok 7\n"}
else {
  warn "\$pv: $pv\n\$iv: $iv\n";
  print "not ok 7\n";
}

$pv += Math::Float128::new(0.5);
$nv = Math::Float128::new(-22.5);

if($pv == $nv) {print "ok 8\n"}
else {
  warn "\$pv: $pv\n\$nv: $nv\n";
  print "not ok 8\n";
}

$pv_copy1 = $pv;

if($pv == $pv_copy1) {print "ok 9\n"}
else {
  warn "\$pv: $pv\n\$pv_copy1: $pv_copy1\n";
  print "not ok 9\n";
}

$pv_copy2 = Math::Float128::new($pv);

if($pv == $pv_copy2) {print "ok 10\n"}
else {
  warn "\$pv: $pv\n\$pv_copy2: $pv_copy2\n";
  print "not ok 10\n";
}

$uv = new Math::Float128(~0);
if($uv == UVtoF128(~0)) {print "ok 11\n"}
else {
  warn "New: $uv\nUVtoF128: ", UVtoF128(~0), "\n";
  print "not ok 11\n";
}

$iv = new Math::Float128(-23);
$pv = new Math::Float128('-23');

if($pv == $iv){print "ok 12\n"}
else {
  warn "\$pv: $pv\n\$iv: $iv\n";
  print "not ok 12\n";
}

$pv += new Math::Float128(0.5);
$nv =  new Math::Float128(-22.5);

if($pv == $nv) {print "ok 13\n"}
else {
  warn "\$pv: $pv\n\$nv: $nv\n";
  print "not ok 13\n";
}

$pv_copy1 = $pv;

if($pv == $pv_copy1) {print "ok 14\n"}
else {
  warn "\$pv: $pv\n\$pv_copy1: $pv_copy1\n";
  print "not ok 14\n";
}

$pv_copy2 = new Math::Float128($pv);

if($pv == $pv_copy2) {print "ok 15\n"}
else {
  warn "\$pv: $pv\n\$pv_copy2: $pv_copy2\n";
  print "not ok 15\n";
}

fromUV($pv, ~0);
if($pv == ~0) {print "ok 16\n"}
else {
  warn "\n $pv != ", ~0, "\n";
  print "not ok 16\n";
}

fromIV($pv, -123);
if($pv == -123) {print "ok 17\n"}
else {
  warn "\n $pv != -123\n";
  print "not ok 17\n";
}

fromNV($pv, -123.5);
if($pv == -123.5) {print "ok 18\n"}
else {
  warn "\n $pv != -123.5\n";
  print "not ok 18\n";
}

fromSTR($pv, "-1123.5");
if($pv == "-1123.5") {print "ok 19\n"}
else {
  warn "\n $pv != -1123.5\n";
  print "not ok 19\n";
}

fromF128($pv_copy2, $pv);
if($pv_copy2 == "-1123.5") {print "ok 20\n"}
else {
  warn "\n $pv != -1123.5\n";
  print "not ok 20\n";
}



