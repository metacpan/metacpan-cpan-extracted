#!/usr/bin/env perl
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Test::More;

BEGIN {
    eval { require EV };
    plan skip_all => 'EV required' if $@;
}

use EV;
use EV::Etcd;

# Check if etcd is available
my $etcd_available = 0;
eval {
    my $c = EV::Etcd->new(endpoints => ['127.0.0.1:2379'], timeout => 2);
    $c->status(sub { $etcd_available = 1 if !$_[1]; EV::break });
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
};

plan skip_all => 'etcd not available on 127.0.0.1:2379' unless $etcd_available;

plan tests => 4;

my $client = EV::Etcd->new(
    endpoints => ['127.0.0.1:2379'],
    max_retries => 5,
);

ok($client, 'client created');

my $test_key = "/test_auto_reconnect_$$";
my $watch;
my $events_received = 0;
my $test_done = 0;

# Test 1: Create watch with auto_reconnect (default)
$watch = $client->watch($test_key, {
    progress_notify => 1,
}, sub {
    my ($resp, $err) = @_;
    return if $test_done;
    
    if ($err) {
        # Error structure should be a hashref
        ok(ref($err) eq 'HASH', 'error is a hashref');
        ok(exists $err->{code}, 'error has code');
        ok(exists $err->{status}, 'error has status');
        ok(exists $err->{message}, 'error has message');
        ok(exists $err->{retryable}, 'error has retryable flag');
    } elsif ($resp->{events} && @{$resp->{events}}) {
        $events_received++;
    }
});

ok($watch, 'watch created with auto_reconnect');

# Test 2: Verify watch receives events
my $put_done = 0;
$client->put($test_key, "test_value_$$", sub {
    my ($resp, $err) = @_;
    $put_done = 1;
    ok(!$err, 'put succeeded');
});

# Run event loop briefly
my $timer = EV::timer(2, 0, sub {
    $test_done = 1;
    EV::break;
});

EV::run;

ok($events_received >= 1, "watch received $events_received event(s)");

# Cleanup
$watch->cancel(sub {
    $client->delete($test_key, sub {
        EV::break;
    });
});

my $cleanup_timer = EV::timer(1, 0, sub { EV::break });
EV::run;

done_testing();
