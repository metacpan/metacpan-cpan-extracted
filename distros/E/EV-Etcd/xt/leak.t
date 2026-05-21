#!/usr/bin/env perl
# Cheap SV-leak smoke test for the dual-ownership streaming-handle path:
# loop new/watch/cancel/DESTROY many times and assert refcounts don't grow.
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Test::More;

BEGIN { eval { require EV }; plan skip_all => 'EV required' if $@ }
eval "use Devel::Leak; 1" or plan skip_all => 'Devel::Leak required';

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

my $iterations = $ENV{LEAK_ITER} || 100;

# Warm up — the first iteration loads code and primes Perl's arena
for (1 .. 5) { run_cycle() }

my $handle;
my $svs_before = Devel::Leak::NoteSV($handle);
for (1 .. $iterations) { run_cycle() }
my $svs_after  = Devel::Leak::CheckSV($handle);

# Allow a small slop for arena rounding / lazy-loaded modules
my $delta = $svs_after - $svs_before;
ok($delta < 50, "$iterations new+watch+cancel+DESTROY cycles leak < 50 SVs (delta=$delta)");

done_testing();

sub run_cycle {
    my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);
    my $watch  = $client->watch("/leak_test_$$", sub { });
    my $done;
    $watch->cancel(sub { $done = 1; EV::break });
    my $t = EV::timer(1, 0, sub { EV::break });
    EV::run;
    undef $watch;
    undef $client;
}
