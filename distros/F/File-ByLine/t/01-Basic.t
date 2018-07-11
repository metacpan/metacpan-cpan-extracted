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

my $expected_header = 'This is a header.';
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

subtest dolines_inline_with_header => sub {
    my @result;
    @flret = ();

    my $header;

    my $byline = File::ByLine->new();
    $byline->header_handler( sub { $header = $_ } );

    my $lineno  = 0;
    my $linecnt = $byline->do(
        sub {
            $lineno++;
            my $line = shift;

            push @result, $line;

            is( $line, $_, "Line $lineno - Local \$_ and \$_[0] are the same" );
        },
        "t/data/3lines-with-header.txt"
    );

    is( $header,  $expected_header,   'Read header properly' );
    is( \@result, \@lines,            'Read file with header' );
    is( $linecnt, scalar(@lines) + 1, 'Return value is proper' );
};

subtest dolines_inline_with_filename => sub {
    my @result;
    @flret = ();

    my $header;

    my $byline = File::ByLine->new();
    $byline->header_handler( sub { $header = $_ } );
    $byline->file("t/data/3lines-with-header.txt");

    my $lineno  = 0;
    my $linecnt = $byline->do(
        sub {
            $lineno++;
            my $line = shift;

            push @result, $line;

            is( $line, $_, "Line $lineno - Local \$_ and \$_[0] are the same" );
        }
    );

    is( $header,  $expected_header,   'Read header properly' );
    is( \@result, \@lines,            'Read file with header' );
    is( $linecnt, scalar(@lines) + 1, 'Return value is proper' );
};

subtest dolines_inline_with_filename_override => sub {
    my @result;
    @flret = ();

    my $header;

    my $byline = File::ByLine->new();
    $byline->file("t/data/3lines-with-header.txt");

    my $lineno  = 0;
    my $linecnt = $byline->do(
        sub {
            $lineno++;
            my $line = shift;

            push @result, $line;

            is( $line, $_, "Line $lineno - Local \$_ and \$_[0] are the same" );
        },
        "t/data/3lines.txt"
    );

    is( \@result, \@lines,        'Read file with header' );
    is( $linecnt, scalar(@lines), 'Return value is proper' );
};

