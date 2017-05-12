#!/usr/bin/perl
#
# Test the Email::Fingerprint constructor using each input method. The
# "unpack" checksum is used for convenience and speed.

use strict;
use warnings;
use Email::Fingerprint;

use Test::More;


# Options for every test.

my @results = ( 35445, 23458, 64763, 19644 );
my %opts    = (
    checksum        => 'unpack',
    strict_checking => 1,
);


# CONSTRUCTOR TESTS

for my $n ( 1..4 ) {
    my $file   = "t/data/$n.txt";
    my $result = $results[$n-1];

    # File handle
    {
        open "INPUT", "<", $file;
        my $fh = new Email::Fingerprint({ input => \*INPUT, %opts });
        ok $fh->checksum eq $result, "Filehandle constructor ($n).";
        close INPUT;
    }

    # Read the data into an array now.
    open "INPUT", "<", $file;
    my @data = <INPUT>;
    close INPUT;

    # String constructor
    {
        my $fh = new Email::Fingerprint({ input => join("", @data), %opts });
        ok $fh->checksum eq $result, "String constructor ($n).";
    }

    # Array constructor
    {
        my $fh = new Email::Fingerprint({ input => \@data, %opts });
        ok $fh->checksum eq $result, "Array constructor ($n).";
    }
}

# That's all, folks!
done_testing();
