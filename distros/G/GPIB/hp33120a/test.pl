# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..21\n"; }
END {print "not ok 1\n" unless $loaded;}
use GPIB;
use GPIB::hp33120a qw(SIN SQUARE TRIANGLE NOISE);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$device = "HP33120A";

$verbose = 0;
$nosleep = 1;

sub vwait {
    my $prompt = "Press Enter to proceed";
    $prompt = shift if @_;

    if ($verbose) {
        print "$prompt: ";
        <STDIN>;
    }
}

# Open the device
vwait();
$g = GPIB::hp33120a->new($device);
$g->ibtmo(GPIB->T10s);

print "ok 2  Device $device open.\n";

# Make sure a listener is on the bus at this address
vwait();
# die "not ok 2  Device not presenton GPIB bus" if !$g->devicePresent;
print "ok 3  Device $device present on GPIB bus.\n";

# Make sure device at address really is a 33120A
vwait();
$g->ibwrt('*CLS');
$g->errorCheck('CLS ');
$q = $g->query('*IDN?');
$g->errorCheck('IDN query');
$q =~ s/[\n\r]//g;
die "not ok 4  Device $d is a $q.\n" if !($q =~ /33120A/);
print "ok 4  Device $d is a $q.\n";

vwait();
$g->set(GPIB::hp33120a::SIN, 4000000.0, 1.0, 0.0);
$g->errorCheck("set command 1");
vwait();
($shape, $freq, $amp, $offset) = $g->get;
printf("      Shape is %s, freq: %g, amp: %g, offset: %g\n",
    $shape, $freq, $amp, $offset);
print "ok 5  Set 4MHz sine wave parameters.\n";
sleep 3 if !$nosleep;

vwait();
$g->set(SQUARE, 3000000.0, 1.0, 0.0);
$g->errorCheck("set command 2");
vwait();
($shape, $freq, $amp, $offset) = $g->get;
printf("      Shape is %s, freq: %g, amp: %g, offset: %g\n",
    $shape, $freq, $amp, $offset);
print "ok 6  Set 3MHz square wave parameters.\n";
sleep 3 if !$nosleep;

vwait();
$g->set(GPIB::hp33120a->RAMP, 100000.0, 2.1, 1.2);
$g->errorCheck("set command 3");
vwait();
($shape, $freq, $amp, $offset) = $g->get;
printf("      Shape is %s, freq: %g, amp: %g, offset: %g\n",
    $shape, $freq, $amp, $offset);
print "ok 7  Set 100kHz ramp wave parameters.\n";
sleep 3 if !$nosleep;

vwait();
$g->set(SQUARE, 101100.0, 3.0, 0);
$g->errorCheck("set command");
vwait();
($shape, $freq, $amp, $offset) = $g->get;
printf("      Shape is %s, freq: %g, amp: %g, offset: %g\n",
    $shape, $freq, $amp, $offset);
print "ok 8  Set 101.1kHz square wave parameters.\n";
sleep 3 if !$nosleep;

vwait();
$r = $g->ibwrt("OUTPUT:LOAD 50");
$g->errorCheck("LOAD Set ");
$r = $g->query("OUTPUT:LOAD?");
$r =~ s/[\n\r]//g;
$g->errorCheck("LOAD Query ");
printf "ok 9  Expected load is %g ohms\n", $r;

vwait("Set ARB table");
$g->ibtmo(GPIB->T30s);
@q = ();
$len = 8192;
srand(time);

# Mix noise with a local oscillator
for($i=0; $i<$len; $i++) {
    $q[$i] = int(0.5 + 1800 * (sin(2.0 * 3.14159 * $i / $len) * 
                                (0.5 + 0.5*rand())));
}

$g->arb(\@q);
$g->ibtmo(GPIB->T1s);
$g->errorCheck("arb ");

vwait("Set to source:func:user volatile");
$g->ibwrt("SOURCE:FUNC:USER VOLATILE");
$g->errorCheck("v1 ");

vwait("Set func:shape user");
$g->ibwrt("FUNC:SHAPE USER");
$g->errorCheck("v2 ");
print "ok 10 $len point arbitrary function loaded (sine*noise)\n";
sleep 4 if !$nosleep;

