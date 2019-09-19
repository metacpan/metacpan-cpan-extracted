#!/usr/bin/env perl
use strict;
use warnings;

=head1 NAME

C<jobmon-redis.pl> - monitor job queue activity

=head1 DESCRIPTION

Provides basic statsd metrics for job queues.

The following information is recorded under the C<< job_queue.prefix.processing|pending >> keys:

=over 4

=item * C<age> - how long the job has been in the queue

=item * C<delay> - time between job being queued and worker picking it up

=item * C<work> - elapsed time within worker processing the job

=item * C<total> - time between initial queuing and completion

=item * C<count> - number of jobs in this queue (processing/pending)

=back

=cut

use Net::Async::Redis;
use Net::Async::Statsd::Client;
use IO::Async::Loop;
use IO::Async::Timer::Periodic;

use Future::AsyncAwait;
use Syntax::Keyword::Try;
use Future::Utils qw(fmap_void);

use Log::Any qw($log);

use Getopt::Long;
use Pod::Usage;

GetOptions(
    'l|log=s'      => \my $log_level,
    'p|prefix=s'   => \my $prefix,
    'i|interval=f' => \my $interval,
) or pod2usage(1);

$prefix //= 'jobs';
$log_level //= 'info';
$interval //= 0.1;
require Log::Any::Adapter;
Log::Any::Adapter->import(qw(Stdout), log_level => $log_level);

my $loop = IO::Async::Loop->new;

$loop->add(
    my $redis = Net::Async::Redis->new
);
$loop->add(
    my $statsd = Net::Async::Statsd::Client->new(
        host => 'localhost',
        port => 8125,
        prefix => join('.', 'job_queue', $prefix),
    )
);
my @time_stats = qw(queued processed);
(async sub {
    await $redis->connect;
    while(1) {
        my $then = Time::HiRes::time();
        for my $queue (qw(processing pending)) {
            $statsd->timing($queue . '.count', await $redis->llen(join '::', $prefix, $queue));
            # Limit to a reasonable number of processing and pending jobs
            my $items = await $redis->lrange(join('::', $prefix, $queue), 0, 100);
            await fmap_void(async sub {
                my ($id) = @_;
                $log->tracef('Active job %s', $id);
                my %times;
                @times{@time_stats} = (await $redis->hmget(
                    'job::' . $id,
                    map { "_$_" } @time_stats
                ))->@*;
                my $now = Time::HiRes::time();
                my %stats;
                $stats{age} = ($now - $times{queued}) * 1000.0 if $times{queued};
                $stats{delay} = ($times{started} - $times{queued}) * 1000.0 if $times{queued} and $times{started};
                $stats{work} = ($times{processed} - $times{started}) * 1000.0 if $times{processed} and $times{started};
                $stats{total} = ($times{processed} - $times{queued}) * 1000.0 if $times{processed} and $times{queued};
                $log->tracef('%s job stats %s', $id, \%stats);
                $statsd->timing("$queue.$_" => $stats{$_}) for sort keys %stats;
            }, concurrent => 16, foreach => $items);
        }
        my $now = Time::HiRes::time();
        my $wait = ($then + $interval) - $now;
        await $loop->delay_future(after => $wait) if $wait > 0;
    }
})->()->get;

