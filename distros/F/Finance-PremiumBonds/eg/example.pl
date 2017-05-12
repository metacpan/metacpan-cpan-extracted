#!/usr/bin/perl

# $Id$
# Simple usage example for Finance::PremiumBonds

use Finance::PremiumBonds;

my $holder_number = $ARGV[0];

if (!$holder_number) {
    die "Usage: $0 holdernumber";
}

if (defined(my $won = Finance::PremiumBonds::has_won($holder_number))) 
{
    print "Looks like you " . ($won ? 'may have won' : 'have not won') . "\n";
} else {
    warn "An error occurred.";
}
