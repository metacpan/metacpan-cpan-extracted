#!/usr/bin/perl
#
# Test Email::Fingerprint using each initializer method. The
# "unpack" checksum is used for ubiquity; other checksums are
# also tried if available.

use strict;
use warnings;
use Email::Fingerprint;

use Test::More;


# Options for every test.
my @tests = (
    {
        results => [ 35445, 23458, 64763, 19644, 24557, 16289 ],
        options => {
            checksum        => 'unpack',
            strict_checking => 1,
        },
    },
    {
        results => [ 2777, 4408, 3802, 3355, 8268, 16289 ],
        options => {
            checksum        => 'unpack',
            strict_checking => 0,
        },
    },
    {
        results => [
            '1159b52099dbc8f7776e9b75a5c1217f',
            '1e3f90ab6dea6a0f14de6064821dd3a3',
            '11871e7633c860aaea61d25b966ce4aa',
            '6f4adfaa917550bf2811fcb9b65d3ee2',
            '898e3bc36edb2d8d152d72b2ed8c5e4d',
            '077d805643d8a14c83a65d84fb92b956',
        ],
        options => {
            checksum        => 'Digest::MD5',
            strict_checking => 1,
        },
    },
);

# Initializer tests
for my $test ( @tests ) {
    SKIP: {

        # Count the tests to be run
        my @results   = @{ $test->{results} || [] };
        my $num_tests = 3 * scalar(@results);

        # Decide whether to skip the test
        my $module = $test->{options}{checksum} || "";

        if ( not $module ) {
            skip "Bad test: no checksum module specified", $num_tests;
        }
        elsif ( $module ne "unpack" ) {
            eval "use $module;";
            skip "Skipping test: module not installed: $module", $num_tests
                if $@;
        }

        # Run the test
        run_test($test);
    }
}

sub run_test {
    my $settings = shift;

    my @results = @{ $settings->{results} || [] };
    my %opts    = %{ $settings->{options} || {} };

    for my $n ( 1..@results ) {
        my $file   = "t/data/$n.txt";
        my $result = $results[$n-1];

        # File handle initializer
        {
            open "INPUT", "<", $file;
            my $fh = new Email::Fingerprint( \%opts );
            $fh->read_filehandle( \*INPUT );
            ok $fh->checksum eq $result, "Filehandle initalizer ($n).";
            close INPUT;
        }

        # Read the data into an array now.
        open "INPUT", "<", $file;
        my @data = <INPUT>;
        close INPUT;

        # String initializer
        {
            my $fh = new Email::Fingerprint( \%opts );
            $fh->read_string( join("", @data) );
            ok $fh->checksum eq $result, "String initializer ($n).";
        }

        # Arrayref initializer
        {
            my $fh = new Email::Fingerprint( \%opts );
            $fh->read_arrayref( \@data );
            ok $fh->checksum eq $result, "Array initializer ($n).";
        }
    }
}

# That's all, folks!
done_testing();
