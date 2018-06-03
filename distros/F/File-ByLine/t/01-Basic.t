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

my (@lines) = ( 'Line 1', 'Line 2', 'Line 3', );
my $lc = 0;
my @flret;

subtest dolines_inline => sub {
    my @result;
    @flret = ();

    my $lineno  = 0;
    my $linecnt = dolines {
        $lineno++;
        my $line = shift;

        push @result, $line;

        is( $line, $_, "Line $lineno - Local \$_ and \$_[0] are the same" );
      }
      "t/data/3lines.txt";

    is( \@result, \@lines,        'Read 3 line file' );
    is( $linecnt, scalar(@lines), 'Return value is proper' );
};

subtest forlines_inline => sub {
    my @result;
    @flret = ();

    my $lineno = 0;
    my $linecnt = forlines "t/data/3lines.txt", sub {
        $lineno++;
        my $line = shift;

        push @result, $line;

        is( $line, $_, "Line $lineno - Local \$_ and \$_[0] are the same" );
    };

    is( \@result, \@lines,        'Read 3 line file' );
    is( $linecnt, scalar(@lines), 'Return value is proper' );
};

sub flsub {
    $lc++;
    my $line = shift;

    is( $line, $_, "Line $lc - Local \$_ and \$_[0] are the same" );

    push @flret, $line;
    return;
}

subtest dolines_sub => sub {
    my @result;
    @flret = ();

    my $lineno = 0;
    my $linecnt = dolines \&flsub, "t/data/3lines.txt";

    is( \@flret,  \@lines,        'Read 3 line file' );
    is( $linecnt, scalar(@lines), 'Return value is proper' );
};

subtest forlines_sub => sub {
    my @result;
    @flret = ();

    my $lineno = 0;
    my $linecnt = forlines "t/data/3lines.txt", \&flsub;

    is( \@flret,  \@lines,        'Read 3 line file' );
    is( $linecnt, scalar(@lines), 'Return value is proper' );
};

subtest maplines_one_for_one => sub {
    my $lineno = 0;
    my @result = maplines {
        $lineno++;
        my $line = shift;

        is( $line, $_, "Line $lineno - Local \$_ and \$_[0] are the same" );
        return lc($line);
    }
    "t/data/3lines.txt";

    my (@lc) = map { lc } @lines;

    is( \@result, \@lc, 'Read 3 line file' );
};

subtest maplines_none_and_two => sub {
    my $lineno = 0;
    my @result = maplines {
        $lineno++;
        my $line = shift;

        is( $line, $_, "Line $lineno - Local \$_ and \$_[0] are the same" );

        if ( $line eq 'Line 1' ) { return; }
        if ( $line eq 'Line 2' ) { return $line, $line; }
        if ( $line eq 'Line 3' ) { return $line; }
    }
    "t/data/3lines.txt";

    my (@expected) = ( $lines[1], $lines[1], $lines[2] );

    is( \@result, \@expected, 'Read 3 line file' );
};

subtest greplines => sub {
    my $lineno = 0;
    my @result = greplines {
        $lineno++;
        my $line = shift;

        is( $line, $_, "Line $lineno - Local \$_ and \$_[0] are the same" );
        if ( $line eq 'Line 1' ) { return; }
        if ( $line eq 'Line 2' ) { return 1; }
        if ( $line eq 'Line 3' ) { return 1; }
    }
    "t/data/3lines.txt";

    my (@expected) = grep { $_ ne 'Line 1' } @lines;

    is( \@result, \@expected, 'Read 3 line file' );
};

subtest readlines => sub {
    my $lineno = 0;
    my (@result) = readlines('t/data/3lines.txt');

    is( \@result, \@lines, 'Read 3 line file' );
};

done_testing();

