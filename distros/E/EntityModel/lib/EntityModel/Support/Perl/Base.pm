package EntityModel::Support::Perl::Base;
{
  $EntityModel::Support::Perl::Base::VERSION = '0.102';
}
use EntityModel::Class {
};
no if $] >= 5.017011, warnings => "experimental::smartmatch";

=head1 NAME

EntityModel::Support::Perl::Base - base class for entity instances

=head1 VERSION

version 0.102

=head1 SYNOPSIS

 say $_->name foreach Entity::Thing->find({name=>'test'});

=head1 DESCRIPTION

All entities are derived from this base class by default.

=head1 ASYNCHRONOUS HANDLING

When data has not yet been loaded for an entity, some additional logic is used to allow
asynchronous requests via chained method accessors.

Given a chain $book->author->address->city, where the first three entries are regular entities
and the last item in the chain is an accessor for a scalar method:

First, we check $book to see whether it has an author yet. If the author information is loaded
(to the extent that ->author contains an entity instance), then we can use this existing instance.
If not, we instantiate a new entity of this type, marked as incomplete and as a pending request, and
continue.

This means that a chain where some of the elements can be null is still valid. As data is populated,
entries in this chain will be filled out, and cases where the foreign key value was null will end up
marked as invalid entities.

In general, unless you know beforehand that all entities in the chain have been populated, all access
to chained entities should go through the L<EntityModel::Gather> interface to ensure that values are
consistent.

This also allows the backend storage to apply optimisations if available - if several pending requests
address related storage areas, it may be possible for the storage engine to combine queries and return
data faster.

=head1 EVENTS

Two types of events can be defined:

=over 4

=item * task - this is a one-shot event, typically used to call a piece of code after data has been written
to or read from storage

=item * event - this is an event handler that will be called every time an event occurs.

=back

These are handled by the L</_queue_task> and L</_attach_event> methods respectively.

=cut

use Time::HiRes qw{time};
use POSIX::strptime ();
use Tie::Cache::LRU;

sub _supported_callbacks { qw(before_commit after_load on_not_found on_create) }

=head2 new

Instantiate from an ID or a pre-fabricated object (hashref).

=over 4

=item * Create a new, empty object:

 EntityModel::Support::Perl::Base->new(1)

=item * Instantiate from ID:

 EntityModel::Support::Perl::Base->new(1)
 EntityModel::Support::Perl::Base->new('123-456')
 EntityModel::Support::Perl::Base->new([123,456])

=item * Create an object and assign initial values:

 EntityModel::Support::Perl::Base->new({ x => 1, y => 2 })

=back

Any remaining options indicate callbacks:

=over 4

=item * before_commit - just before commit

=item * after_commit - after this has been committed to the database

=item * on_load - when the data has been read from storage

=item * on_not_found - when storage reports that this item is not found

=back

The before_XXX callbacks are also aliased to on_XXX for convenience.

=cut

sub new {
	my $class = shift;
	my $spec = shift || {};
	my %args = @_;

	my %opt;
	my $self = bless {
		_incomplete	=> 1
	}, $class;
	return $self if $args{pending};

# Now we might want to provide some callbacks
	while(my ($k, $v) = each %args) {
		if($k eq 'create') {
			$opt{create} = $v ? 1 : 0;
		} elsif($k ~~ $class->_supported_callbacks) {
			$self->{_callback}->{$k} = $v;
		} else {
			warn "Unknown callback $k requested";
		}
	}

# An arrayref or plain value is used as an ID
	if(!ref($spec) || ref($spec) eq 'ARRAY') {
		$class->_storage->read(
			entity		=> $class->_entity,
			id		=> $spec,
			on_complete	=> sub {
				my $data = shift;
				$self->{$_} = $data->{$_} for keys %$data;
				delete $self->{_incomplete};
				$self->_event('on_load');
			}
		);
# A hashref (possibly empty) means we create a new object with the given values
	} elsif(ref($spec) eq 'HASH') {
		my $data = $class->_spec_from_hashref($spec);
		$self->{$_} = $data->{$_} for keys %$data;
		if($opt{create}) {
			$self->_queue_task(on_create => delete $args{on_complete}) if exists $args{on_complete};
			$self->{ _insert_required } = 1;
			$self->_insert(
				on_complete	=> sub {
					my $data = shift;
					use Data::Dumper;
#					warn "Created " . Dumper($data);
					delete $self->{_incomplete};
					$self->_event('on_create');
				}
			);
		}
	}
	return $self;
}

