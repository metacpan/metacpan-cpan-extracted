#!/usr/bin/env perl 
use strict;
use warnings;

use Job::Async::Worker::Redis;

my $loop = IO::Async::Loop->new(
    my $worker = Job::Async::Worker::Redis->new(
        redis_uri => 'redis://localhost:6379',
    )
);

$worker->jobs
    ->each(sub {
        $job->done(
            $job->args('x') + $job->args('y')
        );
    })->await;

