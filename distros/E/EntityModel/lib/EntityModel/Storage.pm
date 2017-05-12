package EntityModel::Storage;
{
  $EntityModel::Storage::VERSION = '0.102';
}
use EntityModel::Class {
	_isa		=> [qw(Mixin::Event::Dispatch)],
	entity		=> { type => 'array', subclass => 'EntityModel::Entity' },
	transaction	=> { type => 'array', subclass => 'EntityModel::Transaction' },
};
no if $] >= 5.017011, warnings => "experimental::smartmatch";

=head1 NAME

EntityModel::Storage - backend storage interface for L<EntityModel>

=head1 VERSION

version 0.102

=head1 SYNOPSIS

See L<EntityModel>.

=head1 DESCRIPTION

See L<EntityModel> for more details.

=head1 METHODS

=cut

=head2 register

Register with L<EntityModel> so that callbacks trigger when further definitions are loaded/processed.

The base storage engine doesn't provide any callbacks - but we define the method anyway so that we don't
need to check for ->can.

=cut

sub register {
	my $class = shift;
}

=head2 apply_model

Apply the given model.

=cut

sub apply_model {
	my $self = shift;
	my $model = shift;
	$self->apply_model_and_schema($model);
}

=head2 apply_model_and_schema

Apply the given model to the storage layer.

This delegates most of the work to L</apply_entity>.

=cut

