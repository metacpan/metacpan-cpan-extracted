#!/usr/bin/perl
# Copyright (c) 2005 Jonathan T. Rockway

use Test::More tests=>3;
use File::CreationTime;

sub cleanup {
    unlink("new.file");
    unlink("new.file.time");
}

# cleanup from last time, if necessary
cleanup;

# create a file
open my $testfile, ">new.file";
print {$testfile} "hello, world\n";
close $testfile;

ok(-e "new.file", "test file creation");

# record the ctime
ok(my $ctime = creation_time("new.file"), "creation_time didn't die");

open my $timefile, ">new.file.time";
print {$timefile} "$ctime\n";
close $timefile;

# change the mtime of the file by ... 5 seconds
diag "Sleeping 5 seconds";
sleep 5;

open $testfile, ">new.file";
print {$testfile} "hello, world (again)\n";
close $testfile;

is(creation_time("new.file"), $ctime, "creation time matched between tests");

