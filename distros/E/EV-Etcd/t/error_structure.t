#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';

BEGIN {
    eval { require EV };
    if ($@) {
        plan skip_all => 'EV module not available';
        exit;
    }
}

plan tests => 8;

use_ok('EV::Etcd');

my $client = EV::Etcd->new(
    endpoints => ['127.0.0.1:29999'],
    timeout => 2,
    max_retries => 0,  # No retries to make test faster
);

ok($client, 'client created with bad endpoint');

my $error_received;
my $got_response = 0;

$client->get('/test/key', sub {
    my ($resp, $err) = @_;
    $got_response = 1;
    $error_received = $err;
    EV::break;
});

my $timer = EV::timer(5, 0, sub {
    EV::break;
});

EV::run;

ok($got_response, 'callback was called');
ok($error_received, 'received an error');
ok(ref($error_received) eq 'HASH', 'error is a hashref');
ok(exists $error_received->{code}, 'error has code field');
ok(exists $error_received->{status}, 'error has status field');
ok(exists $error_received->{retryable}, 'error has retryable field');

if ($error_received && ref($error_received) eq 'HASH') {
    diag("Error details:");
    diag("  code: $error_received->{code}");
    diag("  status: $error_received->{status}");
    diag("  message: $error_received->{message}");
    diag("  source: $error_received->{source}");
    diag("  retryable: $error_received->{retryable}");
}

done_testing();
