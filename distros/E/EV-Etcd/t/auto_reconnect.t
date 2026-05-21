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
my $watch_created = 0;

# Test 1: Create watch with auto_reconnect (default)
$watch = $client->watch($test_key, {
    progress_notify => 1,
}, sub {
    my ($resp, $err) = @_;
    return if $test_done;

    if ($err) {
        ok(ref($err) eq 'HASH', 'error is a hashref');
        ok(exists $err->{code}, 'error has code');
        ok(exists $err->{status}, 'error has status');
        ok(exists $err->{message}, 'error has message');
        ok(exists $err->{retryable}, 'error has retryable flag');
    } else {
        $watch_created ||= $resp->{created};
        $events_received++ if $resp->{events} && @{$resp->{events}};
    }
});

ok($watch, 'watch created with auto_reconnect');

# Wait for the watch's first server response (created=1) before firing the put,
# otherwise on a slow/loaded runner the put can land before the watch is
# registered and the event is never delivered.
my $created_timeout = EV::timer(5, 0, sub { EV::break });
my $created_check = EV::timer(0.05, 0.05, sub { EV::break if $watch_created });
EV::run;
undef $created_check;
undef $created_timeout;

# Test 2: Verify watch receives events
$client->put($test_key, "test_value_$$", sub {
    my ($resp, $err) = @_;
    ok(!$err, 'put succeeded');
});

# Wait for the put's event to fan out through the watch
my $timer = EV::timer(2, 0, sub {
    $test_done = 1;
    EV::break;
});
my $event_check = EV::timer(0.05, 0.05, sub {
    EV::break if $events_received >= 1;
});

EV::run;
undef $event_check;

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
