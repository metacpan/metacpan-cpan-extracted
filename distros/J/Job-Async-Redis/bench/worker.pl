use strict;
use warnings;

use Heap;
use Job::Async::Worker::Redis;
use Job::Async::Client::Redis;
use IO::Async::Loop::Poll;
use Future::Utils qw(fmap0);
use Time::HiRes;

my $loop = IO::Async::Loop->new;
$loop->add(
    my $worker = Job::Async::Worker::Redis->new(
        uri => 'redis://127.0.0.1',
        max_concurrent_jobs => 4,
        timeout => 5
    )
);
$worker->jobs->each(sub {
    $_->done($_->data('first') + $_->data('second'));
});
$worker->trigger;
$loop->run;
