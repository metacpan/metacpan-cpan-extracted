#!/usr/bin/env perl
use strict;
use warnings;
use AnyEvent;
use Fork::Promise;
use Promises qw(collect);

use Test::More tests => 1;


my $fork = Fork::Promise->new();

my $cv = AnyEvent->condvar();

my @promises;
push @promises, $fork->run(sub {sleep int(rand(5)); exit 0}) for 1 .. 1000;
push @promises, $fork->run(sub {exec "sleep " . (1+int(rand(5)))}) for 1 .. 1000;

collect(@promises)->then(sub { pass 'all promises held'; $cv->send() });
my $w = AnyEvent->timer(
    after => 30,
    cb => sub { fail 'timeout'; $cv->send() }
);

$cv->recv();
