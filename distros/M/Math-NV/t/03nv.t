use strict;
use warnings;
use Math::NV qw(:all);

print "1..5\n";

# Test with values for which perl and C will (hopefully) agree.

my $strtod = Math::NV::_has_perl_strtod();

my($nv, $iv) = nv('123.625');

if($nv == 123.625) {print "ok 1\n"}
else {
  warn "\nExpected 123.625\nGot $nv\n";
  print "not ok 1\n";
}

if($iv == 0) {print "ok 2\n"}
else {
  warn "\nExpected 0\nGot $iv\n";
  print "not ok 2\n";
}

$nv = nv('-1125e-3');

if($nv == -1.125) {print "ok 3\n"}
else {
  warn "\nExpected -1.125\nGot $nv\n";
  print "not ok 3\n";
}

$Math::NV::no_warn = 1; # disable warning about non-string arg provided to nv();

my $nv2 = nv(-1.5);

if($nv2 == -1.5) {print "ok 4\n"}
else {
  warn "\nexpecting -1.5, got $nv2\n";
  print "not ok 4\n";
}

if($strtod) {
  $nv = nv('-1125e-3');
  if($nv == set_C('-1125e-3')) {print "ok 5\n"}
  else {
    warn "\n$nv != ", set_C('-1125e-3'), "\n";
    print "not ok 5\n";
  }
}
else {
  warn "\n Skipping test 5 - Perl_strtod is not defined\n";
  print "ok 5\n";
}

$Math::NV::no_warn = 0; # re-enable warning
