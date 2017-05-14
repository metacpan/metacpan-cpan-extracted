# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..12\n"; }
END {print "not ok 1\n" unless $loaded;}
use GPIB qw(T1s T3s T10s);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$device = "HP33120A";       # Device for test

# Load config is not normally called by the user.  I do it
# to make test script friendly.
GPIB->loadConfig();         
die "Edit test.pl and set \$device to a valid GPIB device from\n/etc/pgpib.conf for testing." unless defined($gpib::config{$device});

@interfaces = ('GPIB::ni', 'GPIB::llp', 'GPIB::rmt', 'GPIB::hpserial');

for (@interfaces) {
    eval " use $_; ";
    print "      Successfully loaded $_\n" unless $@;
    print "      Did not load $_\n" if $@;
}
print "ok 1a Loaded interface modules\n";

$g = GPIB->new($device);
print "ok 2  Opened device\n";

die "not ok 3  Device $device not present on GPIB bus." if !$g->devicePresent;
print "ok 3  Device $device present on GPIB bus.\n";

$g->ibwrt('*IDN?');
$g->errorCheck("not ok 2  First write failed");
print "ok 4  Wrote command to device\n";

$response = $g->ibrd(1024);
$g->errorCheck("not ok 3  First read failed");
chomp $response;
print "ok 5  Read String from device: $response\n";

$reponse = $g->query('*IDN?');
$g->errorCheck("not ok 6  Query failed");
$rx = $response;
chomp $response;
print "ok 6  Query device okay: $response\n\n";

print GPIB->hexDump($rx);
print "ok 7  Hex dump of response\n\n";

$reponse = $g->ibrd(1024);
$g->printStatus;

die "not ok 8 Read timeout failed\n\n" if !($g->ibsta & GPIB->ERR);
print "ok 8  Read timeout succeeded\n\n";

$g->printStatus;
print "ok 9  Status of device descriptor\n\n";

# Too spewy
# $g->printConfig;
# print "ok 10 Configuration of device\n\n";

print "Some constants:\n";
print "    T10uS        ", GPIB->T10us, "\n";
print "    T30uS        ", GPIB->T30us, "\n";
print "    T100uS       ", GPIB->T100us, "\n";
print "    T300uS       ", GPIB->T300us, "\n";
print "    T1mS         ", GPIB->T1ms, "\n";
print "ok 11 Constants\n\n";

print "Some imported constants:\n";
print "    T1s          ", T1s,  "\n";
print "    T3s          ", T3s,  "\n";
print "    T10s         ", T10s, "\n";
print "ok 12 Constants\n\n";

print "Config hash not loaded.\n" if (!defined($gpib::config{loaded}));
GPIB->loadConfig;
print "Config hash still not loaded?\n" if (!defined($gpib::config{loaded}));
print "Config table:\n";
for (sort keys %gpib::config) {
    next if $_ eq "loaded";
    printf "    %10s: ", $_;
    if (ref($gpib::config{$_}) eq "ARRAY") {
        print "[ @{$gpib::config{$_}} ]\n";
    } else {
        print " $gpib::config{$_}\n";
    }
}

