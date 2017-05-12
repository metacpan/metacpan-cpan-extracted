# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };
use Device::Conrad::RelaisControl;
ok(1); # If we made it this far, we're ok.

#change port settings according to your needs
print "open serial port\n";
$c = new Device::Conrad::RelaisControl("/dev/ttyS0");
ok(2);
print "initialize card\n";
$c->init;
ok(3) if $c->getNumCards() > 0;

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