=head2 _queue_task

Queues a new one-shot task for the given event type.

Supports the following event types:

=over 4

=item * on_load - data has been read from storage

=item * on_create - initial data has been written to storage

=item * on_update - values have been updated, but not necessarily written to storage

=item * on_remove - this entry has been removed from storage

=item * on_not_found - could not find this entry in backend storage

=back

=cut

sub _queue_task {
	my $self = shift;
	while(@_) {
		my ($evt, $task) = splice @_, 0, 2;
		push @{$self->{_task_pending}->{$evt}}, $task;
	}
	return $self;
}

=head2 _event

Pass the given event through to any defined callbacks.

=cut

sub _event {
	my $self = shift;
	my $ev = shift;
	if(my $task = shift @{$self->{_task_pending}->{$ev}}) {
		$task->($self, @_);
	}

	if(exists $self->{_callback}->{$ev}) {
		$_->($self, @_) for @{$self->{_callback}->{$ev}};
	}

# also alias before_XXX to on_XXX
	if($ev =~ /^before_(.*)$/) {
		$ev = "on_$1";
		if(exists $self->{_callback}->{$ev}) {
			$_->($self, @_) for @{$self->{_callback}->{$ev}};
		}
	}
	return $self;
}

=head2 _spec_from_hashref

Private method to generate hashref containing spec information suitable for bless to requested class,
given a hashref which represents the keys/values for the object.

This will flatten any Entity objects down to the required ID key+values.

=cut

sub _spec_from_hashref {
	my $class = shift;
	my $spec = shift;
	my %details;
	foreach my $k (sort keys %$spec) {
		if(ref $spec->{$k} && eval { $spec->{$k}->isa(__PACKAGE__) }) {
			$details{"id$k"} = $spec->{$k}->id;
		} else {
			$details{$k} = $spec->{$k};
		}
		$details{id} = $spec->{$k} if $k eq $class->_entity->primary;
	}
	return \%details;
}

=head2 create

Create a new object.

Takes a hashref, and sets the flag so that ->commit does the insert.

=cut

sub create {
	my $class = shift;
	my $self = $class->new(@_, create => 1);
	$self->commit;
	return $self;
}

sub find {
	my $class = shift;
	my $args = shift || {};

	my %spec = %$args;

# Convert refs to IDs
	foreach my $k (sort keys %spec) {
		$spec{"id$k"} = delete($spec{$k})->id if eval { $spec{$k}->isa(__PACKAGE__); };
	}

	return map { $class->new($_) } $class->_storage->find(
		entity	=> $class->_entity,
		data	=> \%spec,
	);
}

sub iterate {
	my $class = shift;
	my $code = pop;
	my $q = $class->_find_query(@_);
	$q->iterate(sub {
		my $self = $class->new($_[0]);
		$code->($self) if $self;
	});
	return $class;
}

sub _extract_data {
	my $self = shift;
	return {
		map { $_ => $self->$_ } grep { exists $self->{$_} } map { $_->name } $self->_entity->field->list
	};
}

=head2 _update

Write current values back to storage.

=cut

sub _update {
	my $self = shift;
	my %args = @_;

	$self->{_active_write} = 1;
	my $primary = $self->_entity->primary;
	$self->_storage->store(
		entity	=> $self->_entity,
		id	=> $self->id,
		data	=> $self->_extract_data,
		on_complete	=> $self->sap(sub {
			my $self = shift;
			$self->{_active_write} = 0;
		})
	);
	return $self;
}

=head2 _select

Populate this instance with values from the database.

=cut

sub _select {
	my $self = shift;
	my %args = @_;

	my $primary = $self->_entity->primary;
	die "Undef primary element found for $self" if grep !defined, $primary;
return $self;
	my $data = $self->_storage->read(
		entity	=> $self->_entity,
		id	=> $self->id,
	) or return EntityModel::Error->new("Failed to read");
	$self->{$_} = $data->{$_} for keys %$data;
	return $self;
}

=head2 _pending_insert

Returns true if this instance is due to be committed to the database.

=cut

sub _pending_insert { return shift->{_insert_required} ? 1 : 0; }

=head2 _pending_update

Returns true if this instance is due to be committed to the database.

=cut

sub _pending_update { return shift->{_update_required} ? 1 : 0; }

=head2 _insert

Insert this instance into the db.

=cut

