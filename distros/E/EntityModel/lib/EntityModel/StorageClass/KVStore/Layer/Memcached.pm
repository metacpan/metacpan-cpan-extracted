package EntityModel::StorageClass::KVStore::Layer::Memcached;
{
  $EntityModel::StorageClass::KVStore::Layer::Memcached::VERSION = '0.102';
}
use strict;
use warnings;
use parent qw(EntityModel::StorageClass::KVStore::Layer EntityModel::StorageClass::KVStore::Mixin::Deferred);

sub new {
	my $class = shift;
	my %args = @_;
	my $self = $class->SUPER::new;
	$self->{connected} = 0;
	$self->{queue} = [ ];
	require Net::Async::Memcached::Client;
	$self->{memcached} = Net::Async::Memcached::Client->new(
		host => $args{host} || 'localhost',
		loop => $args{loop},
		on_connected => sub { $self->connection_complete }
	);
	$self
}

sub memcached { shift->{memcached} }

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

sub retrieve {
	my $self = shift;
	return $self->queue_task(retrieve => @_) unless $self->is_connected;
	my %args = @_;

	my $on_success = $args{on_success};
	my $k = $args{query};
	$self->memcached->get(
		$args{query},
		on_complete => sub {
			my %args = @_;
			$on_success->($args{value}) if $on_success;
		},
		on_error  => sub {
			my %err_args = @_;
			return $self->retrieval_fallback(%args) if $self->memcached->status_text($err_args{status}) eq 'Key not found';
			warn "Failed:\n";
			warn "* $_ => " . $err_args{$_} for keys %err_args;
			die "giving up"
		}
	);
	$self
}

=head2 store

Store a value in the cache.

Takes the following parameters:

=over 4

=item * $query - query to store under

=item * $value - value to store in key (can be undef)

=back

Returns $self.

=cut

sub store {
	my ($self, $k, $v) = @_;
	return $self->queue_task(store => @_) unless $self->is_connected;

	$self->memcached->set(
               $k => $v,
               on_complete => sub { },
	       on_error  => sub { die "Failed because of @_\n" }
       );
       $self
}

=head2 cleanup

Takes the following parameters:

=over 4

=item *

=back

Returns

=cut

sub shutdown {
        my $self = shift;
        my %args = @_;
        $self->memcached->disconnect(
                on_success => $args{on_success}
        ) if $args{on_success};
        $self
}

1;

