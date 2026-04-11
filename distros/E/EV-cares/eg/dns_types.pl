#!/usr/bin/env perl
# Query all common DNS record types for a domain
# Usage: perl eg/dns_types.pl example.com
use strict;
use warnings;
use EV;
use EV::cares qw(:status :types);

my $domain = shift || 'cloudflare.com';
my $r = EV::cares->new(timeout => 5);
my $pending = 0;

my @queries = (
    [T_A,     'A'],
    [T_AAAA,  'AAAA'],
    [T_MX,    'MX'],
    [T_NS,    'NS'],
    [T_TXT,   'TXT'],
    [T_SOA,   'SOA'],
    [T_CAA,   'CAA'],
);

for my $q (@queries) {
    my ($type, $label) = @$q;
    $pending++;

    $r->search($domain, $type, sub {
        my ($status, @records) = @_;
        if ($status != ARES_SUCCESS) {
            printf "%-6s %s\n", $label, EV::cares::strerror($status);
        } elsif ($type == T_A || $type == T_AAAA || $type == T_NS) {
            printf "%-6s %s\n", $label, $_ for @records;
        } elsif ($type == T_MX) {
            printf "%-6s %d %s\n", $label, $_->{priority}, $_->{host} for @records;
        } elsif ($type == T_TXT) {
            printf "%-6s \"%s\"\n", $label, $_ for @records;
        } elsif ($type == T_SOA) {
            my $s = $records[0];
            printf "%-6s %s %s (serial %d, refresh %d, retry %d, expire %d, minttl %d)\n",
                $label, $s->{mname}, $s->{rname},
                $s->{serial}, $s->{refresh}, $s->{retry}, $s->{expire}, $s->{minttl};
        } elsif ($type == T_CAA) {
            printf "%-6s %s%s \"%s\"\n", $label,
                ($_->{critical} ? '! ' : ''), $_->{property}, $_->{value}
                for @records;
        }

        EV::break unless --$pending;
    });
}

printf "--- %s ---\n", $domain;
EV::run;
