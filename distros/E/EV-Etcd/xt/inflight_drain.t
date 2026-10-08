#!/usr/bin/env perl
# Completions of many in-flight calls take linear time: four times the calls
# must not take sixteen times as long to drain (quadratic handling took 32)
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Test::More;
use Time::HiRes qw(time);

BEGIN { eval { require EV }; plan skip_all => 'EV required' if $@ }

use EV;
use EV::Etcd;

my $ETCD = '127.0.0.1:2379';

my $client = EV::Etcd->new(endpoints => [$ETCD], timeout => 60);
my $available = 0;
$client->status(sub { $available = 1 if !$_[1]; EV::break });
{
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
}
plan skip_all => "etcd not available on $ETCD" unless $available;

sub drain_seconds {
    my $n = shift;
    my ($done, $first, $last) = (0);
    for (1 .. $n) {
        $client->get('/xt-inflight-drain', sub {
            $first //= time;
            if (++$done == $n) { $last = time; EV::break }
        });
    }
    my $t = EV::timer(120, 0, sub { EV::break });
    EV::run;
    return $done == $n ? $last - $first : 9**9;
}

drain_seconds(1000);
my ($small, $large) = (9**9, 9**9);
for (1 .. 2) {
    my $s = drain_seconds(6000);
    my $l = drain_seconds(24000);
    $small = $s if $s < $small;
    $large = $l if $l < $large;
}
cmp_ok($large / $small, '<', 16,
    sprintf('24000 calls drain in %.3fs, 6000 in %.3fs', $large, $small));

done_testing;
