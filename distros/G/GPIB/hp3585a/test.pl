# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use GPIB::hp3585a;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


$device = "HP3585A";
die "Edit test.pl and change name of \$device to a valid entry in /etc/pgpib.conf" if $device eq "";

$g = GPIB::hp3585a->new("HP3585A");
print "ok 2  Device $device open.\n";

if (!$g->devicePresent) {
    print "Device $device not present on GPIB\n";
    exit 0;
}
print "ok 3  Device $device present on GPIB.\n";

$g->ibtmo(GPIB->T3s);
@cap = $g->getCaption;
die "not ok 4  getCaption failed" if $g->ibsta & GPIB->ERR;

for (@cap) {
    print "    caption:   $_\n";
}
print "ok 4  getCaption\n\n";

@vals = $g->getDisplay;
die "not ok 5  getDisplay failed" if $g->ibsta & GPIB->ERR;

$n = @vals;
print "$n values.\n";
for($i=0; $i < @vals; $i+=12) {
    for($j=$i; $j<$i+12 && $j < @vals; $j++) {
        printf("%5d ", $vals[$j]);
    }
    print "\n";
}

print "ok 5  getDisplay\n\n" if $g->ibcnt == 2004;
print ("not ok 5  getDisplay returned ", $g->ibcnt, " bytes, should be 2004.\n") 
   unless $g->ibcnt == 2004;

