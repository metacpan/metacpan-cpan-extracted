#!/usr/bin/env perl
# Minimal DNS proxy: listens UDP on 127.0.0.1:$PORT, forwards each
# query to upstream resolvers via EV::cares, sends raw response back
# (with the client's transaction ID re-written in).
#
# Usage:
#   perl eg/dns_proxy.pl [port=1053] [upstream=8.8.8.8 1.1.1.1 ...]
#   dig @127.0.0.1 -p 1053 example.com
use strict;
use warnings;
use EV;
use EV::cares qw(:all);
use IO::Socket::IP;

my $port = shift @ARGV || 1053;
my @upstreams = @ARGV ? @ARGV : qw(8.8.8.8 1.1.1.1);

my $sock = IO::Socket::IP->new(
    LocalAddr => '127.0.0.1',
    LocalPort => $port,
    Proto     => 'udp',
    ReuseAddr => 1,
) or die "bind 127.0.0.1:$port: $@\n";
$sock->blocking(0);

my $r = EV::cares->new(
    servers => \@upstreams,
    timeout => 3,
    tries   => 2,
);

# Decode just enough of the DNS query to extract the question.
# Returns ($txn_id, $qname, $qclass, $qtype) on success, () on parse error.
sub parse_query {
    my ($pkt) = @_;
    return if length $pkt < 12;
    my $txn = substr $pkt, 0, 2;
    my $pos = 12;
    my @labels;
    while ($pos < length $pkt) {
        my $len = ord substr $pkt, $pos, 1;
        $pos++;
        last if $len == 0;
        return if $len > 63 || $pos + $len > length $pkt;
        push @labels, substr $pkt, $pos, $len;
        $pos += $len;
    }
    return if $pos + 4 > length $pkt;
    my $qtype  = unpack 'n', substr $pkt, $pos,     2;
    my $qclass = unpack 'n', substr $pkt, $pos + 2, 2;
    return ($txn, join('.', @labels), $qclass, $qtype);
}

my $stats = { queries => 0, errors => 0 };

# Watch the listening socket for incoming UDP packets.
my $w = EV::io $sock->fileno, EV::READ, sub {
    my $peer = recv $sock, my $pkt, 4096, 0;
    return unless defined $peer;

    my @q = parse_query($pkt);
    unless (@q) {
        $stats->{errors}++;
        return;
    }
    my ($txn, $qname, $qclass, $qtype) = @q;
    $stats->{queries}++;

    $r->query($qname, $qclass, $qtype, sub {
        my ($status, $resp) = @_;
        if ($status != ARES_SUCCESS || !defined $resp) {
            $stats->{errors}++;
            warn "$qname (type=$qtype): " . EV::cares::strerror($status) . "\n";
            return;
        }
        # rewrite the response's txn id to match the client's request
        substr($resp, 0, 2) = $txn;
        send $sock, $resp, 0, $peer;
    });
};

# Periodic status dump
my $stat = EV::timer 30, 30, sub {
    printf STDERR "[stats] queries=%d errors=%d active=%d\n",
        $stats->{queries}, $stats->{errors}, $r->active_queries;
};

printf "DNS proxy listening on 127.0.0.1:%d → @upstreams\n", $port;
printf "Try: dig \@127.0.0.1 -p %d example.com\n", $port;
EV::run;
