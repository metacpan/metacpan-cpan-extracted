# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}
use GPIB;
use GPIB::hpe3631a qw(P6V P25V N25V);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$device = "HPE3631A";

$g = GPIB::hpe3631a->new($device);
print "ok 2  Device $device open.\n";

die "not ok 2  Device not presenton GPIB bus" if !$g->devicePresent;
print "ok 3  Device $device present on GPIB bus.\n";

$g->ibwrt('*CLS');

$q = $g->query('*IDN?');
$g->errorCheck("IDN query");
$q =~ s/[\r\n]//g;
print "ok 3a Device $d is a $q.\n" if $q =~ /E3631A/;
die "not ok 3a Device $d is a $q.\n" unless $q =~ /E3631A/;

$v1 = "1.234567"; $c1 = "0.123456";
$v2 = "12.3456";  $c2 = "0.23";
$v3 = "-13.567";  $c3 = "0.34";

$g->set(P6V,  $v1, $c1);
$g->errorCheck("Set P6V");
$g->set(P25V, $v2, $c2);
$g->errorCheck("Set P25V");
$g->set(N25V, $v3, $c3);
$g->errorCheck("Set N25V");
print "ok 4  Set voltages.\n";

($v,$c) = $g->get(P6V);
$g->errorCheck("Get N25V");
print "P6V  Voltage = $v, Current = $c\n";
($v,$c) = $g->get(P25V);
$g->errorCheck("Get P25V");
print "P25V Voltage = $v, Current = $c\n";
($v,$c) = $g->get(N25V);
$g->errorCheck("Get N25V");
print "N25V Voltage = $v, Current = $c\n";
print "ok 5  Get voltages.\n";

$g->output(1);
$g->errorCheck("On");
$v = $g->output;
print "      Output is $v\n";
print "ok 6  Outputs on.\n";
sleep 1;


($v,$c) = $g->measure(P6V);
$g->errorCheck("Get N25V");
printf "P6V measure Voltage = %4.6g, Current = %4.6g\n", $v, $c;
($v,$c) = $g->measure(P25V);
$g->errorCheck("Get N25V");
printf "P25V measure Voltage = %4.6g, Current = %4.6g\n", $v, $c;
($v,$c) = $g->measure(N25V);
$g->errorCheck("Get N25V");
printf "N25V measure Voltage = %4.6g, Current = %4.6g\n", $v, $c;
print "ok 6  Measure outputs.\n";

$g->track(1);
$v = $g->track;
print "      Tracking is $v.\n";

$g->track(0);
$v = $g->track;
print "      Tracking is $v.\n";

$g->output(0);
$g->errorCheck("Off");
$v = $g->output;
print "      Output is $v\n";
print "ok 7  Outputs off.\n";
sleep 1;

($v,$c) = $g->measure(P6V);
$g->errorCheck("Get N25V");
printf "P6V measure Voltage = %4.6g, Current = %4.6g\n", $v, $c;
($v,$c) = $g->measure(P25V);
$g->errorCheck("Get N25V");
printf "P25V measure Voltage = %4.6g, Current = %4.6g\n", $v, $c;
($v,$c) = $g->measure(N25V);
$g->errorCheck("Get N25V");
printf "N25V measure Voltage = %4.6g, Current = %4.6g\n", $v, $c;
print "ok 8  Measure outputs.\n";


$g->display("TEST1");
$g->errorCheck();
$r = $g->display;
print "      Display is $r.\n";
sleep 1;
$g->display("PERL IS COOL");
$g->errorCheck();
$r = $g->display;
print "      Display is $r.\n";
sleep 1;
$g->display("GPIB IS OLD");
$g->errorCheck();
$r = $g->display;
print "      Display is $r.\n";
print "ok 9 Display text on instrument\n";
sleep 2;

