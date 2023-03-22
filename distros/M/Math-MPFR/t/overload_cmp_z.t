use strict;
use warnings;
use Math::MPFR;

eval{require Math::GMPz;};

if($@) {
  warn "\n\$\@:$@\n";
  warn "\n Skipping all tests - couldn't load Math::GMPz\n";
  print "1..1\n";
  print "ok 1\n";
  exit 0;
}

print "1..8\n";

my $nan = Math::MPFR->new();
my $fop = Math::MPFR->new('10.3');
my $zop = Math::GMPz->new(5);

if($nan == $zop || $nan < $zop || $nan > $zop || $nan <= $zop || $nan >= $zop) {print "not ok 1\n"}
else {print "ok 1\n"}

if($nan != $zop) {print "ok 2\n"}
else {print "not ok 2\n"}

my $undef = $nan <=> $zop;
if(!defined($undef)) {print "ok 3\n"}
else {print "not ok 3\n"}

if($fop == $zop) {print "not ok 4\n"}
else {print "ok 4\n"}

if($fop > $zop && $fop >= $zop && -$fop < $zop && -$fop <= $zop && $fop != $zop) {print "ok 5\n"}
else {print "not ok 5\n"}

my $def = $fop <=> $zop;

if($def > 0) {print "ok 6\n"}
else {print "not ok 6\n"}

$def = -$fop <=> $zop;

if($def < 0) {print "ok 7\n"}
else {print "not ok 7\n"}

$def = Math::MPFR->new(2.0) <=> Math::GMPz->new(2);

if($def == 0) {print "ok 8\n"}
else {print "not ok 8\n"}

