#!/usr/bin/env perl
# Compare DNS answers for the same name across multiple resolvers.
# Useful for debugging GeoDNS, split-horizon, or DNS poisoning.
# Usage: perl eg/dns_compare.pl example.com [resolver1 resolver2 ...]
use strict;
use warnings;
use EV;
use EV::cares qw(:status);

my $name = shift or die "usage: $0 NAME [resolver ...]\n";
my @servers = @ARGV ? @ARGV : qw(1.1.1.1 8.8.8.8 9.9.9.9 208.67.222.222);

my %answers;
my $pending = scalar @servers;

for my $srv (@servers) {
    my $r = EV::cares->new(servers => [$srv], timeout => 3, tries => 1);
    $r->resolve($name, sub {
        my ($status, @addrs) = @_;
        $answers{$srv} = $status == ARES_SUCCESS
            ? [sort @addrs]
            : ['FAIL: ' . EV::cares::strerror($status)];
        EV::break unless --$pending;
    });
}

EV::run;

# print and look for divergence
my %seen;
for my $srv (@servers) {
    my $key = join '|', @{$answers{$srv}};
    push @{$seen{$key}}, $srv;
}

printf "%s across %d resolvers:\n", $name, scalar @servers;
for my $key (sort { @{$seen{$b}} <=> @{$seen{$a}} } keys %seen) {
    printf "\n  %-40s\n", "[" . join(', ', @{$seen{$key}}) . "]";
    print "    $_\n" for split /\|/, $key;
}

if (keys %seen > 1) {
    print "\n*** DIVERGENT *** (resolvers disagree)\n";
} else {
    print "\nconsistent across all resolvers.\n";
}