subtest dolines_inline_skip_header => sub {
    my @result;
    @flret = ();

    my $byline = File::ByLine->new();
    $byline->header_skip(1);

    my $lineno  = 0;
    my $linecnt = $byline->do(
        sub {
            $lineno++;
            my $line = shift;

            push @result, $line;

            is( $line, $_, "Line $lineno - Local \$_ and \$_[0] are the same" );
        },
        "t/data/3lines-with-header.txt"
    );

    is( \@result, \@lines,            'Read file with header' );
    is( $linecnt, scalar(@lines) + 1, 'Return value is proper' );
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

subtest maplines_with_header => sub {
    my $header;
    my $lineno = 0;

    my $byline = File::ByLine->new();
    $byline->header_handler( sub { $header = shift; } );

    my @result = $byline->map(
        sub {
            $lineno++;
            my $line = shift;

            is( $line, $_, "Line $lineno - Local \$_ and \$_[0] are the same" );
            return lc($line);
        },
        "t/data/3lines-with-header.txt"
    );

    my (@lc) = map { lc } @lines;

    is( $header,  $expected_header, 'Read header properly' );
    is( \@result, \@lc,             'Read 3 line file' );
};

subtest maplines_with_filename => sub {
    my $header;
    my $lineno = 0;

    my $byline = File::ByLine->new();
    $byline->header_handler( sub { $header = shift; } );
    $byline->file("t/data/3lines-with-header.txt");

    my @result = $byline->map(
        sub {
            $lineno++;
            my $line = shift;

            is( $line, $_, "Line $lineno - Local \$_ and \$_[0] are the same" );
            return lc($line);
        }
    );

    my (@lc) = map { lc } @lines;

    is( $header,  $expected_header, 'Read header properly' );
    is( \@result, \@lc,             'Read 3 line file' );
};

subtest maplines_with_filename_override => sub {
    my $header;
    my $lineno = 0;

    my $byline = File::ByLine->new();
    $byline->file("t/data/3lines-with-header.txt");

    my @result = $byline->map(
        sub {
            $lineno++;
            my $line = shift;

            is( $line, $_, "Line $lineno - Local \$_ and \$_[0] are the same" );
            return lc($line);
        },
        "t/data/3lines.txt"
    );

    my (@lc) = map { lc } @lines;

    is( \@result, \@lc, 'Read 3 line file' );
};

subtest maplines_skip_header => sub {
    my $lineno = 0;

    my $byline = File::ByLine->new();
    $byline->header_skip(1);

    my @result = $byline->map(
        sub {
            $lineno++;
            my $line = shift;

            is( $line, $_, "Line $lineno - Local \$_ and \$_[0] are the same" );
            return lc($line);
        },
        "t/data/3lines-with-header.txt"
    );

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

subtest greplines_with_header => sub {
    my $header;
    my $lineno = 0;

    my $byline = File::ByLine->new();
    $byline->header_handler( sub { $header = shift; } );

    my @result = $byline->grep(
        sub {
            $lineno++;
            my $line = shift;

            is( $line, $_, "Line $lineno - Local \$_ and \$_[0] are the same" );
            if ( $line eq 'Line 1' ) { return; }
            if ( $line eq 'Line 2' ) { return 1; }
            if ( $line eq 'Line 3' ) { return 1; }
        },
        "t/data/3lines-with-header.txt"
    );

    my (@expected) = grep { $_ ne 'Line 1' } @lines;

    is( $header,  $expected_header, 'Read header properly' );
    is( \@result, \@expected,       'Read 3 line file' );
};

subtest greplines_with_filename => sub {
    my $header;
    my $lineno = 0;

    my $byline = File::ByLine->new();
    $byline->header_handler( sub { $header = shift; } );
    $byline->file("t/data/3lines-with-header.txt");

    my @result = $byline->grep(
        sub {
            $lineno++;
            my $line = shift;

            is( $line, $_, "Line $lineno - Local \$_ and \$_[0] are the same" );
            if ( $line eq 'Line 1' ) { return; }
            if ( $line eq 'Line 2' ) { return 1; }
            if ( $line eq 'Line 3' ) { return 1; }
        }
    );

    my (@expected) = grep { $_ ne 'Line 1' } @lines;

    is( $header,  $expected_header, 'Read header properly' );
    is( \@result, \@expected,       'Read 3 line file' );
};

subtest greplines_with_filename_override => sub {
    my $header;
    my $lineno = 0;

    my $byline = File::ByLine->new();
    $byline->file("t/data/3lines-with-header.txt");

    my @result = $byline->grep(
        sub {
            $lineno++;
            my $line = shift;

            is( $line, $_, "Line $lineno - Local \$_ and \$_[0] are the same" );
            if ( $line eq 'Line 1' ) { return; }
            if ( $line eq 'Line 2' ) { return 1; }
            if ( $line eq 'Line 3' ) { return 1; }
        },
        "t/data/3lines.txt"
    );

    my (@expected) = grep { $_ ne 'Line 1' } @lines;

    is( \@result, \@expected, 'Read 3 line file' );
};

subtest greplines_skip_header => sub {
    my $lineno = 0;

    my $byline = File::ByLine->new();
    $byline->header_skip(1);

    my @result = $byline->grep(
        sub {
            $lineno++;
            my $line = shift;

            is( $line, $_, "Line $lineno - Local \$_ and \$_[0] are the same" );
            if ( $line eq 'Line 1' ) { return; }
            if ( $line eq 'Line 2' ) { return 1; }
            if ( $line eq 'Line 3' ) { return 1; }
        },
        "t/data/3lines-with-header.txt"
    );

    my (@expected) = grep { $_ ne 'Line 1' } @lines;

    is( \@result, \@expected, 'Read 3 line file' );
};

subtest readlines => sub {
    my $lineno = 0;
    my (@result) = readlines('t/data/3lines.txt');

    is( \@result, \@lines, 'Read 3 line file' );
};

subtest readlines_object => sub {
    my $lineno = 0;

    my $byline = File::ByLine->new();

    my (@result) = $byline->lines('t/data/3lines.txt');

    is( \@result, \@lines, 'Read 3 line file' );
};

subtest readlines_object_with_filename => sub {
    my $lineno = 0;

    my $byline = File::ByLine->new();
    $byline->file("t/data/3lines.txt");

    my (@result) = $byline->lines();

    is( \@result, \@lines, 'Read 3 line file' );
};

subtest readlines_object_with_filename_override => sub {
    my $lineno = 0;

    my $byline = File::ByLine->new();
    $byline->file("t/data/3lines-with-header.txt");

    my (@result) = $byline->lines('t/data/3lines.txt');

    is( \@result, \@lines, 'Read 3 line file' );
};

subtest readlines_object_with_header_skip => sub {
    my $lineno = 0;

    my $byline = File::ByLine->new();
    $byline->file("t/data/3lines-with-header.txt");
    $byline->header_skip(1);

    my (@result) = $byline->lines();

    is( \@result, \@lines, 'Read 3 line file' );
};

subtest readlines_object_with_header_handler => sub {
    my $lineno = 0;

    my $header;
    my $byline = File::ByLine->new();
    $byline->file("t/data/3lines-with-header.txt");
    $byline->header_handler( sub { $header = $_ } );

    my (@result) = $byline->lines();

    is( \@result, \@lines,          'Read 3 line file' );
    is( $header,  $expected_header, 'Read header properly' );
};

done_testing();

