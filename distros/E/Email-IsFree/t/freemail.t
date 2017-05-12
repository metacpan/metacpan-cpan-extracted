# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 5 };
use Email::IsFree;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(Email::IsFree::by_domain('hotmail.com'),1);
ok(Email::IsFree::by_email('foo@hotmail.com'),1);
ok(Email::IsFree::by_domain('aol.com'),0);
ok(Email::IsFree::by_email('bar@aol.com'),0);
