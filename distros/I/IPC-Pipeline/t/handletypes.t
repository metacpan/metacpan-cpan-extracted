#! /usr/bin/perl

# Copyright (c) 2012, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use Test::More ( tests => 7 );

use strict;
use warnings;

use IPC::Pipeline;

{
    my $pids = pipeline( my ( $in, $out, $error ), [qw/echo hi/], [qw/cat/] );

    close $in;
    close $out;

    waitpid( $pids->[0], 0 );
    waitpid( $pids->[1], 0 );

    is( ref($pids), 'ARRAY', 'Calling pipeline() in scalar context returns ARRAY ref of pids' );
}

{
    open( my $test_in,  '>', '/dev/null' );
    open( my $test_out, '<', '/dev/null' );
    open( my $test_err, '<', '/dev/null' );

    my $expected = 2;

    my @pids = pipeline(
        $test_in, $test_out, $test_err,
        [ qw/perl -e/, 'print readline(STDIN) ."\n"; die' ],
        [qw/cat/]
    );

    is( @pids => $expected, "Calling pipeline() with typeglobs succeeds in creating $expected processes" );

    {
        my $expected = 'Test line';
        print {$test_in} "$expected\n";
        close $test_in;

        my $line = readline($test_out);
        chomp $line;
        is( $line => $expected, 'Reading and writing to typeglob handles passed to pipeline() succeeds' );
    }

    {
        my $expected = qr/^Died at/;
        my $line     = readline($test_err);
        chomp $line;

        like( $line => $expected, 'Reading from error typeglob handle passed to pipeline() succeeds' );
    }

    close $test_out;
    close $test_err;

    foreach my $pid (@pids) {
        waitpid( $pid, 1 );
    }
}

{
    open( my $fh_in,    '>', '/dev/null' );
    open( my $fh_out,   '<', '/dev/null' );
    open( my $fh_error, '<', '/dev/null' );

    my $expected = 2;

    my @pids = pipeline(
        fileno($fh_in), fileno($fh_out), fileno($fh_error),
        [ qw/perl -e/, 'print readline(STDIN) ."\n"; die' ],
        [qw/cat/]
    );

    is( @pids => $expected, "Calling pipeline() with file descriptors succeeds in creating $expected processes" );

    {
        my $expected = 'Test line';
        print {$fh_in} "$expected\n";
        close $fh_in;

        my $line = readline($fh_out);
        chomp $line;
        is( $line => $expected, 'Reading and writing to file descriptors passed to pipeline() succeeds' );
    }

    {
        my $expected = qr/^Died at/;
        my $line     = readline($fh_error);
        chomp $line;

        like( $line => $expected, 'Reading from error file descriptors passed to pipeline() succeeds' );
    }

    close $fh_out;
    close $fh_error;

    foreach my $pid (@pids) {
        waitpid( $pid, 1 );
    }
}
