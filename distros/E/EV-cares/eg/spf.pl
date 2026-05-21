#!/usr/bin/env perl
# Look up SPF, DMARC, and DKIM records for a domain
# Usage: perl eg/spf.pl google.com
use strict;
use warnings;
use EV;
use EV::cares qw(:status :types);

my $domain = shift || 'google.com';
my $r = EV::cares->new(timeout => 5);
my $pending = 0;

my @lookups = (
    [$domain,               'SPF'],
    ["_dmarc.$domain",      'DMARC'],
    ["default._domainkey.$domain", 'DKIM'],
);

for my $l (@lookups) {
    my ($name, $label) = @$l;
    $pending++;
    $r->search($name, T_TXT, sub {
        my ($status, @txt) = @_;
        if ($status == ARES_SUCCESS) {
            for my $rec (@txt) {
                # SPF/DMARC are version-prefixed; DKIM records vary, print all
                next if $label eq 'SPF'   && $rec !~ /^v=spf/i;
                next if $label eq 'DMARC' && $rec !~ /^v=DMARC/i;
                printf "%-6s %s\n  %s\n", $label, $name, $rec;
            }
        } else {
            printf "%-6s %s: %s\n", $label, $name, EV::cares::strerror($status);
        }
        EV::break unless --$pending;
    });
}

EV::run;
