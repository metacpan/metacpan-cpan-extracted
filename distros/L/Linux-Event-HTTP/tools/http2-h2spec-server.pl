#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Getopt::Long qw(GetOptions);

use Linux::Event::HTTP::Server;
use Linux::Event::Loop;

my $host = '127.0.0.1';
my $port = 18443;
my ($cert, $key);
my $native = 1;
my $response_mode = 'headers';

GetOptions(
    'host=s' => \$host,
    'port=i' => \$port,
    'cert=s' => \$cert,
    'key=s'  => \$key,
    'native-input!' => \$native,
    'response-mode=s' => \$response_mode,
) or die "usage: $0 --cert FILE --key FILE [--host HOST] [--port PORT]\n";

die "--response-mode must be headers or request\n"
    unless $response_mode eq 'headers' || $response_mode eq 'request';
die "--cert is required\n" if !defined($cert) || $cert eq '';
die "--key is required\n" if !defined($key) || $key eq '';
die "--port must be between 1 and 65535\n"
    if $port < 1 || $port > 65_535;

my $loop = Linux::Event::Loop->new;

my $server = Linux::Event::HTTP::Server->new(
    loop  => $loop,
    host  => $host,
    port  => $port,
    http2 => 1,
    native_input => $native,
    tls   => {
        cert_file => $cert,
        key_file  => $key,
    },
    # Compare early response against response after the full request.
    # Both modes retain identical status/body; no engine behavior changes.
    on_headers => sub ($tx, $request) {
        $tx->on_data(sub { });
        if ($response_mode eq 'headers') {
            $tx->respond(status => 200,
                headers => [['content-type', 'text/plain']], body => "unblock-h2spec-ok\n");
        }
    },
    on_request => sub ($tx, $request) {
        if ($response_mode eq 'request') {
            $tx->respond(status => 200,
                headers => [['content-type', 'text/plain']], body => "ok\n");
        }
    },
);

$| = 1;
say "READY " . $server->host . ":" . $server->port;

$loop->run;
