# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 5 };
use File::FnMatch;
ok(1); # If we made it this far, we are ok.

ok(defined &File::FnMatch::fnmatch);
ok(! defined &fnmatch, 1, "fnmatch not imported by default");

my @const = grep { /^FNM_/ } keys %{File::FnMatch::};
ok(@const > 0, 1, "FNM_* constants present");
ok(@const == scalar grep { defined &{"File::FnMatch::$_"} } @const, 1,
   "FNM_* constants callable");

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

