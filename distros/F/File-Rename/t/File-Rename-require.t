# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl File-Rename.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { require_ok('File::Rename') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# require File::Rename should not include File::Rename::Options
my $ok = !eval { local @ARGV = (1); File::Rename::Options::GetOptions(); 1 };
ok($ok, 'not imported File::Rename::Options::GetOptions' );

# eval will fail if rename is CORE::rename
my $eval = eval q{ rename [1], 1, 1; 1; };
# require File::Rename does not import rename
ok(!$eval, 'not imported rename()');
