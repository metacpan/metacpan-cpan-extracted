#!/usr/bin/perl
#
# Verify that the checksum operation is repeatable. This could theoretically
# fail, for example, when reading the message from a pipe. The two strategies
# for repeatability are (1) caching the message data, or (2) seeking back to
# the start of the input stream. The latter is much preferred if messages are
# large relative to physical memory; the former is quicker for small messages.

use strict;
use warnings;
use Email::Fingerprint;

use File::Slurp qw( read_file );

use Test::More;

# Options for the test.
my %options = (
    checksum        => 'unpack',
    strict_checking => 1,
);

my $n = 1;

for my $file ( glob "t/data/*.txt" ) {

    # Read the message into a string
    my $email = read_file($file);
    my @lines = read_file($file);

    # Get an open filehandle to the message
    open INPUT, "<", $file;

    # Checksum using the filehandle
    {
        my $fp = new Email::Fingerprint({ input => \*INPUT, %options });
        my $result = $fp->checksum;

        # Verify that repeated calls return the same result
        for my $m (1..3) {
            ok $result eq $fp->checksum, "Message $n, attempt $m"
        }

        # Again, this time changing the input within the checksum call
        for my $m (1..3) {
            ok $result eq $fp->checksum({ input => $email, %options }),
                "Message $n, string $m";
            ok $result eq $fp->checksum({ input => \@lines, %options }),
                "Message $n, array $m";
        }

        $n++;
    }

    # Done with this message
    close INPUT;
}

# That's all, folks!
done_testing();
