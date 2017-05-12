# Just a dumb test to make sure directory timestamps are affected
# in the proper way by nodes being created and deleted within it.

use strict;
use Test;

plan tests => 32;

# Create a dummy directory
# 1
ok mkdir("testdir");

# Grab timestamp
my $m1 = (stat "testdir")[9];
# 2
ok $m1;

# Wait long enough for the the timestamp to change
# 3
ok sleep 1;
# 4
ok sleep 1;

# Try to create a node within it
# 5
ok open (TEST, ">testdir/testfile.txt");
close(TEST);

# Grab timestamp again
my $m2 = (stat "testdir")[9];
# 6
ok $m2;

# Creating a file should change the timestamp of its directory.
# 7
ok ($m2 > $m1);

# Wait some more...
# 8
ok sleep 1;
# 9
ok sleep 1;

# Try renaming the file
# 10
ok rename("testdir/testfile.txt","testdir/newfile.txt");

# Grab timestamp again
my $m3 = (stat "testdir")[9];
# 11
ok $m3;

# Renaming a file should change the timestamp of its directory.
# 12
ok ($m3 > $m2);

# Wait some more...
# 13
ok sleep 1;
# 14
ok sleep 1;

# Now wipe the file
# 15
ok unlink("testdir/newfile.txt");

# Grab timestamp again
my $m4 = (stat "testdir")[9];
# 16
ok $m4;

# Deleting a file should change the timestamp of the directory it used to be in.
# 17
ok ($m4 > $m3);

# Wait some more...
# 18
ok sleep 1;
# 19
ok sleep 1;

# Create a symlink
# 20
ok symlink("dest", "testdir/symlink");

# Grab timestamp again
my $m5 = (stat "testdir")[9];
# 21
ok $m5;

# Creating a symlink should change the timestamp of its containing directory
# 22
ok ($m5 > $m4);

# Wait some more...
# 23
ok sleep 1;
# 24
ok sleep 1;

# Try renaming the symlink
# 25
ok rename("testdir/symlink","testdir/newsymlink");

# Grab timestamp again
my $m6 = (stat "testdir")[9];
# 26
ok $m6;

# Renaming a symlink should change the timestamp of its directory.
# 27
ok ($m6 > $m5);

# Wait some more...
# 28
ok sleep 1;
# 29
ok sleep 1;

# Remove the symlink
# 30
ok unlink("testdir/newsymlink");

# Grab timestamp again
my $m7 = (stat "testdir")[9];
# 31
ok $m7;

# Renaming a symlink should change the timestamp of its directory.
# 32
ok ($m7 > $m6);

rmdir("testdir");
