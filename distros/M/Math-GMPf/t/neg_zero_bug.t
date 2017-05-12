# This file so named because it tests the fixing of a bug with -0 and mpf_fits_u*_p().
# The bug was present in gmp up to (and including) version 5.1.1.

use warnings;
use strict;
use Math::GMPf qw(:mpf);

print "1..12\n";

print  "# Using gmp library version ", Math::GMPf::gmp_v(), "\n";



my($ok, $count) = (0, 6);

my @vals = (
            Math::GMPf->new(-0.99999), Math::GMPf->new(-0.50001),
            Math::GMPf->new(-0.5), Math::GMPf->new(-0.4999999),
            Math::GMPf->new(-0.000001), Math::GMPf->new(0.0),
           );

$vals[5] *= -1.0;

for my $v(@vals) {
  if(Rmpf_fits_ushort_p($v)) {$ok++}
  else {warn "$v: ", Rmpf_fits_ushort_p($v), "\n"}
}


if($ok == $count) {print "ok 1\n"}
else {
  warn "\n\$ok: $ok\n\$count: $count\n";
  print "not ok 1\n";
}

$ok = 0;

for my $v(@vals) {
  if(Rmpf_fits_uint_p($v)) {$ok++}
  else {warn "$v: ", Rmpf_fits_uint_p($v), "\n"}
}


if($ok == $count) {print "ok 2\n"}
else {
  warn "\n\$ok: $ok\n\$count: $count\n";
  print "not ok 2\n";
}

$ok = 0;

for my $v(@vals) {
  if(Rmpf_fits_ulong_p($v)) {$ok++}
  else {warn "$v: ", Rmpf_fits_ulong_p($v), "\n"}
}


if($ok == $count) {print "ok 3\n"}
else {
  warn "\n\$ok: $ok\n\$count: $count\n";
  print "not ok 3\n";
}

my $f1 = Math::GMPf->new(-1.0);

if(Rmpf_fits_ushort_p($f1)) {print "not ok 4\n"}
else {print "ok 4\n"}

if(Rmpf_fits_uint_p($f1)) {print "not ok 5\n"}
else {print "ok 5\n"}

if(Rmpf_fits_ulong_p($f1)) {print "not ok 6\n"}
else {print "ok 6\n"}

if(Rmpf_fits_sshort_p($f1)) {print "ok 7\n"}
else {print "not ok 7\n"}

if(Rmpf_fits_sint_p($f1)) {print "ok 8\n"}
else {print "not ok 8\n"}

if(Rmpf_fits_slong_p($f1)) {print "ok 9\n"}
else {print "not ok 9\n"}

$f1 += 1.7;

if(Rmpf_fits_ushort_p($f1)) {print "ok 10\n"}
else {print "not ok 10\n"}

if(Rmpf_fits_uint_p($f1)) {print "ok 11\n"}
else {print "not ok 11\n"}

if(Rmpf_fits_ulong_p($f1)) {print "ok 12\n"}
else {print "not ok 12\n"}
