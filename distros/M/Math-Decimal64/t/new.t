use warnings;
use strict;
use Math::Decimal64 qw(:all);
use Math::BigInt;

print "1..36\n";

my ($nan,$d64, $d64_2);

#######################################

$nan = Math::Decimal64->new();
if(is_NaND64($nan)) {print "ok 1\n"}
else {
   warn "\n\$nan: $nan\n";
   print "not ok 1\n";
}

$d64 = Math::Decimal64->new(~0);
if($d64 == UVtoD64(~0)) {print "ok 2\n"}
else {
  warn "\n\$64: $d64\n";
  print "not ok 2\n";
}
undef $d64;

$d64 = Math::Decimal64->new(-5);
if($d64 == IVtoD64(-5)) {print "ok 3\n"}
else {
  warn "\n\$64: $d64\n";
  print "not ok 3\n";
}
undef $d64;

$d64 = Math::Decimal64->new('-10.75');
if($d64 == NVtoD64(-10.75)) {print "ok 4\n"}
else {
  warn "\n\$64: $d64\n";
  print "not ok 4\n";
}
undef $d64;

$d64 = Math::Decimal64->new("-10.75");
if($d64 == PVtoD64("-10.75")) {print "ok 5\n"}
else {
  warn "\n\$64: $d64\n";
  print "not ok 5\n";
}
undef $d64;

#######################################
#######################################

$nan = Math::Decimal64::new();
if(is_NaND64($nan)) {print "ok 6\n"}
else {
   warn "\n\$nan: $nan\n";
   print "not ok 6\n";
}

$d64 = Math::Decimal64::new(~0);
if($d64 == UVtoD64(~0)) {print "ok 7\n"}
else {
  warn "\n\$64: $d64\n";
  print "not ok 7\n";
}
undef $d64;

$d64 = Math::Decimal64::new(-5);
if($d64 == IVtoD64(-5)) {print "ok 8\n"}
else {
  warn "\n\$64: $d64\n";
  print "not ok 8\n";
}
undef $d64;

$d64 = Math::Decimal64::new('-10.75');
if($d64 == NVtoD64(-10.75)) {print "ok 9\n"}
else {
  warn "\n\$64: $d64\n";
  print "not ok 9\n";
}
undef $d64;

$d64 = Math::Decimal64::new("-10.75");
if($d64 == PVtoD64("-10.75")) {print "ok 10\n"}
else {
  warn "\n\$64: $d64\n";
  print "not ok 10\n";
}
undef $d64;

#######################################
#######################################

$nan = new Math::Decimal64();
if(is_NaND64($nan)) {print "ok 11\n"}
else {
   warn "\n\$nan: $nan\n";
   print "not ok 11\n";
}

$d64 = new Math::Decimal64(~0);
if($d64 == UVtoD64(~0)) {print "ok 12\n"}
else {
  warn "\n\$64: $d64\n";
  print "not ok 12\n";
}
undef $d64;

$d64 = new Math::Decimal64(-5);
if($d64 == IVtoD64(-5)) {print "ok 13\n"}
else {
  warn "\n\$64: $d64\n";
  print "not ok 13\n";
}
undef $d64;

$d64 = new Math::Decimal64('-10.75');
if($d64 == NVtoD64(-10.75)) {print "ok 14\n"}
else {
  warn "\n\$64: $d64\n";
  print "not ok 14\n";
}
undef $d64;

$d64 = new Math::Decimal64("-10.75");
if($d64 == PVtoD64("-10.75")) {print "ok 15\n"}
else {
  warn "\n\$64: $d64\n";
  print "not ok 15\n";
}

#######################################
#######################################

$d64_2 = Math::Decimal64->new($d64);
if($d64_2 == PVtoD64("-10.75")) {print "ok 16\n"}
else {
  warn "\n\$64_2: $d64_2\n";
  print "not ok 16\n";
}
undef $d64_2;

$d64_2 = Math::Decimal64::new($d64);
if($d64_2 == PVtoD64("-10.75")) {print "ok 17\n"}
else {
  warn "\n\$64_2: $d64_2\n";
  print "not ok 17\n";
}
undef $d64_2;

