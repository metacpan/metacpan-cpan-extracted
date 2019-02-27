use strict;
use warnings;

use Test::Fatal;
use Test::More;
use Test::Deep;

use Job::Async::Worker::Redis;
use IO::Async::Loop;

plan skip_all => 'Set JOB_ASYNC_REDIS_URI' unless $ENV{JOB_ASYNC_REDIS_URI};

eval {
    require Log::Any::Adapter;
    Log::Any::Adapter->import('TAP');
    1
} or die $@;
my $loop = IO::Async::Loop->new;

$loop->add(
    my $worker = new_ok('Job::Async::Worker::Redis', [
        uri    => $ENV{JOB_ASYNC_REDIS_URI},
        prefix => 'job',
    ])
);
isa_ok($worker->incoming_job, 'Ryu::Source');
is($worker->{awaiting_job}, undef, 'start with no pending BRPOPLPUSH');
is(exception {
    $worker->trigger
}, undef, 'can ->trigger without exceptions');
isa_ok($worker->{awaiting_job}, 'Future');
ok(my $id = Job::Async::Utils::uuid(), 'can create a new ID');
my %incoming;
$worker->incoming_job->each(sub { ++$incoming{$_->[0]} });
$worker->jobs->each(sub {
    my $job = $_;
    isa_ok($job, 'Job::Async::Job');
    is($job->data('input_example'), 'one_two_three');
    ok(!$job->future->is_ready, 'still pending');
    $loop->later(sub {
        $job->done('result here');
    })
});
$worker->redis->multi(sub {
    my ($tx) = @_;
    $tx->hmset(
        'job::' . $id,
        _reply_to => 'target_address',
        text_input_example => 'one_two_three',
    );
    $tx->lpush($worker->prefixed_queue(($worker->pending_queues)[0]) => $id);
})->get;
$loop->delay_future(after => 0.5)->get;
cmp_deeply(\%incoming, {
    $id => 1
}, 'received expected jobs');

done_testing;


