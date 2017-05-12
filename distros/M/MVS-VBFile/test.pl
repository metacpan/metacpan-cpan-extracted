# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

################## We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use MVS::VBFile qw(:all);
$loaded = 1;
print "ok 1\n";

################## End of black magic.

$failed = 0;

#--- Test scalar call (no BDW's).
print "vbget............";
open(VB, "./mvsvb1.txt") or die "Could not open: $!";
while ($r = vbget(*VB)) {
   $n++;
   $rec1 = $r  if $n == 1;
}
was_it_ok(2, $n == 3 && substr($rec1,0,4) eq "\xC2\x85\x88\x96");
close VB;

#--- Test array call (no BDW's).
open(VB, "./mvsvb1.txt") or die "Could not open: $!";
$n = 0;
@aa = vbget(*VB);
was_it_ok(3, @aa == 3 && substr($aa[2],0,4) eq "\x60\x60\xC9\x40");
close VB;


#--- Test scalar call (with BDW's).
$MVS::VBFile::bdws = 1;
open(VB, "./mvsvb2.txt") or die "Could not open: $!";
while ($r = vbget(*VB)) {
   $n++;
   $rec1 = $r  if $n == 1;
   $rec20 = $r if $n == 20;
}
was_it_ok(4, $n == 20 && substr($rec1,0,4) eq "\xC2\x93\x85\xA2"
     && substr($rec20,0,4) eq "\x40\x40\xE3\x88");
close VB;

#--- Test array call (with BDW's).
open(VB, "./mvsvb2.txt") or die "Could not open: $!";
$n = 0;
@aa = vbget(*VB);
was_it_ok(5, @aa == 20 && substr($aa[0],0,4) eq "\xC2\x93\x85\xA2"
     && substr($aa[19],0,4) eq "\x40\x40\xE3\x88");
close VB;


#--- Test scalar call with keep_rdw.
$MVS::VBFile::bdws = 0;
$MVS::VBFile::keep_rdw = 1;
open(VB, "./mvsvb1.txt") or die "Could not open: $!";
while ($r = vbget(*VB)) {
   $n++;
   $rec1 = $r  if $n == 1;
}
was_it_ok(6, $n == 3 && substr($rec1,0,5) eq "\x00\x2D\x00\x00\xC2");
close VB;

#--- Test array call with keep_rdw.
open(VB, "./mvsvb1.txt") or die "Could not open: $!";
$n = 0;
@aa = vbget(*VB);
was_it_ok(7, @aa == 3 && substr($aa[2],0,5) eq "\x00\x14\x00\x00\x60");
close VB;


#--- Test VB output.
print "vbput............";
$outfi = "vbOUT01";
vbopen(*VBO, ">$outfi", 2048);
for (1..400) {
   vbput(*VBO, "vbput test record no. $_\n");
}
vbclose(*VBO);
$b = vb_blocks_written(*VBO);
open(VBO, $outfi) or die "Whoa! What happened";
read(VBO, $bdw, 4);
close(VBO);
was_it_ok(8, $b == 6 && $bdw eq "\x07\xE9\x00\x00");

unlink($outfi);


if ($failed == 0) { print "All tests successful.\n"; }
else {
   $tt = ($failed == 1) ? "1 test" : "$failed tests";
   print "$tt failed!  There is no joy in Mudville.\n";
}

sub was_it_ok {
 my ($num, $test) = @_;
 if ($test) { print "ok $num\n"; }
 else       { print "not ok $num\n"; $failed++; }
}
