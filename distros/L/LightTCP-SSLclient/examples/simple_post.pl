#!/usr/bin/env perl
use strict;
use warnings;
use lib '../lib';
use LightTCP::SSLclient;

my $client = LightTCP::SSLclient->new(timeout => 30);
my ($ok, $errors, $debug, $code) = $client->connect('reqbin.com', 443);

unless ($ok) {
    die "Connect failed: @$errors";
}

my $payload = '{"name":"test","value":123}';

($ok, $errors, $debug, $code) = $client->request(
    'POST',
    '/echo/post/json',
    host    => 'reqbin.com',
    payload => $payload,
    headers => {
        'Content-Type' => 'application/json',
    },
);

unless ($ok) {
    die "Request failed: @$errors";
}

my ($status, $state, $headers, $body) = $client->response();

print "Status: $status $state\n";
print "Response:\n";
print $body;
print "\n";

$client->close();
