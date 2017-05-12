
###############################################
# When $rop and $op are NOT the same variable #
###############################################

use strict;
use warnings;
use Math::GMPq qw(:mpq);

eval {require Math::GMPz};

if($@) {
  print "1..1\n";
  warn "\$\@: $@";
  print "ok 1\n";
  warn "Skipping tests - Couldn't load Math::GMPz\n";
  exit 0;
}

print "1..15\n";

print "# Using gmp version ", Math::GMPq::gmp_v(), "\n";

my $rop = Math::GMPq->new();

Rmpq_add_z($rop, Math::GMPq->new("18/5"), Math::GMPz->new(17));

if($rop == Math::GMPq->new("103/5")) {print "ok 1\n"}
else {
  warn "\n Expected 103/5, got $rop\n";
  print "not ok 1\n";
}

Rmpq_add_z($rop, Math::GMPq->new("18/5"), Math::GMPz->new(-17));

if($rop == Math::GMPq->new("-67/5")) {print "ok 2\n"}
else {
  warn "\n Expected -67/5, got $rop\n";
  print "not ok 2\n";
}

Rmpq_sub_z($rop, Math::GMPq->new("18/5"), Math::GMPz->new(-17));

if($rop == Math::GMPq->new("103/5")) {print "ok 3\n"}
else {
  warn "\n Expected 103/5, got $rop\n";
  print "not ok 3\n";
}

Rmpq_sub_z($rop, Math::GMPq->new("18/5"), Math::GMPz->new(17));

if($rop == Math::GMPq->new("-67/5")) {print "ok 4\n"}
else {
  warn "\n Expected -67/5, got $rop\n";
  print "not ok 4\n";
}

Rmpq_z_sub($rop, Math::GMPz->new(-17), Math::GMPq->new("18/5"));

if($rop == Math::GMPq->new("-103/5")) {print "ok 5\n"}
else {
  warn "\n Expected -103/5, got $rop\n";
  print "not ok 5\n";
}

Rmpq_z_sub($rop, Math::GMPz->new(17), Math::GMPq->new("18/5"));

if($rop == Math::GMPq->new("67/5")) {print "ok 6\n"}
else {
  warn "\n Expected 67/5, got $rop\n";
  print "not ok 6\n";
}

Rmpq_mul_z($rop, Math::GMPq->new("3/7"), Math::GMPz->new(-7));
if($rop == -3) {print "ok 7\n"}
else {
  warn "\n Expected -3, got $rop\n";
  print "not ok 7\n";
}

Rmpq_mul_z($rop, Math::GMPq->new("-3/7"), Math::GMPz->new(-7));
if($rop == 3) {print "ok 8\n"}
else {
  warn "\n Expected 3, got $rop\n";
  print "not ok 8\n";
}

Rmpq_div_z($rop, Math::GMPq->new("3/7"), Math::GMPz->new(-7));
if($rop == Math::GMPq->new("-3/49")) {print "ok 9\n"}
else {
  warn "\n Expected -3/49, got $rop\n";
  print "not ok 9\n";
}

Rmpq_div_z($rop, Math::GMPq->new("-3/7"), Math::GMPz->new(-7));
if($rop == Math::GMPq->new("3/49")) {print "ok 10\n"}
else {
  warn "\n Expected 3/49, got $rop\n";
  print "not ok 10\n";
}

Rmpq_z_div($rop, Math::GMPz->new(-7), Math::GMPq->new("3/7"));
if($rop == Math::GMPq->new("-49/3")) {print "ok 11\n"}
else {
  warn "\n Expected -49/3, got $rop\n";
  print "not ok 11\n";
}

Rmpq_z_div($rop, Math::GMPz->new(-7), Math::GMPq->new("-3/7"));
if($rop == Math::GMPq->new("49/3")) {print "ok 12\n"}
else {
  warn "\n Expected 49/3, got $rop\n";
  print "not ok 12\n";
}

Rmpq_pow_ui($rop, Math::GMPq->new("-3/4"), 3);

if($rop == Math::GMPq->new("-27/64")) {print "ok 13\n"}
else {
  warn "\n Expected -27/64, got $rop\n";
  print "not ok 13\n";
}

Rmpq_z_div($rop, Math::GMPz->new(0), Math::GMPq->new('1/3'));

if($rop == 0) {print "ok 14\n"}
else {
  warn "\n Expected 0, got $rop\n";
  print "not ok 14\n";
}

Rmpq_div_z($rop, Math::GMPq->new(0), Math::GMPz->new(-11));

if($rop == 0) {print "ok 15\n"}
else {
  warn "\n Expected 0, got $rop\n";
  print "not ok 15\n";
}


