# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Foo-Bar.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More qw(no_plan);
use File::Find::ProjectCycleMigration;
BEGIN { use_ok('File::Find::ProjectCycleMigration') };

             

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

