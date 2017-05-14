# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use GPIB::hp59306a;
$loaded = 1;
print "ok 1  Module loaded\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# The name GPIB name of the device
$device = "HP59306A";

$g = GPIB::hp59306a->new($device);
print "ok 2  Device $device opened\n";

if (!$g->devicePresent) {
    print "Device $device not present on GPIB\n";
    exit 0;
}
print "ok 3  Device $device present on GPIB.\n";

@st = $g->getState;
print "Relay state is (1..6): @st\n";

for(1..3) {
    for(1 .. 6) {
        $g->setRelay($_, 1);
        @st = $g->getState;
        print "Relay state is (1..6): @st\n" if $_ == 3;
        GPIB::msleep 00;
    }

    @st = $g->getState;
    print "Relay state is (1..6): @st\n";

    for(1 .. 6) {
        $g->setRelay($_, 0);
        @st = $g->getState;
        print "Relay state is (1..6): @st\n" if $_ == 3;
        GPIB::msleep 100;
    }
}

@st = $g->getState;
print "Relay state is (1..6): @st\n";
print "ok 4  Relays wiggled\n";