sub apply_model_and_schema {
	my $self = shift;
	my $model = shift;
	my %args = @_;

	# Start off assuming that we need all the listed entities
	my @pending = $model->entity->list;
	# Nothing applied yet (should be $self->entity->list)
	my %existing;
	my @pendingNames = map { $_->name } @pending;

	my $code;
	# Called when everything's been applied successfully
	my $done; $done = sub {
#		$done = sub { die "Tried to hit the same completion callback twice\n" };
		$args{on_complete}->() if exists $args{on_complete};
		0
	};
	my %incomplete;
	# Process a single entity
	$code = sub {
		# We may be a leftover event, bail out if there's nothing to do
		unless(@pending) {
			return 1 if keys %incomplete; # try us again later
			$done->();
			return 0; # all complete
		}

		# Next item in queue, no idea what state it's in yet
		my $entity = shift(@pending);

		# Also remove current entry so we don't match ourselves when checking deps
		shift(@pendingNames);

		# If we've seen this one before, assume it's done
		# FIXME Diff the entities
		return $code->() if exists $existing{$entity->name};

		{ # Dependency handling
			my @deps = map { $_->name } $entity->dependencies;
			# Include ourselves in the list in case anyone else has a dependency on us
			my %expected = %existing; @expected{map { $_->name } @pending, $entity} = ();
			if(my @unresolved = grep { !exists $expected{$_} } @deps, $entity->name) {
				logError("%s unresolved (pending %s, deps %s for %s)", $_, join(',', @pendingNames), join(',', @deps), $entity->name) for @unresolved;
				die "Dependency error";
			}

			# Check that all dependencies are complete
			delete @expected{$entity->name, keys %existing};
			if(my @unsatisfied = grep { exists $expected{$_} } @deps) {
				logInfo("%s has %d unsatisfied deps, postponing: %s", $entity->name, scalar @unsatisfied, join(',',@unsatisfied));
				push @pending, $entity;
				push @pendingNames, $entity->name;
				return $code->();
			}
		}

		# Apply this entity and add more detail to the error message if it fails:
		return try {
			$incomplete{$entity->name} = $entity;
			$self->apply_entity(
				$entity,
				on_complete => sub {
					# Record this entry so we pick it up in later dependency checks
					$existing{$entity->name} = $entity;
					$code->();
					return 0;
				}
			);
			return 0;
		} catch {
			die "Failed to apply entity " . $entity->name . " (pending " . join(',', @pendingNames) . "): " . ($_ // 'undef');
			return 1;
		};
	};
	1 while $code->();
	return $self;
}

=head2 read

Reads the data for the given entity and returns hashref with the appropriate data.

Parameters:

=over 4

=item * entity - L<EntityModel::Entity>

=item * id - ID to read data from

=back

=cut

sub read {
	my $self = shift;
	my %args = @_;
	die "Virtual!";
}

=head2 create

Creates new entry for the given L<EntityModel::Entity>.

Parameters:

=over 4

=item * entity - L<EntityModel::Entity>

=item * data - actual data values

=back

=cut

sub create {
	my $self = shift;
	my %args = @_;
	die "Virtual!";
}

=head2 store

Stores data to the given entity and ID.

Parameters:

=over 4

=item * entity - L<EntityModel::Entity>

=item * id - ID to store data to

=item * data - actual data values

=back

=cut

sub store {
	my $self = shift;
	my %args = @_;
	die "Virtual!";
}

=head2 remove

Removes given ID from storage.

Parameters:

=over 4

=item * entity - L<EntityModel::Entity>

=item * id - ID to store data to

=back

=cut

sub remove {
	my $self = shift;
	my %args = @_;
	die "Virtual!";
}

=head2 find

Find some entities that match the spec.

=cut

sub find {
	my $self = shift;
	my %args = @_;
	die "Virtual!";
}

=head2 adjacent

Returns the previous and next element for the given ID.

=cut

sub adjacent {
	my $self = shift;
	my %args = @_;
	die "Virtual!";
}

=head2 prev

Returns previous element for the given ID.

=cut

sub prev {
	my $self = shift;
	my ($prev, $next) = $self->adjacent(@_);
	return $prev;
}

=head2 next

Returns next element for the given ID.

=cut

sub next {
	my $self = shift;
	my ($prev, $next) = $self->adjacent(@_);
	return $next;
}

=head2 outer

Returns first and last IDs for the given entity.

=cut

sub outer {
	my $self = shift;
	my %args = @_;
	die "Virtual!";
}

=head2 first

Returns first active ID for the given entity.

=cut

sub first {
	my $self = shift;
	my ($first, $last) = $self->outer(@_);
	return $first;
}

=head2 last

Returns last active ID for the given entity.

=cut

sub last {
	my $self = shift;
	my ($first, $last) = $self->outer(@_);
	return $last;
}

=head2 transaction_start

Mark the start of a transaction.

=cut

sub transaction_start {
	my $self = shift;
	my $tran = shift;

# TODO weaken?
	$self->transaction->push($tran);
	return $self;
}

=head2 transaction_rollback

Roll back a transaction.

=cut

sub transaction_rollback {
	my $self = shift;
	my $tran = shift;
	die "No transaction in progress" unless $self->transaction->count;
	die "Mismatched transaction" unless $tran ~~ $self->transaction->last;
}

=head2 transaction_commit

Commit this transaction to storage - makes everything done within the transaction permanent
(or at least to the level the storage class supports permanence).

=cut

sub transaction_commit {
	my $self = shift;
	my $tran = shift;
	die "No transaction in progress" unless $self->transaction->count;
	die "Mismatched transaction" unless $tran ~~ $self->transaction->last;
}

=head2 transaction_end

Release the transaction on completion.

=cut

sub transaction_end {
	my $self = shift;
	my $tran = shift;
	die "No transaction in progress" unless $self->transaction->count;
	die "Mismatched transaction" unless $tran ~~ $self->transaction->last;
	$self->transaction->pop;
	return $self;
}

sub backend_ready { shift->{backend_ready} }

sub wait_for_backend {
	my $self = shift;
	my $code = shift;
	return $code->($self) if $self->backend_ready;
	$self->add_handler_for_event( backend_ready => sub { $code->(@_); 0 });
	return $self;
}

sub DESTROY {
	my $self = shift;
	die "Active transactions" if $self->transaction->count;
}

1;

__END__

=head1 SUBCLASSING

This module provides the abstract base class for all storage modules. Here's how to build
your own.

=head2 INITIAL SETUP

L</setup> will be called when this storage class is attached to the model via
L<EntityModel/add_storage>, and this will receive the $model as the first parameter along
with any additional options. Typically this will include storage-specific connection
information.

Each entity added to the model will be applied to the storage engine through L</apply_entity>.
It is the responsibility of the storage engine to verify that it is able to handle the given
entities and fields, either creating the underlying storage structure (database tables, etc.)
or raising an error if this isn't appropriate.

=head2 USAGE

Most of the work is handled by the following methods:

=over 4

=item * L</read> - retrieves data from the backend storage engine for the given entity and ID

=item * L</create> - writes new data to storage for given entity, data and optional ID

=item * L</store> - updates an existing entry in storage for the given entity, data and ID

=item * L</remove> - deletes an existing entry from storage, takes entity and ID

=back

Each of these applies to a single entity instance only. Since they operate on a callback
basis, multiple operations can be aggregated if desired:

 select * from storage where id in (x,y,z)

Two callbacks are required for each of the above operations:

=over 4

=item * on_complete - the operation completed successfully and the data is guaranteed to
have been written to storage. The strength of this guarantee depends on the storage engine
but it should be safe for calling code to assume that any further operations will not result
in losing the data - for example, a database engine would commit the data before sending this
event.

=item * on_fail - the operation was not successful and storage has been rolled back to
the previous state. This could be the case when trying to create an item with a pre-existing
ID or possibly transaction deadlock, although in the latter case it would be preferable to
attempt retry some reasonable number of times before signalling a failure.

=back

Neither callback is mandatory - default behaviour if there is no C<on_fail> is to die() on failure,
and no-op if C<on_complete> is not specified.

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
