# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/test.t'

#########################

use Test;
BEGIN { plan tests => 8, todo => [] };
use Linux::loadavg;
1 && ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

2 && ok((@a = loadavg())  == 3);
3 && ok((@a = loadavg(2)) == 2);
4 && ok((@a = loadavg(1)) == 1);
5 && ok(LOADAVG_1MIN == 0);
6 && ok(LOADAVG_5MIN == 1);
7 && ok(LOADAVG_15MIN == 2);
8 && ok(sub { foreach my $i (0..1_234_567) { loadavg()} 1});
