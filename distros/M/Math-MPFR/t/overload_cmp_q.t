use strict;
use warnings;
use Math::MPFR;

eval{require Math::GMPq;};

if($@) {
  warn "\n\$\@:$@\n";
  warn "\n Skipping all tests - couldn't load Math::GMPq\n";
  print "1..1\n";
  print "ok 1\n";
  exit 0;
}

print "1..8\n";

my $nan = Math::MPFR->new();
my $fop = Math::MPFR->new('10.3');
my $qop = Math::GMPq->new('5/1');

if($nan == $qop || $nan < $qop || $nan > $qop || $nan <= $qop || $nan >= $qop) {print "not ok 1\n"}
else {print "ok 1\n"}

if($nan != $qop) {print "ok 2\n"}
else {print "not ok 2\n"}

my $undef = $nan <=> $qop;
if(!defined($undef)) {print "ok 3\n"}
else {print "not ok 3\n"}

if($fop == $qop) {print "not ok 4\n"}
else {print "ok 4\n"}

if($fop > $qop && $fop >= $qop && -$fop < $qop && -$fop <= $qop && $fop != $qop) {print "ok 5\n"}
else {print "not ok 5\n"}

my $def = $fop <=> $qop;

if($def == 1) {print "ok 6\n"}
else {print "not ok 6\n"}

$def = -$fop <=> $qop;

if($def == -1) {print "ok 7\n"}
else {print "not ok 7\n"}

$def = Math::MPFR->new(0.5) <=> Math::GMPq->new('1/2');

if($def == 0) {print "ok 8\n"}
else {print "not ok 8\n"}

