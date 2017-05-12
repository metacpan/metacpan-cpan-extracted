##!perl  -l
use strict;
use warnings;
use Math::Decimal64 qw(:all);

print "1..11\n";

my $str = '5' x16; # 5555555555555555
my $str_copy = $str;

if(MEtoD64($str, -399) == MEtoD64( ('5' x 14) . 6, -398)) {print "ok 1\n"}
else {
  warn "\n          $str\n Got      ", MEtoD64($str, -399), "\n Expected 555555555555556e-398\n";
  print "not ok 1\n";
}

substr($str, -2, 1, '4'); # 5555555555555545

if(MEtoD64($str, -399) == MEtoD64( ('5' x 14) . 4, -398)) {print "ok 2\n"}
else {
  warn "\n          $str\n Got      ", MEtoD64($str, -399), "\n Expected 555555555555556e-398\n";
  print "not ok 2\n";
}

substr($str, -2, 2, '54'); # 5555555555555554

if(MEtoD64($str, -399) == MEtoD64( ('5' x 14) . 5, -398)) {print "ok 3\n"}
else {
  warn "\n          $str\n Got      ", MEtoD64($str, -399), "\n Expected 555555555555555e-398\n";
  print "not ok 3\n";
}

$str = $str_copy;  # 5555555555555555

if(MEtoD64($str, -400) == MEtoD64( ('5' x 13) . 6, -398)) {print "ok 4\n"}
else {
  warn "\n          $str\n Got      ", MEtoD64($str, -400), "\n Expected 55555555555556e-398\n";
  print "not ok 4\n";
}

substr($str, -3, 1, '4');  # 5555555555555455

if(MEtoD64($str, -400) == MEtoD64( ('5' x 13) . 5, -398)) {print "ok 5\n"}
else {
  warn "\n          $str\n Got      ", MEtoD64($str, -400), "\n Expected 55555555555554e-398\n";
  print "not ok 5\n";
}

substr($str, -3, 2, '54');  # 5555555555555545

if(MEtoD64($str, -400) == MEtoD64( ('5' x 13) . 5, -398)) {print "ok 6\n"}
else {
  warn "\n          $str\n Got      ", MEtoD64($str, -400), "\n Expected 55555555555555e-398\n";
  print "not ok 6\n";
}

$str = '55' . ('0' x 14);

if(MEtoD64($str, -413) == MEtoD64( '6', -398)) {print "ok 7\n"}
else {
  warn "\n          $str\n Got      ", MEtoD64($str, -413), "\n Expected 6e-398\n";
  print "not ok 7\n";
}

$str = '45' . ('0' x 14);

if(MEtoD64($str, -413) == MEtoD64( '4', -398)) {print "ok 8\n"}
else {
  warn "\n          $str\n Got      ", MEtoD64($str, -413), "\n Expected 4e-398\n";
  print "not ok 8\n";
}

$str = '55' . ('0' x 14);

if(MEtoD64($str, -414) == MEtoD64( '1', -398)) {print "ok 9\n"}
else {
  warn "\n          $str\n Got      ", MEtoD64($str, -414), "\n Expected 1e-398\n";
  print "not ok 9\n";
}

$str = '49' . ('0' x 14);

if(MEtoD64($str, -414) == MEtoD64( '0', -398)) {print "ok 10\n"}
else {
  warn "\n          $str\n Got      ", MEtoD64($str, -414), "\n Expected 0\n";
  print "not ok 10\n";
}

$str = '54' . ('9' x 14);

if(MEtoD64($str, -413) == MEtoD64( '5', -398)) {print "ok 11\n"}
else {
  warn "\n          $str\n Got      ", MEtoD64($str, -413), "\n Expected 6e-398\n";
  print "not ok 11\n";
}