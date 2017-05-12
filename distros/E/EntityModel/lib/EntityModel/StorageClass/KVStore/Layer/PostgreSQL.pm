package EntityModel::StorageClass::KVStore::Layer::PostgreSQL;
{
  $EntityModel::StorageClass::KVStore::Layer::PostgreSQL::VERSION = '0.102';
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
	my $loop = delete $args{loop};
	require Net::Async::PostgreSQL::Client;
	$self->{dbh} = my $pg = Net::Async::PostgreSQL::Client->new(
		%args,
	);
	$loop->add($pg);
	$pg->add_handler_for_event(
		error => sub {
			my $x = shift;
			my %args = @_;
			warn "* $_ => " . $args{error}->{$_} for sort keys %{$args{error}};
			die "failed"
		},
		ready_for_query => sub { $self->connection_complete },
	);
	$pg->connect;
	$self
}

sub dbh { shift->{dbh} }

sub retrieve {
	my $self = shift;
	return $self->queue_task(retrieve => @_) unless $self->is_connected;
	my %args = @_;

	my $on_success = $args{on_success};
	my $k = $args{query};

	$self->dbh->add_handler_for_event(
		data_row => sub {
			return 0 unless $on_success;
			my ($self, %args) = @_;
			$on_success->($args{row}[0]{data});
			0
		}
	);
	# FIXME injected with a poison...
        $self->dbh->simple_query(q{insert into emtest.kvstore(content) values ('} . $k . q{') returning id});
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

1;

