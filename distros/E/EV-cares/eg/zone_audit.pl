#!/usr/bin/env perl
# Audit a domain's DNS zone for common configuration issues:
# NS / SOA / DNSKEY / DS / CAA / MX / SPF / DMARC
# Usage: perl eg/zone_audit.pl example.com
use strict;
use warnings;
use EV;
use EV::cares qw(:all);

my $domain = shift or die "usage: $0 DOMAIN\n";
my $r = EV::cares->new(timeout => 5, tries => 2);

my $pending = 0;
my %out;

sub query {
    my ($key, $name, $type) = @_;
    $pending++;
    $r->search($name, $type, sub {
        my ($status, @rrs) = @_;
        $out{$key} = { status => $status, records => \@rrs };
        EV::break unless --$pending;
    });
}

query 'NS',    $domain, T_NS;
query 'SOA',   $domain, T_SOA;
query 'CAA',   $domain, T_CAA;
query 'MX',    $domain, T_MX;
query 'TXT',   $domain, T_TXT;
query 'DMARC', "_dmarc.$domain",   T_TXT;
query 'STS',   "_mta-sts.$domain", T_TXT;

EV::run;

print "=" x 60, "\n";
printf "Zone audit for %s\n", $domain;
print "=" x 60, "\n";

# NS check
my $ns = $out{NS}{records} || [];
if ($out{NS}{status} == ARES_SUCCESS && @$ns) {
    print "NS  (@{[scalar @$ns]} servers)\n";
    print "  $_\n" for sort @$ns;
} else {
    print "NS  MISSING\n";
}

# SOA + cross-check mname against NS set
if ($out{SOA}{status} == ARES_SUCCESS && @{$out{SOA}{records}}) {
    my $soa = $out{SOA}{records}[0];
    printf "SOA primary=%s admin=%s serial=%d\n",
        $soa->{mname}, $soa->{rname}, $soa->{serial};
    my %ns_set = map { lc($_) => 1 } @$ns;
    print "  ! SOA mname '$soa->{mname}' not in NS set\n"
        unless $ns_set{lc $soa->{mname}};
} else {
    print "SOA MISSING\n";
}

# MX
my $mx = $out{MX}{records} || [];
if ($out{MX}{status} == ARES_SUCCESS && @$mx) {
    print "MX  (@{[scalar @$mx]} hosts)\n";
    for (sort { $a->{priority} <=> $b->{priority} } @$mx) {
        printf "  %d %s\n", $_->{priority}, $_->{host};
    }
} else {
    print "MX  none (domain does not receive mail)\n";
}

# Email auth
my @spf = grep /^v=spf1/i, @{$out{TXT}{records} || []};
print "SPF ", @spf ? $spf[0] : "MISSING\n";
print "\n" if @spf;

my @dmarc = grep /^v=DMARC1/i, @{$out{DMARC}{records} || []};
print "DMARC ", @dmarc ? $dmarc[0] : "MISSING";
print "\n";

my @sts = grep /^v=STSv1/i, @{$out{STS}{records} || []};
print "MTA-STS ", @sts ? $sts[0] : "not configured";
print "\n";

# CAA
my $caa = $out{CAA}{records} || [];
if (@$caa) {
    print "CAA (@{[scalar @$caa]})\n";
    for (@$caa) {
        printf "  %s%s %s\n",
            $_->{critical} ? '!' : '', $_->{property}, $_->{value};
    }
} else {
    print "CAA not set (any CA may issue)\n";
}
