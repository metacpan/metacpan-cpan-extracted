#!/usr/bin/perl -T
# Yes, we want to make sure things work in taint mode

#
# Copyright (C) 2018 Joelle Maslak
# All Rights Reserved - See License
#

use strict;
use warnings;
use autodie;

use v5.10;

use Carp;

use Test2::V0;

use File::ByLine;
use File::Temp;

my (@lines) = ( 'Line 1', 'Line 2', 'Line 3', );

my $extended = 0;

subtest file_test => sub {
    my $dir = File::Temp->newdir();

    appendfile "$dir/foo.txt", @lines;

    my @written = readlines "$dir/foo.txt";
    is( \@written, \@lines, "Written file has the right number of lines" );

    open my $fh, "$dir/foo.txt";
    my $num = 0;
    while (my $line = <$fh>) {
        $num++;
        ok( ($line =~ m/\n$/s), "Line $num has trailing newline" );
    }
    close $fh;

    appendfile "$dir/foo.txt", reverse @lines;

    @written = readlines "$dir/foo.txt";
    is( \@written, [ @lines, reverse @lines ], "Appended file has the right number of lines" );
};

subtest multi_args => sub {
    my $dir = File::Temp->newdir();

    appendfile "$dir/baz.txt", 'Line 1', 'Line 2', 'Line 3';

    my @written = readlines "$dir/baz.txt";
    is( \@written, \@lines, "Written file has the right number of lines" );
};

subtest newline_test => sub {
    my $dir = File::Temp->newdir();

    appendfile "$dir/bar.txt", "123\n";

    my @written = readlines "$dir/bar.txt";
    is( \@written, [ '123' ], "Written file has the right number of lines" );
};

done_testing;

