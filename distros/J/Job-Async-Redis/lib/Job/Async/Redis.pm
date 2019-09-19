package Job::Async::Redis;

use strict;
use warnings;

our $VERSION = '0.004';

=head1 NAME

Job::Async::Redis - L<Net::Async::Redis> backend for L<Job::Async>

=head1 SYNOPSIS

 use IO::Async::Loop;
 use Job::Async;
 my $loop = IO::Async::Loop->new;
 $loop->add( my $jobman = Job::Async->new );
 my $client = $jobman->client(
     redis => { uri => 'redis://127.0.0.1', }
 );
 my $worker = $jobman->worker(
     redis => { uri => 'redis://127.0.0.1', }
 );
 Future->needs_all(
     $client->start,
 )->get;

 $worker->jobs->each(sub {
     $_->done('' . reverse $_->data('some_data'))
 });
 print Future->needs_all(
  $client->start,
  $worker->trigger
 )->then(sub {
  $client->submit(
   some_data => 'reverse me please'
  )->future
 })->get;

=head1 DESCRIPTION

The system can be configured to select a performance/reliability tradeoff
as follows. Please note that clients and workers B<must> be configured to
use the same mode - results are undefined if you try to mix clients and
workers using different modes. If it works, don't rely on it.

=head2 Operational modes

=head3 simple

Jobs are submitted by serialising as JSON and pushing to a Redis list
as a queue.

Workers retrieve jobs from queue, and send the results via pubsub.

Multiple queues can be used for priority handling - the client can route
based on the job data.

=head3 recoverable

As with simple mode, queues are used for communication between the
clients and workers. However, these queues contain only the job ID.

Actual job data is stored in a hash key, and once the worker completes
the result is also stored here.

Job completion will trigger a L<Net::Redis::Async::Commands/publish>
notification, allowing clients to listen for completion.

Multiple queues can be used, as with C<simple> mode.

=head3 reliable

Each worker uses L<Net::Async::Redis::Commands/brpoplpush> to await job IDs
posted to a single queue.

Job details are stored in a hash key, as with the C<recoverable> approach.

When a worker starts on a job, the ID is atomically moved to an in-process queue,
and this is used to track whether workers are still valid.

Only one queue is allowed per worker, due to limitations of the
L<Net::Async::Redis::Commands/brpoplpush> implementation as described in
L<this issue|https://github.com/antirez/redis/issues/1785>.

=cut

use Job::Async::Worker::Redis;
use Job::Async::Client::Redis;

our %MODES = (
    simple      => 1,
    recoverable => 1,
    reliable    => 1
);

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2019. Licensed under the same terms as Perl itself.

