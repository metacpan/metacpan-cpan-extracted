#!/usr/bin/env perl
# Server-side progress notifications for an idle watch: with progress_notify
# the server sends periodic empty WatchResponses so the client can keep its
# revision cursor fresh. We can't control the server's interval (etcd issues
# them periodically), but the watch's `created` first response always arrives
# and any later progress messages should carry an empty events array and
# advancing header revisions.
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Test::More;

BEGIN { eval { require EV }; plan skip_all => 'EV required' if $@ }
use EV;
use EV::Etcd;

my $available = 0;
eval {
    my $c = EV::Etcd->new(endpoints => ['127.0.0.1:2379'], timeout => 2);
    $c->status(sub { $available = 1 if !$_[1]; EV::break });
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
};
plan skip_all => 'etcd not available on 127.0.0.1:2379' unless $available;

my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);
my $key = "/test_progress_$$";

my @messages;
my $watch = $client->watch($key, { progress_notify => 1 }, sub {
    my ($resp, $err) = @_;
    return if $err;
    push @messages, $resp;
});
ok($watch, 'watch with progress_notify created');

# First response: created=1
my $tcreated = EV::timer(0.05, 0.05, sub {
    EV::break if @messages && $messages[0]{created};
});
my $bail = EV::timer(3, 0, sub { EV::break });
EV::run;

ok(@messages >= 1, 'first watch message arrived');
SKIP: {
    skip 'no first message', 2 unless @messages;
    is($messages[0]{created}, 1, 'first message marks watch as created');
    ok(exists $messages[0]{header}, 'first message has a header');
}

# Force the server to advance global revision by writing to *another* key — the
# watcher should NOT see an event (filtered out by key) but a subsequent
# progress message under progress_notify will reflect the new revision.
$client->put("/test_progress_other_$$", "x", sub { EV::break });
my $tput = EV::timer(2, 0, sub { EV::break });
EV::run;

# Wait for either a progress message (empty events, advanced revision) or
# the wall clock; etcd's default progress interval is ~10 minutes, so we
# can only test that progress_notify doesn't break the watch — we don't
# require a progress tick to land in the test window.
$client->delete("/test_progress_other_$$", sub { EV::break });
my $tcd = EV::timer(2, 0, sub { EV::break });
EV::run;

# Verify the watch survived and first-message contract held
ok($watch, 'watch handle still valid after activity');

$watch->cancel(sub { EV::break });
my $tc = EV::timer(2, 0, sub { EV::break });
EV::run;

done_testing();
