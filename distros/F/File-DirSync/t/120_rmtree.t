# This is to test the File::DirSync->rmtree method to
# make sure it's strong enough to get rid of anything.

use strict;
use Test;
use File::DirSync;

plan tests => 10;

# 1
my $dirsync = new File::DirSync;
ok $dirsync;

# Create a dummy directory
# 2
ok mkdir("testdir", 0755);

# 3
ok open (TEST, ">testdir/testfile.txt");
close TEST;

# 4
ok $dirsync->rmtree("testdir");

# The directory should be gone
# 5
ok !-e "testdir";

# Create a dummy directory
# 6
ok mkdir("testdir", 0755);

# 7
ok open (TEST, ">testdir/testfile.txt");
close TEST;

# 8
ok chmod(0000, "testdir");

# 9
ok $dirsync->rmtree("testdir");

# The directory should be gone
# 10
ok !-e "testdir";
