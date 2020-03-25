#!/usr/bin/env perl

#
# Validate email addresses in the specified files and print
# thier statistics per domain basis.
#
# This version also checks DNS responses. You have to use
# a DNS server with cache to complete the work fast.
#
# P.S. This version expects that Net::DNS has libidn (Net::LibIDN) support.
#
# Usage: count-domains.pl FILE1 [ FILE2 FILE3 ... ]
#

use strict;
use warnings;
use open qw(:std :utf8);
use EAV::XS;
use Net::DNS ();


# prototypes
sub parse_file($);
sub check_dns($);


my %dns_cache = ();
my $dns = Net::DNS::Resolver->new();


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

            if (not exists $dns_cache{ $domain }) {
                $dns_cache{ $domain } = check_dns ($domain);
            }

            if ($dns_cache{ $domain }) {
                $stats{ $domain }++;
                next;
            }
        }

        $invalid++;
    }

    close ($fh)
        or die "close: $file: $!";
}


#
# In RFC 5321 has been said that DNS check should follow next steps:
# 1) Use MX records for domain if they exist;
# 2) If there is CNAME records use them and go to step 1;
# 3) If there is no MX records and no CNAME records try to use A/AAAA record;
# 4) If there is no A/AAAA records, then test has failed.
#
# XXX Inside of unstable networks this test might give false-positive results.
# According to RFC 5321 there is must be query repeat attempts 
# if the DNS server does not respond.
#
sub check_dns($) {
    my ($domain) = @_;


    my $reply = $dns->query($domain, "MX");

    if (! $reply) {
        return ($dns->query($domain, "A") || $dns->query($domain, "AAAA"));
    }

    for my $rr (grep { $_->type eq 'MX' } $reply->answer) {
        if ($dns->query($rr->exchange(), "A") ||
            $dns->query($rr->exchange(), "AAAA"))
        {
            return 1;
        }
    }

    for my $rr (grep { $_->type eq 'CNAME' } $reply->answer) {
        # XXX recursion
        if (check_dns ($rr->cname())) {
            return 1;
        }
    }

    return 0;
}
