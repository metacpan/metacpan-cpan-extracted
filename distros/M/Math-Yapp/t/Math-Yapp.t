# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Math-Yapp.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Cwd;

use Test::More tests => 2;
BEGIN { use_ok('Math::Yapp') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Jake here: Run running any tests from this module; just going to
# print the current directory to see where it is running the tests.
#
my $run_dir = getcwd();
printf("Running tests in directory <%s>\n", $run_dir);

is($run_dir, $run_dir, "Successful dummy test");
