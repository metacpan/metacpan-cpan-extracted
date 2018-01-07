use strict;
use warnings;

use Test::Fatal;
use Test::More;
use Test::Deep;

use Job::Async::Worker::Redis;
use Job::Async::Client::Redis;
use IO::Async::Loop;

plan skip_all => 'Set JOB_ASYNC_REDIS_URI' unless $ENV{JOB_ASYNC_REDIS_URI};

eval {
    require Log::Any::Adapter;
    Log::Any::Adapter->import('TAP');
    1
};

my $loop = IO::Async::Loop->new;

$loop->add(
    my $worker = new_ok('Job::Async::Worker::Redis', [
        uri => $ENV{JOB_ASYNC_REDIS_URI},
    ])
);
$loop->add(
    my $client = new_ok('Job::Async::Client::Redis', [
        uri => $ENV{JOB_ASYNC_REDIS_URI},
    ])
);
$worker->redis->del('jobs::pending')->get;
$worker->redis->del('jobs::processing')->get;
$worker->jobs->each(sub {
    $_->done($_->data('first') + $_->data('second'));
});
$client->start->get;
$worker->trigger;
is($client->submit(
    first => 45,
    second => 64,
)->get, 109, 'result was correct');

done_testing;


