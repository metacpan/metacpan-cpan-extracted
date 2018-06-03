#!/usr/bin/perl
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
use Test2::Require::Module 'Parallel::WorkUnit' => 1.117;

use Fcntl;
use File::ByLine;
use File::Temp qw(tempfile);

my (@lines) = ( 'Line 1', 'Line 2', 'Line 3', );
my $lc = 0;
my @flret;

subtest parallel_dolines => sub {
    my ($fh1, $fn1) = tempfile();
    my ($fh2, $fn2) = tempfile();
    my ($fh3, $fn3) = tempfile();

    #
    # Make sure that we call the code for each line
    #

    my $linecnt = parallel_dolines {
        my $line = shift;

        if ($line eq 'Line 1') {
            print $fh1 "$line\n";
        } elsif ($line eq 'Line 2') {
            print $fh2 "$line\n";
        } elsif ($line eq 'Line 3') {
            print $fh3 "$line\n";
        }
    }
    "t/data/3lines.txt", 4;

    seek($fh1, 0, Fcntl::SEEK_SET);
    seek($fh2, 0, Fcntl::SEEK_SET);
    seek($fh3, 0, Fcntl::SEEK_SET);

    my $l1 = <$fh1>;
    my $l2 = <$fh2>;
    my $l3 = <$fh3>;

    close $fh1;
    close $fh2;
    close $fh3;

    chomp($l1);
    chomp($l2);
    chomp($l3);

    is( $l1, $lines[0], 'Line 0 correct');
    is( $l2, $lines[1], 'Line 1 correct');
    is( $l3, $lines[2], 'Line 2 correct');
    is( $linecnt, scalar(@lines), 'Return value is proper' );

    #
    # Make sure that the code only sees each line once
    #

    parallel_forlines "t/data/3lines.txt", 4, sub {
        my $line = shift;

        if ($line eq 'Line 1') {
            unlink $fn1 or die($!);
        } elsif ($line eq 'Line 2') {
            unlink $fn2 or die($!);
        } elsif ($line eq 'Line 3') {
            unlink $fn3 or die($!);
        }
    };

    ok( ! -f $fn1, "FN1 Deleted" );
    ok( ! -f $fn2, "FN2 Deleted" );
    ok( ! -f $fn3, "FN3 Deleted" );
};

subtest parallel_forlines => sub {
    my ($fh1, $fn1) = tempfile();
    my ($fh2, $fn2) = tempfile();
    my ($fh3, $fn3) = tempfile();

    #
    # Make sure that we call the code for each line
    #

    my $linecnt = parallel_forlines "t/data/3lines.txt", 4, sub {
        my $line = shift;

        if ($line eq 'Line 1') {
            print $fh1 "$line\n";
        } elsif ($line eq 'Line 2') {
            print $fh2 "$line\n";
        } elsif ($line eq 'Line 3') {
            print $fh3 "$line\n";
        }
    };

    seek($fh1, 0, Fcntl::SEEK_SET);
    seek($fh2, 0, Fcntl::SEEK_SET);
    seek($fh3, 0, Fcntl::SEEK_SET);

    my $l1 = <$fh1>;
    my $l2 = <$fh2>;
    my $l3 = <$fh3>;

    close $fh1;
    close $fh2;
    close $fh3;

    chomp($l1);
    chomp($l2);
    chomp($l3);

    is( $l1, $lines[0], 'Line 0 correct');
    is( $l2, $lines[1], 'Line 1 correct');
    is( $l3, $lines[2], 'Line 2 correct');
    is( $linecnt, scalar(@lines), 'Return value is proper' );

    #
    # Make sure that the code only sees each line once
    #

    parallel_forlines "t/data/3lines.txt", 4, sub {
        my $line = shift;

        if ($line eq 'Line 1') {
            unlink $fn1 or die($!);
        } elsif ($line eq 'Line 2') {
            unlink $fn2 or die($!);
        } elsif ($line eq 'Line 3') {
            unlink $fn3 or die($!);
        }
    };

    ok( ! -f $fn1, "FN1 Deleted" );
    ok( ! -f $fn2, "FN2 Deleted" );
    ok( ! -f $fn3, "FN3 Deleted" );
};

sub flsub {
    $lc++;
    my $line = shift;

    is( $line, $_, "Line $lc - Local \$_ and \$_[0] are the same" );

    push @flret, $line;
    return;
}

subtest parallel_maplines_one_for_one => sub {
    my @result = parallel_maplines {
        my $line = shift;
        return lc($line);
    }
    "t/data/3lines.txt", 1;

    my (@lc) = map { lc } @lines;
    is( \@result, \@lc, 'Read 3 line file, 1 process' );

    @result = parallel_maplines {
        my $line = shift;
        return lc($line);
    }
    "t/data/3lines.txt", 4;

    is( \@result, \@lc, 'Read 3 line file, 4 processes' );
};

subtest parallel_maplines_none_and_two => sub {
    my @result = parallel_maplines {
        my $line = shift;

        if ( $line eq 'Line 1' ) { return; }
        if ( $line eq 'Line 2' ) { return $line, $line; }
        if ( $line eq 'Line 3' ) { return $line; }
    }
    "t/data/3lines.txt", 1;

    my (@expected) = ( $lines[1], $lines[1], $lines[2] );

    is( \@result, \@expected, 'Read 3 line file' );
};

subtest parallel_greplines => sub {
    my @result = parallel_greplines {
        my $line = shift;

        if ( $line eq 'Line 1' ) { return; }
        if ( $line eq 'Line 2' ) { return 1; }
        if ( $line eq 'Line 3' ) { return 1; }
    }
    "t/data/3lines.txt", 1;

    my (@expected) = grep { $_ ne 'Line 1' } @lines;
    is( \@result, \@expected, 'Read 3 line file, 1 process' );

    @result = parallel_greplines {
        my $line = shift;

        if ( $line eq 'Line 1' ) { return; }
        if ( $line eq 'Line 2' ) { return 1; }
        if ( $line eq 'Line 3' ) { return 1; }
    }
    "t/data/3lines.txt", 4;

    is( \@result, \@expected, 'Read 3 line file, 4 processes' );
};

subtest parallel_greplines_large => sub {
    my @result = parallel_greplines { 1; } "t/data/longer-text.txt", 4;
    my @expected = readlines "t/data/longer-text.txt";

    is( \@result, \@expected, "Grep on non-trivial file" );
};

subtest parallel_maplines_large => sub {
    my @result = parallel_maplines { lc($_) } "t/data/longer-text.txt", 4;
    my @expected = map { lc($_) } readlines "t/data/longer-text.txt";

    is( \@result, \@expected, "Map on non-trivial file" );
};

done_testing();

