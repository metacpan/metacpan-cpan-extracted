# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'


######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded; print "not ok 2\n" unless ($ObjectCreated && $loaded);}
use File::Mode;
$FmodeVER = 0.05;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$Fmode = File::Mode->new();
$ObjectCreated=1;
print "ok 2\n";
if ($Fmode->VERSION == $FmodeVER) { print "ok 3\n" }
elsif ($Fmode->VERSION > $FmodeVER) { print "not ok 3 (are you trying to override a better version?)\n" }
else { print "not ok 3 (version unmatch)\n" }