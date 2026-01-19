#!/usr/bin/env perl
use strict;
use warnings;
use lib '../lib';
use LightTCP::SSLclient;

my $client = LightTCP::SSLclient->new(
    timeout    => 30,
    keep_alive => 1,
);

my ($ok, $errors, $debug, $code) = $client->connect('reqbin.com', 443);

unless ($ok) {
    die "Connect failed: @$errors";
}

print "Connected. Making 3 requests on same connection...\n";
print "Keep-alive: " . ($client->is_keep_alive() ? "enabled" : "disabled") . "\n\n";

for my $i (1 .. 3) {
    my ($req_ok, $req_errors, $req_debug, $req_code)
        = $client->request('GET', "/echo?id=$i", host => 'reqbin.com');

    unless ($req_ok) {
        warn "Request $i failed: @$req_errors";
        next;
    }

    my ($status, $state, $headers, $body, $resp_errors, $resp_debug, $resp_code)
        = $client->response();

    if (defined $status && $status =~ /^\d+$/) {
        print "Request $i: $status $state (Connection: $headers->{'connection'})\n";
    } else {
        print "Request $i: Response error\n";
    }
}

print "\nConnection still alive: " . ($client->is_connected() ? "yes" : "no") . "\n";

$client->close();
