use warnings;
use strict;
use Math::Complex_C::L qw(:all);

print "1..28\n";

my $eps = 1e-12;

my $c1 = MCL(5, 6);
my $c2 = MCL(3, 2);

add_cl($c2, $c2, $c1);
sub_cl($c2, $c2, $c1);

if($c2 == MCL(3, 2)) {print "ok 1\n"}
else {
  warn "\$c2: $c2\n";
  print "not ok 1\n";
}

add_c_uvl($c2, $c2, 17);
sub_c_uvl($c2, $c2, 17);

if($c2 == MCL(3, 2)) {print "ok 2\n"}
else {
  warn "\$c2: $c2\n";
  print "not ok 2\n";
}

add_c_ivl($c2, $c2, -17);
sub_c_ivl($c2, $c2, -17);

if($c2 == MCL(3, 2)) {print "ok 3\n"}
else {
  warn "\$c2: $c2\n";
  print "not ok 3\n";
}

add_c_nvl($c2, $c2, -17.5);
sub_c_nvl($c2, $c2, -17.5);

if($c2 == MCL(3, 2)) {print "ok 4\n"}
else {
  warn "\$c2: $c2\n";
  print "not ok 4\n";
}

mul_cl($c2, $c2, $c1);
div_cl($c2, $c2, $c1);

if(approx(real_cl($c2), 3, $eps) && approx(imag_cl($c2), 2, $eps)) {print "ok 5\n"}
else {
  warn "\$c2: $c2\n";
  print "not ok 5\n";
}

mul_c_uvl($c2, $c2, 17);
div_c_uvl($c2, $c2, 17);

if(approx(real_cl($c2), 3, $eps) && approx(imag_cl($c2), 2, $eps)) {print "ok 6\n"}
else {
  warn "\$c2: $c2\n";
  print "not ok 6\n";
}

mul_c_ivl($c2, $c2, -17);
div_c_ivl($c2, $c2, -17);

if(approx(real_cl($c2), 3, $eps) && approx(imag_cl($c2), 2, $eps)) {print "ok 7\n"}
else {
  warn "\$c2: $c2\n";
  print "not ok 7\n";
}

mul_c_nvl($c2, $c2, -17.5);
div_c_nvl($c2, $c2, -17.5);

if(approx(real_cl($c2), 3, $eps) && approx(imag_cl($c2), 2, $eps)) {print "ok 8\n"}
else {
  warn "\$c2: $c2\n";
  print "not ok 8\n";
}

##################################
##################################
##################################

# $c2 might not be exactly as it was - so we restore it to
# its original value.

assign_cl($c2, 3.0, 2.0);

my $c3 = $c2 + $c1;
$c3 = $c3 - $c1;

if($c3 == MCL(3, 2)) {print "ok 9\n"}
else {
  warn "\$c3: $c3\n";
  print "not ok 9\n";
}

$c3 = $c2 + 17;
$c3 = $c3 - 17;

if($c3 == MCL(3, 2)) {print "ok 10\n"}
else {
  warn "\$c3: $c3\n";
  print "not ok 10\n";
}

$c3 = $c2 + (-17);
$c3 = $c3 - (-17);

if($c3 == MCL(3, 2)) {print "ok 11\n"}
else {
  warn "\$c3: $c3\n";
  print "not ok 11\n";
}

$c3 = $c2 + (-19.25);
$c3 = $c3 - (-19.25);

if($c3 == MCL(3, 2)) {print "ok 12\n"}
else {
  warn "\$c3: $c3\n";
  print "not ok 12\n";
}

$c3 = $c2 * $c1;
$c3 = $c3 / $c1;

if(approx(real_cl($c3), 3, $eps) && approx(imag_cl($c3), 2, $eps)) {print "ok 13\n"}
else {
  warn "\$c3: $c3\n";
  print "not ok 13\n";
}

$c3 = $c2 * 17;
$c3 = $c3 / 17;

