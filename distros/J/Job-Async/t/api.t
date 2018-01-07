use strict;
use warnings;

use Test::More;
use IO::Async::Loop;

use Job::Async::Client::Memory;
use Job::Async::Worker::Memory;

subtest api => sub {
    my $loop = IO::Async::Loop->new;
    $loop->add(
        my $worker = new_ok('Job::Async::Worker::Memory')
    );
    $loop->add(
        my $client = new_ok('Job::Async::Client::Memory')
    );
    my $seen = 0;
    $worker->jobs->each(sub {
        ++$seen;
        $_->done(
            $_->data('x') + $_->data('y')
        );
    });
    is($seen, 0, 'no jobs yet');
    ok(my $job = $client->submit(
        x => 1,
        y => 2
    ), 'can submit a job');
    isa_ok($job, 'Job::Async::Job');
    isa_ok($job->future, 'Future');
    is($seen, 0, 'worker has not yet been triggered');
    ok(!$job->is_ready, '... and the job is still pending');
    $worker->trigger;
    Future->needs_any(
        $job->future,
        $loop->timeout_future(after => 1)
    )->get;
    is($seen, 1, 'worker saw the job');
    ok($job->is_done, 'job is now done') or note explain $job->state;
    die 'job not ready' unless $job->is_ready;
    is($job->get, 3, 'result was correct') or note explain $job->state;
    $worker->stop;
    Future->needs_all(
        $worker->jobs->completed
    )->get;
};

done_testing;


