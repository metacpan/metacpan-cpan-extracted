#!/usr/bin/env perl
# Look up HTTPS/SVCB records (RFC 9460). Useful for ECH discovery,
# H3 hinting, and CDN steering.
# Usage: perl eg/svcb.pl [name] [HTTPS|SVCB]
use strict;
use warnings;
use EV;
use EV::cares qw(:status :types);

my $name = shift // 'cloudflare.com';
my $type = uc(shift // 'HTTPS');
my $tnum = $type eq 'SVCB' ? T_SVCB : T_HTTPS;

my $r = EV::cares->new(timeout => 5);

$r->search($name, $tnum, sub {
    my ($s, @rrs) = @_;
    if ($s != ARES_SUCCESS) {
        die "$type $name: " . EV::cares::strerror($s) . "\n";
    }
    for my $rr (@rrs) {
        unless (ref $rr eq 'HASH') {
            print "raw response: ", length($rr), " bytes\n";
            print "  (rebuild against c-ares >= 1.28 for parsed output)\n";
            next;
        }
        printf "%s priority=%d target=%s\n",
            $type, $rr->{priority}, $rr->{target} ne '' ? $rr->{target} : '.';
        my $p = $rr->{params} || {};
        for my $k (sort keys %$p) {
            my $v = $p->{$k};
            if (ref $v eq 'ARRAY') {
                printf "  %-10s %s\n", $k, join(', ', @$v);
            } elsif ($k eq 'ech') {
                printf "  %-10s [%d bytes opaque]\n", $k, length($v);
            } else {
                printf "  %-10s %s\n", $k, $v;
            }
        }
    }
    EV::break;
});

EV::run;
