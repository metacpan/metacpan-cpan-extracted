use strict;
use warnings;

use Heap;
use Job::Async;
use IO::Async::Loop;
use Future::Utils qw(fmap0);

use Benchmark qw(timethis :hireswallclock);

my $loop = IO::Async::Loop->new;
$loop->add(
    my $jobman = Job::Async->new(
    )
);
my $client = $jobman->client(
    redis => {
        uri => 'redis://127.0.0.1',
    }
);
my $worker = $jobman->worker(
    redis => {
        uri => 'redis://127.0.0.1',
    }
);
Future->needs_all(
    $client->start,
    $worker->redis->del('jobs::pending'),
    $worker->redis->del('jobs::processing'),
)->get;

$worker->jobs->each(sub {
    $_->done($_->data('first') + $_->data('second'));
});
$worker->trigger;
my $start = Time::HiRes::time;
my $count = 0;
(fmap0 {
    my $x = int(100 * rand);
    my $y = int(100 * rand);
    $client->submit(
        first  => $x,
        second => $y,
    )->on_done(sub {
        ++$count;
        warn 'bad result' unless $x + $y == shift
    })->on_fail(sub {
        warn 'failure ' . shift
    })
} concurrent => 10, foreach => [1..1000])->get;
my $elapsed = Time::HiRes::time - $start;
print "Took $elapsed sec, which would be " . ($count / $elapsed) . "/sec\n";

