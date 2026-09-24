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
    my $client = EV::Etcd->new(
        endpoints => ['127.0.0.1:2379'],
        timeout => 2,
    );
    $client->status(sub {
        my ($resp, $err) = @_;
        $etcd_available = 1 if !$err;
        EV::break;
    });
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
};

plan skip_all => 'etcd not available on 127.0.0.1:2379' unless $etcd_available;

plan tests => 19;

my $test_prefix = "/test-cleanup-$$-" . time();

{
    my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);
    ok($client, 'created client for DESTROY test');
}
pass('client DESTROY completed without crash');

{
    my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);
    my $done = 0;
    $client->put("$test_prefix/destroy-test", "value", sub {
        $done = 1;
        EV::break;
    });
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok($done, 'put completed before DESTROY');
}
pass('client DESTROY after operation completed without crash');

{
    my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);
    my $watch_created = 0;

    my $watch = $client->watch("$test_prefix/watch-destroy", sub {
        my ($resp, $err) = @_;
        if ($resp && $resp->{created}) {
            $watch_created = 1;
            EV::break;
        }
    });

    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;

    ok($watch_created, 'watch created before letting it go out of scope');
}
pass('watch DESTROY without explicit cancel completed without crash');

{
    my @clients;
    for my $i (1..5) {
        push @clients, EV::Etcd->new(endpoints => ['127.0.0.1:2379']);
    }
    ok(scalar(@clients) == 5, 'created 5 clients');
}
pass('multiple clients DESTROY completed without crash');

# Explicit DESTROY, then the implicit one at scope exit: the second must be a
# no-op, or the gRPC client count drops twice and the next client skips grpc_init
{
    my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);
    $client->DESTROY;
    eval { $client->put("$test_prefix/x", 'v', sub {}) };
    like($@, qr/already destroyed/, 'method on an explicitly destroyed client croaks');
}
{
    my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);
    my $err = 'no callback';
    $client->put("$test_prefix/after", 'v', sub { $err = $_[1]; EV::break });
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
    is($err, undef, 'client after a double DESTROY works');
}
pass('double DESTROY completed without crash');

# Client dropped in callback after nested EV::run must not clear in_callback early
{
    my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);
    my $nested_done = 0;
    $client->get("$test_prefix/nested-1", sub {
        $client->get("$test_prefix/nested-2", sub {
            $nested_done = 1;
            EV::break;
        });
        EV::run;
        undef $client;
    });
    EV::run;
    ok($nested_done, 'nested get completed');
}
pass('client dropped after nested EV::run in callback completed without crash');

{
    my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);
    my $w = $client->watch("$test_prefix/w", sub {});
    undef $client;
    $w->DESTROY;
    $w->DESTROY;
    eval { $w->cancel(sub {}); };
    like($@, qr/already destroyed/, 'watch cancel after DESTROY throws error');
}
pass('watch double DESTROY completed without crash');
{
    my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);
    my $k = $client->lease_keepalive(1, sub {});
    undef $client;
    $k->DESTROY;
    $k->DESTROY;
    eval { $k->cancel(sub {}); };
    like($@, qr/already destroyed/, 'keepalive cancel after DESTROY throws error');
}
pass('keepalive double DESTROY completed without crash');
{
    my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);
    my $o = $client->election_observe("test-lead", sub {});
    undef $client;
    $o->DESTROY;
    $o->DESTROY;
    eval { $o->cancel(sub {}); };
    like($@, qr/already destroyed/, 'observe cancel after DESTROY throws error');
}
pass('observe double DESTROY completed without crash');

my $cleanup_client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);
$cleanup_client->delete("$test_prefix/", { prefix => 1 }, sub {
    diag("Cleanup completed");
});
my $cleanup_timer = EV::timer(2, 0, sub { EV::break });
EV::run;

done_testing();
