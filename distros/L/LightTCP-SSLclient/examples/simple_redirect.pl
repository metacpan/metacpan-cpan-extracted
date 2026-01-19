#!/usr/bin/env perl
use strict;
use warnings;
use lib '../lib';
use LightTCP::SSLclient;

my $client = LightTCP::SSLclient->new(
    timeout       => 30,
    follow_redirects => 1,
    max_redirects => 5,
);

my ($ok, $errors, $debug, $code) = $client->connect('reqbin.com', 443);

unless ($ok) {
    die "Connect failed: @$errors";
}

my ($status, $state, $headers, $body, $resp_errors, $resp_debug, $resp_code, $history)
    = $client->request_with_redirects('GET', '/echo', host => 'reqbin.com');

print "Final status: $status $state\n";
print "Redirects followed: " . scalar(@$history) . "\n";

if (@$history) {
    print "\n--- Redirect chain ---\n";
    for my $r (@$history) {
        print "$r->{code}: $r->{from}\n";
        print "       -> $r->{to}\n";
    }
}

print "\n--- Response body preview ---\n";
print substr($body, 0, 300);
print "...\n" if length($body) > 300;

$client->close();
