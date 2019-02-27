package Job::Async;
# ABSTRACT: Asynchronous job queue for IO::Async

use strict;
use warnings;

use parent qw(IO::Async::Notifier);

our $VERSION = '0.003';

=head1 NAME

Job::Async - L<IO::Async> abstraction for dispatching tasks to workers and receiving results

=head1 DESCRIPTION

More API details are in the respective base classes:

=over 4

=item * L<Job::Async::Client> - queues jobs for workers to process

=item * L<Job::Async::Worker> - handles the job processing part

=back

Normally, clients and workers would be in separate processes, probably distributed across
multiple servers.

=cut

use Job::Async::Utils;
use Module::Load ();

=head2 worker

Attaches a L<Job::Async::Worker> instance as a child of this manager object,
and returns the new worker instance.

Takes two parameters:

=over 4

=item * C<$type> - used to select the worker class, e.g. C<memory> or C<redis>

=item * C<$cfg> - the configuration parameters to pass to the new worker, as a hashref

=back

Example:

 my $worker = $jobman->worker(
  redis => { uri => 'redis://server', mode => 'reliable' }
 );
 $worker->start;
 $worker->jobs->each(sub { $_->done($_->data('x') . $_->data('y')) });
 $worker->trigger;

=cut

sub worker {
    my ($self, $type, $cfg) = @_;
    die 'need a type' unless $type =~ /^[\w:]+$/;
    my $class = 'Job::Async::Worker::' . ucfirst $type;
    Module::Load::load($class) unless $class->can('new');
    $self->add_child(
        my $worker = $class->new(%$cfg)
    );
    $worker
}

=head2 client

Attaches a L<Job::Async::Client> instance as a child of this manager object,
and returns the new client instance.

Takes two parameters:

=over 4

=item * C<$type> - used to select the worker class, e.g. C<memory> or C<redis>

=item * C<$cfg> - the configuration parameters to pass to the new worker, as a hashref

=back

Example:

 print "Job result was " . $jobman->client(
  redis => { uri => 'redis://server', mode => 'reliable' }
 )->submit(
  x => 123,
  y => 456
 )->get;

=cut

sub client {
    my ($self, $type, $cfg) = @_;
    die 'need a type' unless $type =~ /^[\w:]+$/;
    my $class = 'Job::Async::Client::' . ucfirst $type;
    Module::Load::load($class) unless $class->can('new');
    $self->add_child(
        my $client = $class->new(%$cfg)
    );
    $client
}

1;

=head1 SEE ALSO

The main feature missing from the other alternatives is job completion notification - seems that
"fire and forget" is a popular model.

=over 4

=item * L<Gearman> - venerable contender for background job handling, usually database-backed

=item * L<TheScwhartz> - reliable job queuing, database-backed again

=item * L<Minion> - integrates with L<Mojolicious>, normally seems to be used with a PostgreSQL
backend. Has some useful routing and admin features. Does have some support for notification -
see L<Minion::Notifier> for example - but at the time of writing this came with significant
overhead.

=item * L<Mojo::Redis::Processor> - a curious hybrid of L<Mojo::Redis2> and L<RedisDB>, using
pub/sub and a race on C<SETNX> calls to handle multiple instances possibly trying to queue
the same job at once.

=item * L<Redis::JobQueue>

=item * L<Qless>

=item * L<Queue::Q>

=item * L<Vayne>

=item * L<Resque>

=item * L<Disque>

=item * L<Sque>

=back

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >>

=head1 LICENSE

Copyright Tom Molesworth 2015-2017. Licensed under the same terms as Perl itself.

