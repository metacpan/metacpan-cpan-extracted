use strict;
use warnings;
use Math::Complex_C::L qw(:all);

print "1..4\n";

*nnf        = \&Math::Complex_C::L::nnumflag;
*set_nnum   = \&Math::Complex_C::L::set_nnum;
*clear_nnum = \&Math::Complex_C::L::clear_nnum;

my $rop = Math::Complex_C::L->new('2eb', '6.5.8');

if($rop == Math::Complex_C::L->new(2, 6.5) && nnf() == 2) {print "ok 1\n"}
else {
  warn "\nExpected (2, 6.5), got $rop\n";
  warn "nnumflag() expected 2, got ", nnf(), "\n";
  print "not ok 1\n";
}

set_nnum(5);

if(nnf() == 5) {print "ok 2\n"}
else {
  warn "nnumflag() expected 5, got ", nnf(), "\n";
  print "not ok 2\n";
}

clear_nnum();

if(nnf() == 0) {print "ok 3\n"}
else {
  warn "nnumflag() expected 0, got ", nnf(), "\n";
  print "not ok 3\n";
}

$rop *= '-2 .5';

if($rop == Math::Complex_C::L->new(-4, -13) && nnf() == 1) {print "ok 4\n"}
else {
  warn "\nExpected (-4, -13), got $rop\n";
  warn "nnumflag() expected 1, got ", nnf(), "\n";
  print "not ok 4\n";
}
