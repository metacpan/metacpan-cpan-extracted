use strict;
use warnings;

print "1..16\n";

use Math::Complex_C::L qw(:all);

my $c = MCL('2.1', 0);

if($c == '2.1') {print "ok 1\n"}
else {print "not ok 1\n"}

unless($c == '2.2') {print "ok 2\n"}
else {print "not ok 2\n"}

if($c != '2.2') {print "ok 3\n"}
else {print "not ok 3\n"}

unless($c != '2.1') {print "ok 4\n"}
else {print "not ok 4\n"}

if($c + '2.1' == MCL('4.2', 0)) {print "ok 5\n"}
else {print "not ok 5\n"}

if('2.1' - $c == MCL(0,0)) {print "ok 6\n"}
else {print "not ok 6\n"}

if('2.1' / $c == MCL(1,0)) {print "ok 7\n"}
else {print "not ok 7\n"}

$c += MCL(0, '2.1');

if($c * '2.0' == MCL('4.2', '4.2')) {print "ok 8\n"}
else {print "not ok 8\n"}

if($c / '2.1' == MCL(1, 1)) {print "ok 9\n"}
else {print "not ok 9\n"}

if($c - '2.1' == MCL(0, '2.1')) {print "ok 10\n"}
else {print "not ok 10\n"}

$c -= '2.1';
if($c == MCL(0, '2.1')) {print "ok 11\n"}
else {print "not ok 11\n"}

$c += '2.1';
if($c == MCL('2.1', '2.1')) {print "ok 12\n"}
else {print "not ok 12\n"}

$c /= '2.1';
if($c == MCL(1, 1)) {print "ok 13\n"}
else {print "not ok 13\n"}

$c *= '2.5';
if($c == MCL(2.5, 2.5)) {print "ok 14\n"}
else {print "not ok 14\n"}

if($c ** 0 == MCL(1,0)) {print "ok 15\n"}
else {
  warn "\n\$C: $c\n";
  print "not ok 15\n";
}

$c **= 0;
if($c == MCL(1,0)) {print "ok 16\n"}
else {
  warn "\n\$C: $c\n";
  print "not ok 16\n";
}

