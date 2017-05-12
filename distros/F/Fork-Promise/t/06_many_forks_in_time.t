#!/usr/bin/env perl
use strict;
use warnings;
use AnyEvent;
use Fork::Promise;
use Promises qw(collect deferred);
use Time::HiRes qw(sleep);
use Data::Dumper;

use Test::More tests => 1;


my $fork = Fork::Promise->new();

my $cv = AnyEvent->condvar();

my $d = deferred();
my @promises = ($d->promise);

my $process_emitter = AnyEvent->timer(
    after => 0,
    interval => 0.01,
    cb => sub {
        my $wait = int(rand(3));
        my $promise = $fork->run(sub { exec "sleep $wait" }, $wait);
        push @promises, $promise;
    },
);

my $w = AnyEvent->timer(
    after => 0.5,
    cb => sub {
        $d->resolve(1);
        undef $process_emitter;
    },
);

my $timeout = AnyEvent->timer(
    after => 5,
    cb => sub {
        fail 'timeout';
        $cv->send()
    },
);

collect(@promises)->then(
    sub {
        pass 'all promises held';
        $cv->send()
    }
);

$cv->recv();
