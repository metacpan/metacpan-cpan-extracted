#!/usr/bin/env perl
use strict;
use warnings;
use lib '../lib';
use LightTCP::SSLclient;

my $client = LightTCP::SSLclient->new(
    timeout => 30,
    verbose => 1,
);

my ($ok, $errors, $debug, $code) = $client->connect('reqbin.com', 443);

unless ($ok) {
    die "Connect failed: @$errors";
}

($ok, $errors, $debug, $code) = $client->request('GET', '/echo', host => 'reqbin.com');

unless ($ok) {
    die "Request failed: @$errors";
}

my ($status, $state, $headers, $body) = $client->response();

print "=== DEBUG OUTPUT ===\n";
print @$debug;

print "\n=== ERRORS ===\n";
print @$errors ? @$errors : "(none)\n";

print "\n=== RESPONSE ===\n";
print "Status: $status $state\n";
print "Body length: " . length($body) . " bytes\n";

$client->close();