$d64_2 = new Math::Decimal64($d64);
if($d64_2 == PVtoD64("-10.75")) {print "ok 18\n"}
else {
  warn "\n\$64_2: $d64_2\n";
  print "not ok 18\n";
}
undef $d64_2;

#######################################
#######################################

eval {$d64_2 = Math::Decimal64->new(1,2,3);};
if($@ =~ /More than 3 arguments supplied to new\(\)/) {print "ok 19\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 19\n";
}

eval {$d64_2 = Math::Decimal64::new(1,2,3);};
if($@ =~ /expected no more than 2/) {print "ok 20\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 20\n";
}

eval {$d64_2 = new Math::Decimal64(1,2,3);};
if($@ =~ /More than 3 arguments supplied to new\(\)/) {print "ok 21\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 21\n";
}

#######################################
#######################################

eval {$d64_2 = Math::Decimal64->new(Math::BigInt->new(7));};
if($@ =~ /Bad argument given to new/) {print "ok 22\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 22\n";
}

eval {$d64_2 = Math::Decimal64::new(Math::BigInt->new(7));};
if($@ =~ /Bad argument given to new/) {print "ok 23\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 23\n";
}

eval {$d64_2 = new Math::Decimal64(Math::BigInt->new(7));};
if($@ =~ /Bad argument given to new/) {print "ok 24\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 24\n";
}

#######################################
#######################################

$d64_2 = Math::Decimal64->new(-11075, -2);
if($d64_2 == PVtoD64("-110.75")) {print "ok 25\n"}
else {
  warn "\n\$64_2: $d64_2\n";
  print "not ok 25\n";
}
undef $d64_2;

$d64_2 = Math::Decimal64::new(-11075, -2);
if($d64_2 == PVtoD64("-110.75")) {print "ok 26\n"}
else {
  warn "\n\$64_2: $d64_2\n";
  print "not ok 26\n";
}
undef $d64_2;

$d64_2 = new Math::Decimal64(-11075, -2);
if($d64_2 == PVtoD64("-110.75")) {print "ok 27\n"}
else {
  warn "\n\$64_2: $d64_2\n";
  print "not ok 27\n";
}
undef $d64_2;

#######################################
#######################################

$d64_2 = Math::Decimal64->new('-110.75');
if($d64_2 == PVtoD64("-110.75")) {print "ok 28\n"}
else {
  warn "\n\$64_2: $d64_2\n";
  print "not ok 28\n";
}
undef $d64_2;

$d64_2 = Math::Decimal64::new('-110.75');
if($d64_2 == PVtoD64("-110.75")) {print "ok 29\n"}
else {
  warn "\n\$64_2: $d64_2\n";
  print "not ok 29\n";
}
undef $d64_2;

$d64_2 = new Math::Decimal64('-110.75');
if($d64_2 == PVtoD64("-110.75")) {print "ok 30\n"}
else {
  warn "\n\$64_2: $d64_2\n";
  print "not ok 30\n";
}
undef $d64_2;

#######################################
#######################################

$d64_2 = Math::Decimal64->new('-110.75e2');
if($d64_2 == PVtoD64("-11075")) {print "ok 31\n"}
else {
  warn "\n\$64_2: $d64_2\n";
  print "not ok 31\n";
}
undef $d64_2;

$d64_2 = Math::Decimal64::new('-110.75e2');
if($d64_2 == PVtoD64("-11075")) {print "ok 32\n"}
else {
  warn "\n\$64_2: $d64_2\n";
  print "not ok 32\n";
}
undef $d64_2;

$d64_2 = new Math::Decimal64('-110.75e2');
if($d64_2 == PVtoD64("-11075")) {print "ok 33\n"}
else {
  warn "\n\$64_2: $d64_2\n";
  print "not ok 33\n";
}
undef $d64_2;

#######################################
#######################################

eval {$d64_2 = Math::Decimal64->new(2.5);};

if($@ =~ /new\(\) cannot be used to assign an NV/) {print "ok 34\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 34\n";
}

eval {$d64_2 = Math::Decimal64::new(2.5);};

if($@ =~ /new\(\) cannot be used to assign an NV/) {print "ok 35\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 35\n";
}

eval {$d64_2 = new Math::Decimal64(2.5);};

if($@ =~ /new\(\) cannot be used to assign an NV/) {print "ok 36\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 36\n";
}


