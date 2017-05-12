use warnings;
use strict;
use Math::Float128 qw(:all);

print "1..8\n";

my $unity = UnityF128(-1);

if($unity) {print "ok 1\n"}
else {print "not ok 1\n"}

if(!$unity) {print "not ok 2\n"}
else {print "ok 2\n"}

my $inf = InfF128(-1);

if($inf) {print "ok 3\n"}
else {print "not ok 3\n"}

if(!$inf) {print "not ok 4\n"}
else {print "ok 4\n"}

my $nan = NaNF128();

if(!$nan) {print "ok 5\n"}
else {print "not ok 5\n"}

if($nan) {print "not ok 6\n"}
else {print "ok 6\n"}

my $zero = ZeroF128(-1);

if(!$zero) {print "ok 7\n"}
else {print "not ok 7\n"}

if($zero) {print "not ok 8\n"}
else {print "ok 8\n"}
