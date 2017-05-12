#! perl

use strict;
use warnings;

use Test::More 0.88 tests => 18;
use File::Touch;

my $testfilename = 't/example-file.txt';
my $new_atime    = 1399242863;
my $new_mtime    = 1399156463;

if (-f $testfilename) {
    unlink($testfilename)
    || BAIL_OUT("test file ($testfilename) already exists and I can't delete it: $!");
}

foreach my $set_atime ( 0 .. 1 ) {
    foreach my $set_mtime ( 0 .. 1 ) {
        next unless $set_mtime || $set_atime;

        my %args;
        my $toucher;

        open(my $fh, '>', $testfilename)
            || BAIL_OUT("can't create test file [set_atime=$set_atime set_mtime=$set_mtime]");
        print $fh "set_atime=$set_atime set_mtime=$set_mtime\n";
        close($fh);

        my ($original_atime, $original_mtime) = (stat($testfilename))[8,9];

        ok($original_atime > $new_atime && $original_mtime > $new_mtime,
           "atime & mtime on the new file should be in the future compared to when I wrote this test");

        if ($set_mtime) {
            $args{mtime} = $new_mtime;
        }
        else {
            $args{atime_only} = 1;
        }

        if ($set_atime) {
            $args{atime} = $new_atime;
        }
        else {
            $args{mtime_only} = 1;
        }

        $toucher = File::Touch->new(%args);
        ok(defined($toucher), "We should get an instance of File::Touch");

        ok($toucher->touch($testfilename) == 1, "touch() should say that it updated 1 file");

        my ($updated_atime, $updated_mtime) = (stat($testfilename))[8,9];

        if ($set_mtime) {
            ok($updated_mtime == $new_mtime,
               "stat() should return a changed mtime");
        }
        else {
            ok($updated_mtime == $original_mtime,
               "stat() should return the same mtime as when the file was created");
        }

        if ($set_atime) {
            ok($updated_atime == $new_atime,
               "stat() should return a changed atime");
        }
        else {
            ok($updated_atime == $original_atime,
               "stat() should return the same atime as when the file was created");
        }

        ok(unlink($testfilename), "delete the file after running the test");

    }
}
