#!/usr/bin/env perl
# Recursive SPF expansion: pull v=spf1 TXT, then chase every include:
# directive transitively. Useful for understanding actual SPF reach
# and lookup-count budgets (RFC 7208 caps at 10 DNS lookups).
# Usage: perl eg/spf_chain.pl example.com
use strict;
use warnings;
use EV;
use EV::cares qw(:all);

my $domain = shift or die "usage: $0 DOMAIN\n";

my $r = EV::cares->new(timeout => 5, tries => 2);
my (%seen, @records, $pending, $lookups);
$pending = $lookups = 0;

sub chase {
    my ($name, $depth) = @_;
    return if $seen{$name}++;
    $lookups++;
    $pending++;

    $r->search($name, T_TXT, sub {
        my ($status, @txt) = @_;
        if ($status != ARES_SUCCESS) {
            push @records, [$depth, $name, '(no TXT)'];
            return EV::break unless --$pending;
            return;
        }
        my @spf = grep /^v=spf1/i, @txt;
        for my $rec (@spf) {
            push @records, [$depth, $name, $rec];
            for my $inc ($rec =~ /\binclude:(\S+)/g) {
                chase($inc, $depth + 1);
            }
            for my $red ($rec =~ /\bredirect=(\S+)/g) {
                chase($red, $depth + 1);
            }
        }
        EV::break unless --$pending;
    });
}

chase($domain, 0);
EV::run;

print "SPF chain for $domain ($lookups DNS lookups, RFC 7208 limit is 10):\n";
print "=" x 70, "\n";
for my $r (sort { $a->[0] <=> $b->[0] || $a->[1] cmp $b->[1] } @records) {
    printf "%s%s\n  %s\n", '  ' x $r->[0], $r->[1], $r->[2];
}

if ($lookups > 10) {
    printf "\n*** WARNING: %d lookups exceeds RFC 7208 limit of 10 ***\n",
        $lookups;
}
