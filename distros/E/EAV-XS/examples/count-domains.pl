#!/usr/bin/env perl

#
# Validate email addresses in the specified files and print
# thier statistics per domain basis.
#
# Usage: count-domains.pl FILE1 [ FILE2 FILE3 ... ]
#

use strict;
use warnings;
use open qw(:std :utf8);
use EAV::XS;


# prototypes
sub parse_file($);


# stats storage
my %stats;
my $invalid;

my $eav = EAV::XS->new()
    or die "Failed to create object of EAV::XS";

# simplify usage of print()
local $\ = ($^O eq 'MSWin32') ? "\r\n" : "\n";

for my $file (@ARGV) {
    %stats = ();
    $invalid = 0;

    parse_file ($file);

    # print stats
    print "-" x 72;
    print $file;
    print "-" x 72;

    for my $domain (sort keys %stats) {
        print $domain . " " . $stats{ $domain };
    }

    print "INVALID " . $invalid;

}

exit 0;


#
# parse_file: parse the file and count statistics for each email.
#
# Return value: none.
#
sub parse_file($) {
    my ($file) = @_;


    open (my $fh, "<", $file)
        or die "open: $file: $!";

    my $domain = "";

    while (my $email = <$fh>) {
        $email =~ s/^\s+//; # WSPs are not allowed in the begining
        $email =~ s/\s+$//; # WSPs are not allowed in the end

        if ($eav->is_email ($email)) {
            $domain = substr $email, rindex ($email, "@") + 1;
            $stats{ $domain }++;
        } else {
            $invalid++;
        }
    }

    close ($fh)
        or die "close: $file: $!";
}
