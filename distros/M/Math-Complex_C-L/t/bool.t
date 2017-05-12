use warnings;
use strict;

use Math::Complex_C::L qw(:all);

print "1..14\n";

my $true = MCL(1,0);
my $false = MCL();

if($true) {print "ok 1\n"}
else {
  warn "\$true: $true\n";
  print "not ok 1\n";
}

unless(not $true) {print "ok 2\n"}
else {
  warn "\$true: $true\n";
  print "not ok 2\n";
}

unless(!$true) {print "ok 3\n"}
else {
  warn "\$true: $true\n";
  print "not ok 3\n";
}

unless($false) {print "ok 4\n"}
else {
  warn "\$false: $false\n";
  print "not ok 4\n";
}

if(not $false) {print "ok 5\n"}
else {
  warn "\$false: $false\n";
  print "not ok 5\n";
}

if(!$false) {print "ok 6\n"}
else {
  warn "\$false: $false\n";
  print "not ok 6\n";
}

my $nan = get_nanl();

if(is_nanl($nan)) { print "ok 7\n"}
else {
  warn "\$nan: $nan\n";
  print "not ok 7\n";
}

assign_cl($false, $nan, $nan);
assign_cl($true, 1, $nan);

if($true) {print "ok 8\n"}
else {
  warn "\$true: $true\n";
  print "not ok 8\n";
}

unless(not $true) {print "ok 9\n"}
else {
  warn "\$true: $true\n";
  print "not ok 9\n";
}

unless(!$true) {print "ok 10\n"}
else {
  warn "\$true: $true\n";
  print "not ok 10\n";
}

unless($false) {print "ok 11\n"}
else {
  warn "\$false: $false\n";
  print "not ok 11\n";
}

if(not $false) {print "ok 12\n"}
else {
  warn "\$false: $false\n";
  print "not ok 12\n";
}

if(!$false) {print "ok 13\n"}
else {
  warn "\$false: $false\n";
  print "not ok 13\n";
}

my $inf = get_infl();
if(is_infl($inf)) {print "ok 14\n"}
else {
  warn "\$inf: $inf\n";
  print "not ok 14\n";
}

