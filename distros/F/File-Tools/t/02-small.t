#!/usr/bin/perl -w
use strict;

use File::Temp qw(tempdir);

use Test::More;
use Test::NoWarnings;
my $tests;
plan tests => 1 + $tests;
use File::Tools;

{
    my $full_path = File::Tools::catfile("a",  "b", "c");
    is File::Tools::basename($full_path), "c", "catfile and basename";
    is File::Tools::dirname($full_path), File::Tools::catfile("a", "b"), "catfile, dirname, catfile";

    BEGIN { $tests += 2; }
}

{
    my $file1 = 't/data/file1';
    my $data = File::Tools::slurp $file1;
    open (my $fh1, '<', $file1) or BAIL_OUT("Could not open '$file1' $!");
    my $expected = join "", <$fh1>;
    is $data, $expected, 'slurp of one file works';

    my $file2 = 't/data/file2';
    my $data2 = File::Tools::slurp $file1, $file2;
    open (my $fh2, '<', $file2) or BAIL_OUT("Could not open '$file2' $@");
    my $expected2 = $expected . join "", <$fh2>;
    is $data2, $expected2, 'slurp of two files works';

    my $warn;
    local $SIG{__WARN__} = sub {$warn = shift};
    my $nosuch = 't/data/nosuch';
    my $data3 = File::Tools::slurp $file1, $nosuch, $file2;
    is $data3, $expected2, 'slurp of two files (and one missing) works';
    is $warn, "Could not open '$nosuch'\n", 'warning received correctly';

    BEGIN { $tests += 4; }
}

{
    my $cwd1 = File::Tools::cwd;
    my $pushd = File::Tools::pushd("t");
    my $cwd2 = File::Tools::cwd;
    is $cwd2, "$cwd1/t", 'pushd changes to the new directory';
    is $pushd, "$cwd1/t", 'pushd returns the new directory';

    my $popd = File::Tools::popd;
    my $cwd3 = File::Tools::cwd;
    is $popd, $cwd1, 'popd returns the original directory';
    is $cwd3, $cwd1, 'popd changes to the original directory';

    BEGIN { $tests += 4; }
}

my $dir = tempdir( CLEANUP => 1 );
{
    my $new = File::Tools::catfile($dir, 'a.txt');
    File::Tools::copy($0, $new) or BAIL_OUT("Could not copy $0 to $new");
    is File::Tools::compare($0, $new), 0, 'file copied is the same';

    open (my $fh, ">>", $new) or BAIL_OUT("Cannot open '$new': $!");
    print {$fh} "\n";
    close $fh;
    is File::Tools::compare($0, $new), 1, 'file copied is the same, disregarding newline';
   
    BEGIN { $tests += 2; }
}


# copy
# date
# fileparse
# find
# move
# mail
# rmtree
