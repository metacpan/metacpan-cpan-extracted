#!/usr/bin/env perl
# Walk a zone: NS, then resolve each NS, then SOA + DNSKEY hints.
# Usage: perl eg/zone_walk.pl [domain]
use strict;
use warnings;
use EV;
use EV::cares qw(:all);

my $domain = shift // 'example.com';
my $r = EV::cares->new(timeout => 5);
my $pending = 0;
sub bump_break { EV::break unless --$pending }

$pending++;
$r->search($domain, T_NS, sub {
    my ($s, @ns) = @_;
    if ($s == ARES_SUCCESS) {
        print "NS $domain:\n";
        for my $ns (sort @ns) {
            print "  $ns\n";
            $pending++;
            $r->resolve($ns, sub {
                my ($s, @addrs) = @_;
                printf "    %s -> %s\n", $ns,
                    $s == ARES_SUCCESS ? join(', ', @addrs) : 'FAIL';
                bump_break();
            });
        }
    } else {
        print "NS $domain: ", EV::cares::strerror($s), "\n";
    }
    bump_break();
});

$pending++;
$r->search($domain, T_SOA, sub {
    my ($s, $soa) = @_;
    if ($s == ARES_SUCCESS && ref $soa eq 'HASH') {
        printf "SOA %s: %s admin=%s serial=%d refresh=%d retry=%d expire=%d minttl=%d\n",
            $domain, $soa->{mname}, $soa->{rname},
            $soa->{serial}, $soa->{refresh}, $soa->{retry},
            $soa->{expire}, $soa->{minttl};
    } else {
        print "SOA $domain: ", EV::cares::strerror($s), "\n";
    }
    bump_break();
});

$pending++;
$r->search($domain, T_CAA, sub {
    my ($s, @caa) = @_;
    if ($s == ARES_SUCCESS && @caa) {
        for (@caa) {
            printf "CAA %s: %s%s \"%s\"\n",
                $domain, ($_->{critical} ? '!' : ''), $_->{property}, $_->{value};
        }
    } elsif ($s != ARES_SUCCESS) {
        print "CAA $domain: ", EV::cares::strerror($s), "\n";
    }
    bump_break();
});

EV::run;