vwait();
$r = $g->query("DATA:ATTR:AVER?");
$r =~ s/[\n\r]//g;
printf "      Average ARB is %g\n", $r;
$r = $g->query("DATA:ATTR:CFAC?");
$r =~ s/[\n\r]//g;
printf "      CFactor ARB is %g\n", $r;
$r = $g->query("DATA:ATTR:POIN?");
$r =~ s/[\n\r]//g;
printf "      Points in  ARB is %g\n", $r;
$r = $g->query("DATA:ATTR:PTP?");
$r =~ s/[\n\r]//g;
printf "      PTP ARB is %g\n", $r;
print "ok 11 Query arb\n";

$g->set(SIN, 123456.7890123, 3.0, 0);
vwait();
for(1 .. 5) {
    $f = rand(90000.0)+10000.0;
    $g->freq($f);
    $g->errorCheck("Freq $f ");
    $f2 = $g->freq;
    $g->errorCheck("Freq2 $f ");
    printf "      Set freq to %7g, read back %7g.\n", $f, $f2;
    sleep 1 if !$nosleep;
}
print "ok 12 Freq call\n";

vwait();
for(1 .. 5) {
    $f = rand(5.0)+1.0;
    $g->amplitude($f);
    $g->errorCheck("Amp $f ");
    $f2 = $g->amplitude;
    $g->errorCheck("Amp2 $f ");
    printf "      Set amplitude to %7g, read back %7g.\n", $f, $f2;
    sleep 1 if !$nosleep;
}
print "ok 13 Amplitude call\n";

vwait();
for(1 .. 5) {
    $f = rand(4.0)-2.0;
    $g->offset($f);
    $g->errorCheck("Offset $f ");
    $f2 = $g->offset;
    $g->errorCheck("Offset2 $f ");
    printf "      Set offset to %7g, read back %7g.\n", $f, $f2;
    sleep 1 if !$nosleep;
}
print "ok 14 Offset call\n";

vwait();
for("SIN", "SQU", "TRI", "RAMP") {
    $g->shape($_);
    $g->errorCheck("Shape $_ ");
    $f2 = $g->shape;
    $g->errorCheck("Shape2 $f ");
    printf "      Set shape to %s, read back %s.\n", $_, $f2;
    sleep 1 if !$nosleep;
}
print "ok 15 Shape call\n";

vwait();
$g->display("TEST1");
$g->errorCheck();
$r = $g->display;
print "      Display is $r.\n";
sleep 1 if !$nosleep;
$g->display("PERL IS COOL");
$g->errorCheck();
$r = $g->display;
print "      Display is $r.\n";
sleep 1 if !$nosleep;
$g->display("GPIB IS OLD");
$g->errorCheck();
$r = $g->display;
print "      Display is $r.\n";
print "ok 16 Display text on instrument\n";
sleep 2 if !$nosleep;

vwait("AM");
$g->set(SIN, 1000000.0, 1.0, 0.0);
$g->errorCheck();
$g->am(80, "SIN", 10000.0);
$g->errorCheck();
print "ok 17 AM \n";
sleep 3 if !$nosleep;

vwait("FM");
$g->set(SIN, 1000000.0, 1.0, 0.0);
$g->errorCheck();
$g->fm(10000.0, "SIN", 1000.0);
$g->errorCheck();
print "ok 18 FM \n";
sleep 3 if !$nosleep;

vwait("BM");
$g->set(SIN, 1000000.0, 1.0, 0.0);
$g->errorCheck();
$g->bm(10, 0, 1000.0);
$g->errorCheck();
print "ok 19 BM \n";
sleep 3 if !$nosleep;

vwait("FSK");
$g->set(SIN, 1000000.0, 1.0, 0.0);
$g->errorCheck();
$g->fsk(2000000.0, 1.0);
$g->errorCheck();
print "ok 20 Frequency shift keying\n";
sleep 3 if !$nosleep;

vwait("Sweep");
$g->set(SIN, 1000000.0, 1.0, 0.0);
$g->errorCheck();
$g->sweep("LIN", 1000000.0, 2000000.0, 10.0);
$g->errorCheck();
print "ok 21 Sweep\n";
sleep 3 if !$nosleep;

vwait();
$g->set(SIN, 1000000.0, 1.0, 0.0);

