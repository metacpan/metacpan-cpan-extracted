#!/usr/bin/perl

# Copyright (c) 2012, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Test::More ( 'tests' => 1 );

use IPC::Pipeline;

#
# The theory behind this test is to ensure that pipeline() always binds child
# stderr to a pipe, rather than doing nothing (as in versions <=0.5) when an
# undefined value is passed.  The test would fail if the inner call of
# pipeline() failed to bind stderr to a pipe before dying with 'I should not be
# captured', as the outer pipeline() call would have been able to read the error
# from its child.
#
my ($pid) = pipeline(
    my ( $in, $out, $err ),
    sub {
        my ($sub_pid) = pipeline( undef, undef, undef, sub { die('I should not be captured') } );
        waitpid( $sub_pid, 0 );
        exit 0;
    }
);

close $in;
close $out;

my $line = readline($err);

is( $line => undef, 'pipeline() always attaches subprocess stderr to a pipe' );

waitpid( $pid, 0 );