if(approx(real_cl($c3), 3, $eps) && approx(imag_cl($c3), 2, $eps)) {print "ok 14\n"}
else {
  warn "\$c3: $c3\n";
  print "not ok 14\n";
}

$c3 = $c2 * -18;
$c3 = $c3 / -18;

if(approx(real_cl($c3), 3, $eps) && approx(imag_cl($c3), 2, $eps)) {print "ok 15\n"}
else {
  warn "\$c3: $c3\n";
  print "not ok 15\n";
}

$c3 = $c2 * -217.125;
$c3 = $c3 / -217.125;

if(approx(real_cl($c3), 3, $eps) && approx(imag_cl($c3), 2, $eps)) {print "ok 16\n"}
else {
  warn "\$c3: $c3\n";
  print "not ok 16\n";
}

##################################
##################################
##################################

$c3 = $c2;

$c2 += $c1;
$c2 -= $c1;

if(approx(real_cl($c3), real_cl($c2), $eps)) {print "ok 17\n"}
else {
  warn "\$c3: $c3\n";
  print "not ok 17\n";
}

$c2 += 17;
$c2 -= 17;

if(approx(real_cl($c3), real_cl($c2), $eps)) {print "ok 18\n"}
else {
  warn "\$c3: $c3\n";
  print "not ok 18\n";
}

$c2 += (-17);
$c2 -= (-17);

if(approx(real_cl($c3), real_cl($c2), $eps)) {print "ok 19\n"}
else {
  warn "\$c3: $c3\n";
  print "not ok 19\n";
}

$c2 += (-19.25);
$c2 -= (-19.25);

if(approx(real_cl($c3), real_cl($c2), $eps)) {print "ok 20\n"}
else {
  warn "\$c3: $c3\n";
  print "not ok 20\n";
}

$c2 *= $c1;
$c2 /= $c1;

if(approx(real_cl($c3), real_cl($c2), $eps) && approx(imag_cl($c3), imag_cl($c2), $eps)) {print "ok 21\n"}
else {
  warn "\$c3: $c3\n";
  print "not ok 21\n";
}

$c2 *= 17;
$c2 /= 17;

if(approx(real_cl($c3), real_cl($c2), $eps) && approx(imag_cl($c3), imag_cl($c2), $eps)) {print "ok 22\n"}
else {
  warn "\$c3: $c3\n";
  print "not ok 22\n";
}

$c2 *= -18;
$c2 /= -18;

if(approx(real_cl($c3), real_cl($c2), $eps) && approx(imag_cl($c3), imag_cl($c2), $eps)) {print "ok 23\n"}
else {
  warn "\$c3: $c3\n";
  print "not ok 23\n";
}

$c2 *= -217.125;
$c2 /= -217.125;

if(approx(real_cl($c3), real_cl($c2), $eps) && approx(imag_cl($c3), imag_cl($c2), $eps)) {print "ok 24\n"}
else {
  warn "\$c3: $c3\n";
  print "not ok 24\n";
}

my $c = MCL(2.5, 2.5);

mul_c_pvl($c, $c, '2.5');
if($c == MCL('6.25', 6.25)) {print "ok 25\n"}
else {
  warn "\n\$C: $c\n";
  print "not ok 25\n";
}

div_c_pvl($c, $c, '2.5');
if($c == MCL('2.5', 2.5)) {print "ok 26\n"}
else {
  warn "\n\$C: $c\n";
  print "not ok 26\n";
}

add_c_pvl($c, $c, '2.5');
if($c == MCL(5, 2.5)) {print "ok 27\n"}
else {
  warn "\n\$C: $c\n";
  print "not ok 27\n";
}

sub_c_pvl($c, $c, '2.5');
if($c == MCL(2.5, 2.5)) {print "ok 28\n"}
else {
  warn "\n\$C: $c\n";
  print "not ok 28\n";
}

sub approx {
    if(($_[0] > ($_[1] - $_[2])) && ($_[0] < ($_[1] + $_[2]))) {return 1}
    return 0;
}
