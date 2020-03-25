#!/usr/bin/env perl

# Usage: email-info.pl EMAIL_1 [EMAIL_2, EMAIL_n ...]
# 
# Print additional information about an email address:
# * contains IPv4 / IPv6 / domain?
# * local-part
# * domain-part

use strict;
use warnings;
use EAV::XS;


# simplify usage of print()
local $\ = ($^O eq 'MSWin32') ? "\r\n" : "\n";


if (@ARGV == 0) {
    print "Usage: email-info.pl EMAIL_1 [EMAIL_2, EMAIL_n ...]";
    exit 0;
}

my $eav = EAV::XS->new();
my $fmt = "  %-18s : %s\n";

for (my $i = 0, my $total = @ARGV; $i < $total; $i++) {
    my $email = $ARGV[$i];
    my $valid = $eav->is_email ($email);

    print "${email}";
    printf $fmt, "Is valid email?", $valid ? "TRUE" : "FALSE";
    printf $fmt, "Local-part", $eav->get_lpart () || "<EMPTY>";
    printf $fmt, "Domain-part", $eav->get_domain () || "<EMPTY>";
    printf $fmt, "Is IPv4?", $eav->get_is_ipv4 () ? "TRUE" : "FALSE";
    printf $fmt, "Is IPv6?", $eav->get_is_ipv6 () ? "TRUE" : "FALSE";
    printf $fmt, "Is domain?", $eav->get_is_domain () ? "TRUE" : "FALSE";
    print "-" x 72;
}
