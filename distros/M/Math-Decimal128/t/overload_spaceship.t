use warnings;
use strict;
use Math::Decimal128 qw(:all);

print "1..7\n";

my $nan = NaND128();
my $ninf = InfD128(-1);
my $pinf = InfD128(1);
my $zero = ZeroD128(-1);
my $none = UnityD128(-1);
my $pone = UnityD128(1);

if(!defined($nan <=> $ninf) && !defined($nan <=> $pinf)) {print "ok 1\n"}
else {print "not ok 1\n"}

if(($pinf <=> $ninf) > 0) {print "ok 2\n"}
else {print "not ok 2\n"}

if(($ninf <=> $pinf) < 0) {print "ok 3\n"}
else {print "not ok 3\n"}

if(($ninf <=> $none) < 0) {print "ok 4\n"}
else {print "not ok 4\n"}

if(($none <=> $ninf) > 0) {print "ok 5\n"}
else {print "not ok 5\n"}

unless($zero <=> ZeroD128(1)) {print "ok 6\n"}
else {print "not ok 6\n"}

unless(($pone + $none) <=> $zero) {print "ok 7\n"}
else {print "not ok 7\n"}


