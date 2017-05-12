
use strict;
use warnings;
use Math::GMPq;

eval {require Math::GMPz;};

if($@) {
  print "1..1\n";
  warn "\$\@: $@";
  print "ok 1\n";
  warn "Skipping tests - Couldn't load Math::GMPz\n";
  exit 0;
}

print "1..11\n";

my $q = Math::GMPq->new('-1/5');
my $z = Math::GMPq->new(8);

my $rop = $q + $z;

if($rop == '39/5') {print "ok 1\n"}
else {
  warn "\n Expected 39/5, got $rop\n";
  print "not ok 1\n";
}

$rop += $z;

if($rop == '79/5') {print "ok 2\n"}
else {
  warn "\n Expected 79/5, got $rop\n";
  print "not ok 2\n";
}

$rop -= $z;

if($rop == '39/5') {print "ok 3\n"}
else {
  warn "\n Expected 39/5, got $rop\n";
  print "not ok 3\n";
}

$rop = $rop * $z;

if($rop == '312/5') {print "ok 4\n"}
else {
  warn "\n Expected 312/5, got $rop\n";
  print "not ok 4\n";
}

$rop *= $z;

if($rop == '2496/5') {print "ok 5\n"}
else {
  warn "\n Expected 2496/5, got $rop\n";
  print "not ok 4\n";
}

$rop /= $z;

if($rop == '312/5') {print "ok 6\n"}
else {
  warn "\n Expected 312/5, got $rop\n";
  print "not ok 6\n";
}

$rop = $rop / $z;

if($rop == '39/5') {print "ok 7\n"}
else {
  warn "\n Expected 39/5, got $rop\n";
  print "not ok 7\n";
}

$rop = $rop - $z;

if($rop == '-1/5') {print "ok 8\n"}
else {
  warn "\n Expected -1/5, got $rop\n";
  print "not ok 8\n";
}

$rop = $rop ** 3;

if($rop == '-1/125') {print "ok 9\n"}
else {
  warn "\n Expected -1/125, got $rop\n";
  print "not ok 9\n";
}

$rop **= 2;

if($rop == '1/15625') {print "ok 10\n"}
else {
  warn "\n Expected 1/15625, got $rop\n";
  print "not ok 10\n";
}

eval {my $xception = 2 ** Math::GMPq->new('5/1');};

if($@ =~ /^Raising a value to an mpq_t power is not allowed/) {print "ok 11\n"}
else {
  warn "\n\$\@: $@";
  print "not ok 11\n";
}
