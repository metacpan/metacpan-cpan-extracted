#! /usr/bin/perl

# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use Test::More ( tests => 13 );

use strict;
use warnings;

use IPC::Pipeline;
use Symbol ();

my @commands = (
    [qw(tr aiueo uaioe)],
    [qw(cut -d : -f 2)]
);

my @pids = pipeline( my ( $in, $out, $err ), @commands );

is( ref $in  => 'GLOB', 'pipeline() opened standard input writer handle' );
is( ref $out => 'GLOB', 'pipeline() opened standard output reader handle' );
is( ref $err => 'GLOB', 'pipeline() opened standard error reader handle' );

{
    my $count    = 0;
    my $expected = scalar @commands;

    for ( my $i = 0; $i < $expected; $i++ ) {
        my $command = @{ $commands[$i] }[0];
        my $pid     = $pids[$i];

        die unless ok( $pid > 0, "pipeline() started subprocess '$command' with pid $pid" );

        $count++;
    }

    die unless is( $count => $expected, "pipeline() returned $count nonzero pids (expected $expected)" );
}

{
    my %records = (
        'foo:bar:baz'    => 'bur',
        'eins:zwei:drei' => 'zwoa',
        'one:two:three'  => 'twe'
    );

    foreach ( keys %records ) {
        ok( eval { print {$in} "$_\n"; }, "Able to write record '$_' to pipeline" );
    }

    ok(
        eval {
            close $in;
            return 1;
        },
        'Able to close pipeline input'
    );

    foreach ( keys %records ) {
        my $expected = $records{$_};

        my $line = readline($out);
        chomp($line);

        is( $line => $expected, "Wrote '$_' to pipeline, received '$line' (expected '$expected')" );
    }
}

close $out;

foreach my $pid (@pids) {
    waitpid( $pid, 0 );
}
