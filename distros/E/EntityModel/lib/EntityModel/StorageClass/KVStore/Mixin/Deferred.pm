package EntityModel::StorageClass::KVStore::Mixin::Deferred;
{
  $EntityModel::StorageClass::KVStore::Mixin::Deferred::VERSION = '0.102';
}
use strict;
use warnings;

=head2 has_pending

Returns true if there are pending tasks in the queue.

=cut

sub has_pending { @{ shift->{queue} } }

=head2 run_pending

Processes any tasks pending in the queue.

=cut

sub run_pending {
	my $self = shift;
	return $self unless $self->is_connected;
	while(my $task = shift @{$self->{queue}}) {
		my $method = shift @$task;
		$self->$method(@$task);
	}
	$self;
}

=head2 is_connected

Returns true if we have established a connection.

=cut

sub is_connected { shift->{connected} }

=head2 queue_task

Queues a task for processing when we get around to connecting
later.

Takes the following parameters:

=over 4

=item * $method - should be 'store' or 'retrieve'

=item * @args - any parameters, will be passed verbatim when we get around to
calling the method.

=back

Returns $self.

=cut

sub queue_task {
	my $self = shift;
	push @{ $self->{queue} }, [ @_ ];
	$self
}

=head2 connection_complete

Takes the following parameters:

=over 4

=item *

=back

Returns $self.

=cut

sub connection_complete {
	my $self = shift;
	$self->{connected} = 1;
	$self->run_pending if $self->has_pending;
	$self;
}

1;
