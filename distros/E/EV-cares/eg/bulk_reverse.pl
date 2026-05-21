#!/usr/bin/env perl
# Bulk PTR enrichment for log lines.
# Reads lines from stdin (or a file), extracts unique IPv4/IPv6
# addresses, batch-resolves them to PTR names, and emits each
# input line with the resolved hostname appended.
#
# Usage:
#   tail -f access.log | perl eg/bulk_reverse.pl
#   perl eg/bulk_reverse.pl access.log > enriched.log
use strict;
use warnings;
use EV;
use EV::cares qw(:status);

my $r = EV::cares->new(timeout => 3, tries => 2);

# read everything first so we can batch the lookups
my @lines = <>;
my %ips;
for my $line (@lines) {
    while ($line =~ /\b(\d{1,3}(?:\.\d{1,3}){3})\b/g) { $ips{$1}++ }
    while ($line =~ /\b([0-9a-fA-F:]+:[0-9a-fA-F:]+)\b/g) {
        $ips{$1}++ if $1 =~ /:/ && $1 ne '::';
    }
}
my @ips = sort keys %ips;

unless (@ips) {
    print @lines;
    exit;
}

my %name;
$r->reverse_all(\@ips, sub {
    my ($res) = @_;
    for my $ip (keys %$res) {
        $name{$ip} = $res->{$ip}{status} == ARES_SUCCESS
            ? $res->{$ip}{hosts}[0] : undef;
    }
    EV::break;
});
EV::run;

# emit each input line with first-found IP annotated
for my $line (@lines) {
    chomp $line;
    my ($first_ip) = $line =~ /\b(\d{1,3}(?:\.\d{1,3}){3})\b/;
    if ($first_ip && $name{$first_ip}) {
        print "$line  # $first_ip = $name{$first_ip}\n";
    } else {
        print "$line\n";
    }
}

printf STDERR "resolved %d unique addresses\n", scalar @ips;
