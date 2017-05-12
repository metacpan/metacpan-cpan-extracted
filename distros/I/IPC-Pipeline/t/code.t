#! /usr/bin/perl

# Copyright (c) 2012, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use Test::More ( 'tests' => 6 );

use strict;
use warnings;

use IPC::Pipeline;

my @pids = pipeline(
    my ( $in, $out ),
    undef,
    sub {
        my $line = readline( \*STDIN );

        chomp $line;
        print "$line\n";
        print "bar\n";

        return 127;
    },

    sub {
        while ( my $line = readline( \*STDIN ) ) {
            chomp $line;
            $line =~ s/^/meow: /;
            print "$line\n";
        }

        print "baz\n";

        return 63;
    }
);

print {$in} "foo\n";

close $in;

like( readline($out), qr/^meow: foo/, 'First line of output from CODE pipe is correct' );
like( readline($out), qr/^meow: bar/, 'Second line of output from CODE pipe is correct' );
like( readline($out), qr/^baz/,       'Third line of output from CODE pipe is correct' );

ok( !readline($out), 'Correctly at end of file' );

my @statuses = map {
    waitpid( $_, 0 );
    $? >> 8;
} @pids;

is( shift @statuses, 127, 'Status of first process is 127' );
is( shift @statuses, 63,  'Status of first process is 63' );
