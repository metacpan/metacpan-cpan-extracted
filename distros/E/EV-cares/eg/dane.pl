#!/usr/bin/env perl
# Inspect TLSA records for a service (DANE / RFC 6698).
# Usage: perl eg/dane.pl _443._tcp.www.example.com
#        perl eg/dane.pl _25._tcp.mail.example.com
use strict;
use warnings;
use EV;
use EV::cares qw(:all);

my $name = shift or die "usage: $0 _PORT._PROTO.HOSTNAME\n";

my @cert_usage = (
    'CA constraint',
    'service certificate constraint',
    'trust anchor assertion',
    'domain-issued certificate',
);
my @selector = ('full certificate', 'subject public key info');
my @matching = ('exact match', 'SHA-256', 'SHA-512');

my $r = EV::cares->new(timeout => 5);
$r->search($name, T_TLSA, sub {
    my ($status, @rrs) = @_;
    if ($status != ARES_SUCCESS) {
        die "TLSA $name: " . EV::cares::strerror($status) . "\n";
    }
    if (!@rrs || ref $rrs[0] ne 'HASH') {
        warn "no parsed TLSA records (need c-ares >= 1.28)\n";
        EV::break;
        return;
    }
    print "TLSA records for $name:\n";
    for my $rr (@rrs) {
        printf "  usage    : %d (%s)\n",
            $rr->{cert_usage},
            $cert_usage[$rr->{cert_usage}] // 'reserved';
        printf "  selector : %d (%s)\n",
            $rr->{selector},
            $selector[$rr->{selector}] // 'reserved';
        printf "  matching : %d (%s)\n",
            $rr->{matching_type},
            $matching[$rr->{matching_type}] // 'reserved';
        printf "  data     : %s\n\n", unpack('H*', $rr->{data});
    }
    EV::break;
});
EV::run;
