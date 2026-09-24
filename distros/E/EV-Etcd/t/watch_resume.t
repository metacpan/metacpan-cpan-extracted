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

my $etcd_available = 0;
eval {
    my $c = EV::Etcd->new(endpoints => ['127.0.0.1:2379'], timeout => 2);
    $c->status(sub { $etcd_available = 1 if !$_[1]; EV::break });
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
};

plan skip_all => 'etcd not available on 127.0.0.1:2379' unless $etcd_available;

plan tests => 6;

my $client = EV::Etcd->new(
    endpoints => ['127.0.0.1:2379'],
);

ok($client, 'client created');

my $test_key = "/test_watch_resume_$$";

my $initial_revision;
$client->put($test_key, "initial_value", sub {
    my ($resp, $err) = @_;
    ok(!$err, 'initial put succeeded');
    $initial_revision = $resp->{header}{revision};
    diag("Initial revision: $initial_revision");
    EV::break;
});
EV::run;

for my $i (1..3) {
    $client->put($test_key, "value_$i", sub { EV::break });
    EV::run;
}

my @events;
my $watch = $client->watch($test_key, {
    start_revision => $initial_revision,
}, sub {
    my ($resp, $err) = @_;
    if ($err) {
        diag("Watch error: " . (ref($err) eq 'HASH' ? $err->{message} : $err));
        return;
    }
    if ($resp->{events} && @{$resp->{events}}) {
        for my $event (@{$resp->{events}}) {
            push @events, $event->{kv}{value};
        }
        # initial + 3 updates
        if (@events >= 4) {
            EV::break;
        }
    }
});

ok($watch, 'watch created with start_revision');

my $timer = EV::timer(3, 0, sub { EV::break });
EV::run;

ok(@events >= 4, "received " . scalar(@events) . " events (expected 4)");

is($events[0], 'initial_value', 'first event is initial value');
is($events[3], 'value_3', 'last event is value_3');

diag("Events received: " . join(', ', @events));

$watch->cancel(sub {
    $client->delete($test_key, sub { EV::break });
});
my $cleanup = EV::timer(1, 0, sub { EV::break });
EV::run;

done_testing();
