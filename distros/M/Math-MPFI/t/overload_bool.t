use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

print "1..9\n";

my $op = Math::MPFI->new();

unless($op) {print "ok 1\n"}
else {print "not ok 1\n"}

if(!$op) {print "ok 2\n"}
else {print "not ok 2\n"}

if(not $op) {print "ok 3\n"}
else {print "not ok 3\n"}

Rmpfi_set_ui($op, 0);

unless($op) {print "ok 4\n"}
else {print "not ok 4\n"}

if(!$op) {print "ok 5\n"}
else {print "not ok 5\n"}

if(not $op) {print "ok 6\n"}
else {print "not ok 6\n"}

Rmpfi_set_ui($op, 1);

if($op) {print "ok 7\n"}
else {print "not ok 7\n"}

if(!$op) {print "not ok 8\n"}
else {print "ok 8\n"}

if(not $op) {print "not ok 9\n"}
else {print "ok 9\n"}
