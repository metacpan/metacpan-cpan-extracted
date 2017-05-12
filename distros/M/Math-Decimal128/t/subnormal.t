##!perl  -l
use strict;
use warnings;
use Math::Decimal128 qw(:all);

print "1..11\n";

my $str = '5' x16; # 5555555555555555
my $str_copy = $str;

if(MEtoD128($str, -6177) == MEtoD128( ('5' x 14) . 6, -6176)) {print "ok 1\n"}
else {
  warn "\n          $str\n Got      ", MEtoD128($str, -6177), "\n Expected 555555555555556e-6176\n";
  print "not ok 1\n";
}

substr($str, -2, 1, '4'); # 5555555555555545

if(MEtoD128($str, -6177) == MEtoD128( ('5' x 14) . 4, -6176)) {print "ok 2\n"}
else {
  warn "\n          $str\n Got      ", MEtoD128($str, -6177), "\n Expected 555555555555556e-61765\n";
  print "not ok 2\n";
}

substr($str, -2, 2, '54'); # 5555555555555554

if(MEtoD128($str, -6177) == MEtoD128( ('5' x 14) . 5, -6176)) {print "ok 3\n"}
else {
  warn "\n          $str\n Got      ", MEtoD128($str, -6177), "\n Expected 555555555555555e-6176\n";
  print "not ok 3\n";
}

$str = $str_copy;  # 5555555555555555

if(MEtoD128($str, -6178) == MEtoD128( ('5' x 13) . 6, -6176)) {print "ok 4\n"}
else {
  warn "\n          $str\n Got      ", MEtoD128($str, -400), "\n Expected 55555555555556e-6176\n";
  print "not ok 4\n";
}

substr($str, -3, 1, '4');  # 5555555555555455

if(MEtoD128($str, -6178) == MEtoD128( ('5' x 13) . 5, -6176)) {print "ok 5\n"}
else {
  warn "\n          $str\n Got      ", MEtoD128($str, -6178), "\n Expected 55555555555554e-6176\n";
  print "not ok 5\n";
}

substr($str, -3, 2, '54');  # 5555555555555545

if(MEtoD128($str, -6178) == MEtoD128( ('5' x 13) . 5, -6176)) {print "ok 6\n"}
else {
  warn "\n          $str\n Got      ", MEtoD128($str, -6178), "\n Expected 55555555555555e-6176\n";
  print "not ok 6\n";
}

$str = '55' . ('0' x 14);

if(MEtoD128($str, -6191) == MEtoD128( '6', -6176)) {print "ok 7\n"}
else {
  warn "\n          $str\n Got      ", MEtoD128($str, -6191), "\n Expected 6e-6176\n";
  print "not ok 7\n";
}

$str = '45' . ('0' x 14);

if(MEtoD128($str, -6191) == MEtoD128( '4', -6176)) {print "ok 8\n"}
else {
  warn "\n          $str\n Got      ", MEtoD128($str, -6191), "\n Expected 4e-6176\n";
  print "not ok 8\n";
}

$str = '55' . ('0' x 14);

if(MEtoD128($str, -6192) == MEtoD128( '1', -6176)) {print "ok 9\n"}
else {
  warn "\n          $str\n Got      ", MEtoD128($str, -6192), "\n Expected 1e-6176\n";
  print "not ok 9\n";
}

$str = '49' . ('0' x 14);

if(MEtoD128($str, -6192) == MEtoD128( '0', -6176)) {print "ok 10\n"}
else {
  warn "\n          $str\n Got      ", MEtoD128($str, -6192), "\n Expected 0\n";
  print "not ok 10\n";
}

$str = '54' . ('9' x 14);

if(MEtoD128($str, -6191) == MEtoD128( '5', -6176)) {print "ok 11\n"}
else {
  warn "\n          $str\n Got      ", MEtoD128($str, -6191), "\n Expected 5e-6176\n";
  print "not ok 11\n";
}