sub _insert {
	my $self = shift;
	my %args = @_;
	my $primary = $self->_entity->primary;
	# FIXME haxx
	delete $self->{$primary} unless defined $self->{$primary};

	$self->_storage->create(
		entity	=> $self->_entity,
		data	=> $self->_extract_data,
		on_complete => sub {
			my $v = shift;
			$self->{id} = $v;
			delete $self->{_insert_required};
			$args{on_complete}->($v) if $args{on_complete};
		}
	);
	return $self;
}

=head2 commit

Commit any pending changes to the database.

=cut

sub commit {
	my $self = shift;
	$self->_insert(@_) if $self->_pending_insert;
	$self->_update(@_) if $self->_pending_update;
	return $self;
}

sub done {
	my $self = shift;
	return $self if $self->{failure};
	my $code = shift;
	$code->($self);
	return $self;
}

sub fail {
	my $self = shift;
	return $self unless $self->{failure};
	my $code = shift;
	$code->($self, $self->{failure});
	return $self;
}

sub then {
	my $self = shift;
	$self->commit;
	push @{$self->{_callback}->{on_load}}, @_;
	return $self;
}

=head2 revert

Revert any pending changes to the database.

=cut

sub revert {
	my $self = shift;
	return if $self->_pending_insert;
	return $self->_select(@_);
}

sub waitFor {
	my $self = shift;

}

=head2 id

Primary key (id) for this instance.

=cut

sub id {
	my $self = shift;
	logStack("Self is not an instance?") unless ref $self;
	if(@_) {
		$self->{id} = shift;
		return $self;
	}
	return $self->{id} if exists $self->{id};
	logDebug({%$self});
#	logDebug("Expect from " . $_) foreach $self->_entity->list_primary;
	$self->{id} = join('-', map { $self->{$_} // 'undef' } $self->_entity->primary);
	$self->{$_} = $self->{id} foreach $self->_entity->primary;
#	logDebug("Found ID as " . $self->{id});
	return $self->{id};
}

=head2 fromID

Instantiate from an ID.

=cut

sub fromID {
	my $class = shift;
	my $id = shift;

#	logDebug("Instantiate " . ($id // 'undef'));
	my $self = bless { }, $class;
	$self->{id} = $id;
	$self->{$_} = $id foreach $self->_entity->primary;
	$self->{_incomplete} = 1;
	return EntityModel::Error->new('Permission denied') if $self->can('hasAccess') && !$self->hasAccess('read');
	return $self;
}

sub _request_load {
	my $self = shift;
	my %args = @_;
	if($self->{_incomplete}) {
		$self->_queue_task(
			on_load		=> $args{on_complete}
		) if exists $args{on_complete};
		$self->_queue_task(
			on_error	=> $args{on_error}
		) if exists $args{on_error};
	} else {
		$args{on_complete}->($self) if exists $args{on_complete};
	}
	return $self;
}

=head2 remove

Remove this instance from the database.

=cut

sub remove {
	my $self = shift;
	$self->_storage->remove(
		entity	=> $self->_entity,
		id	=> $self->id
	) or return EntityModel::Error->new("Failed to remove");
	return $self;
}

=head2 _view

Returns the view corresponding to this object.

=cut

sub _view {
	my $self = shift;
	return $self->_viewClass->new(instance => $self) if $self->can('_viewClass');
	return EntityModel::View->new(
		instance	=> $self,
	);
}

sub _paged {
	my $class = shift;
	return EntityModel::Pager->new({
		entity => $class
	});
}

# wrong place?
my %TimestampCache;
tie %TimestampCache, 'Tie::Cache::LRU', 50000;

sub _timeStamp {
	my $self = shift;
	my $fieldName = shift;
	my $v = $self->{$fieldName};
	return undef unless $fieldName && $v;
	return $TimestampCache{$v} if exists $TimestampCache{$v};

	my $ts;
	if($self->{$fieldName} =~ m/^(\d+)-(\d+)-(\d+)[ T](\d+):(\d+):(\d+)(?:\.(\d{1,9}))?/) {
		(my $v = $self->{$fieldName}) =~ tr/ /T/;
		$ts = gmtime POSIX::strptime($v, '%Y-%m-%sT%H:%M:%S');
		$ts .= $1 if $v =~ /(\.\d+)$/;
	}
	$TimestampCache{$v} = $ts;
	return $ts;
}

END { logDebug("Had %d entries in the timestamp cache", (tied %TimestampCache)->curr_size); }

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
