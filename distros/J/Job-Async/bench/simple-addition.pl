use strict;
use warnings;

use Heap;
use IO::Async::Loop::Epoll;
use Future::Utils qw(fmap0);

use Benchmark qw(timethis :hireswallclock);

my @pending_jobs;
{
    package Job::Async::Worker::Memory;
    use parent qw(Job::Async::Worker);
    use Future::Utils qw(repeat);
    sub start {
        my ($self) = @_;
        Future->done;
    }
    sub trigger {
        my ($self) = @_;
        $self->{active} ||= (repeat {
            my $loop = $self->loop;
            my $f = $loop->new_future;
            $self->loop->later(sub {
                if(my $job = shift @pending_jobs) {
                    $self->process($job);
                }
                $f->done;
            });
            $f;
        } while => sub { 0+@pending_jobs })->on_ready(sub {
            delete $self->{active}
        })
    }
    sub process {
        my ($self, $job) = @_;
        $self->jobs->emit($job);
    }
}
{
    package Job::Async::Client::Memory;
    use parent qw(Job::Async::Client);
    sub start {
        my ($self) = @_;
        Future->done;
    }
    sub submit {
        my ($self, %data) = @_;
        push @pending_jobs, my $job = Job::Async::Job->new(
            data => \%data,
            id => rand(1e9),
            future => $self->loop->new_future,
        );
        $job->future
    }
}
my $loop = IO::Async::Loop->new;
$loop->add(
    my $client = Job::Async::Client::Memory->new(
    )
);
$loop->add(
    my $worker = Job::Async::Worker::Memory->new(
        #max_concurrent_jobs => 64,
        #timeout => 5
    )
);
Future->needs_all(
    map $_->start, $client, $worker
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
} concurrent => 64, foreach => [1..1000])->get;
my $elapsed = Time::HiRes::time - $start;
print "Took $elapsed sec, which would be " . ($count / $elapsed) . "/sec\n";

