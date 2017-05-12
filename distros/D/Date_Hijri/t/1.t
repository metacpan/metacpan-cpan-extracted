# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Date::Hijri') };


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(join("-", g2h(22,8,2003)) eq "23-6-1424", 'gregorian to hijri');
ok(join("-", h2g(23,6,1424)) eq "22-8-2003", 'hijri to gregorian');
