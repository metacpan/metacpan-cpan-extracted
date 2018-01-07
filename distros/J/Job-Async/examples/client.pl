#!/usr/bin/env perl 
use strict;
use warnings;

use Job::Async::Client::Redis;

my $loop = IO::Async::Loop->new(
    my $jq = Job::Async::Client::Redis->new(
        redis_uri => 'redis://localhost:6379',
    )
);

my ($x, $y) = @ARGV or die 'need two numbers';
$jq->submit(
    timeout => 5,
    args => {
        x => $x,
        y => $y,
    },
)->on_done(sub {
    my ($rslt) = @_;
    print "$x + $y = $rslt\n";
})->get;

