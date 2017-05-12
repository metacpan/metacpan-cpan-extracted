package EntityModel::Storage::Perl;
{
  $EntityModel::Storage::Perl::VERSION = '0.102';
}
use EntityModel::Class {
	_isa		=> [qw{EntityModel::Storage}],
};
no if $] >= 5.017011, warnings => "experimental::smartmatch";

=head1 NAME

EntityModel::Storage::Perl - backend storage interface for L<EntityModel>

=head1 VERSION

version 0.102

=head1 SYNOPSIS

See L<EntityModel>.

=head1 DESCRIPTION

See L<EntityModel>.

This does not really qualify as a 'storage' module, since it's intended purely for use in
testing, providing an ephemeral backing store for entities which will disappear on program
termination.

=cut

use List::MoreUtils qw(all);

# Used for holding any entities that have been created
my %EntityMap;

# Max ID information, used for sequences
my %EntityMaxID;

=head1 METHODS

=cut

=head2 setup

=cut

sub setup {
	my $self = shift;
	$self->add_handler_for_event(
		backend_ready => sub {
			my $self = shift;
			$self->{backend_ready} = 1;
			0 # one-shot
		}
	);
#	my %args = %{+shift};
	$self->invoke_event(backend_ready =>);
	return $self;
}

=head2 apply_entity

Set up this entity in storage, by adding it to the list of keys and clearing the existing max_id.

=cut

sub apply_entity {
	my $self = shift;
	my $entity = shift;
	my %args = @_;
	die "Entity exists already: " . $entity->name if exists $EntityMap{$entity->name};

	$self->entity->push($entity);
	$EntityMap{$entity->name} = {
		entity	=> $entity,
		max_id	=> 0,
	};
	$args{on_complete}->() if exists $args{on_complete};
	return $self;
}

=head2 read_primary

Get the primary keys for a table.

=cut

sub read_primary {
	my $self = shift;
	my $entity = shift;
	return $EntityMap{$entity->name}->{entity}->primary->list;
}

=head2 read_fields

Read all fields for a given entity.

=cut

sub read_fields {
	my $self = shift;
	my $entity = shift;
	return $EntityMap{$entity->name}->{entity}->field->list;
}

=head2 table_list

Get a list of all the existing tables in the schema.

=cut

sub table_list {
	my $self = shift;
	return map { $_->{entity} } values %EntityMap;
}

=head2 field_list

Returns a list of all fields for the given table.

=cut

sub field_list {
	my $self = shift;
	my $entity = shift;
	return $EntityMap{$entity->name}->{entity}->field->list;
}

=head2 read

Reads the data for the given entity and returns hashref with the appropriate data.

Parameters:

=over 4

=item * entity - L<EntityModel::Entity>

=item * id - ID to read data from

=back

Callbacks (included in parameter list above):

=over 4

=item * on_complete - called when the value has been read, includes the value

=back

=cut

sub read {
	my $self = shift;
	my %args = @_;
	die "Entity not found" unless exists $EntityMap{$args{entity}->name};
	my $v = $EntityMap{$args{entity}->name}->{store}->{$args{id}};
	$args{on_complete}->($v) if exists $args{on_complete};
	return $v;
}

=head2 _next_id

Returns the next ID for the given entity. Not intended to be called outside this package;
returns the value immediately rather than asynchronously.

=cut

sub _next_id {
	my $self = shift;
	my %args = @_;
	die "Entity " . $args{entity}->name . " not found, we have: " . join(',', sort keys %EntityMap) unless exists $EntityMap{$args{entity}->name};
	$EntityMaxID{$args{entity}->name} ||= 0;
	return ++$EntityMaxID{$args{entity}->name};
}

=head2 create

Creates new entry for the given L<EntityModel::Entity>.

Parameters:

=over 4

=item * entity - L<EntityModel::Entity>

=item * data - actual data values

=back

Callbacks (included in parameter list above):

=over 4

=item * on_complete - called when the value has been created, will be passed the assigned ID

=back

=cut

sub create {
	my $self = shift;
	my %args = @_;
	my $id = $self->_next_id(%args);
	$args{id} = $id;
	$args{data} = {
		%{$args{data}},
		$args{entity}->primary => $id
	};
	$self->store(%args);
	$args{on_complete}->($id) if exists $args{on_complete};
	return $id;
}

=head2 store

Stores data to the given entity and ID.

Parameters:

=over 4

=item * entity - L<EntityModel::Entity>

=item * id - ID to store data to

=item * data - actual data values

=back

Callbacks (included in parameter list above):

=over 4

=item * on_complete - called when the value has been stored, will be passed the assigned ID

=back

=cut

sub store {
	my $self = shift;
	my %args = @_;
	die "Entity not found" unless exists $EntityMap{$args{entity}->name};
	die "No ID given" unless defined $args{id};

	$EntityMap{$args{entity}->name}->{store}->{$args{id}} = $args{data};
	$args{on_complete}->($args{id}) if exists $args{on_complete};
	return $self;
}

=head2 remove

Removes given ID from storage.

Parameters:

=over 4

=item * entity - L<EntityModel::Entity>

=item * id - ID to store data to

=back

Callbacks (included in parameter list above):

=over 4

=item * on_complete - called when the value has been removed

=back

=cut

sub remove {
	my $self = shift;
	my %args = @_;
	die "Entity not found" unless exists $EntityMap{$args{entity}->name};
	delete $EntityMap{$args{entity}->name}->{store}->{$args{id}};
	$args{on_complete}->($args{id}) if exists $args{on_complete};
	return $self;
}

=head2 find

Callbacks (included in parameter list above):

=over 4

=item * on_item - called for each item

=item * on_not_found - called once if no items were found

=item * on_complete - called when no more items are forthcoming (regardless of whether any
were found or not)

=back

=cut

sub find {
	my $class = shift;
	my %args = @_;

	my @rslt;
	my $seen = 0;
	ENTRY:
	foreach my $entry (sort values %{$EntityMap{$args{entity}->name}->{store}}) {
		next ENTRY unless all { $entry->{$_} ~~ $args{data}->{$_} } keys %{$args{data}};
		++$seen;
		$args{on_item}->($entry) if exists $args{on_item};
		push @rslt, $entry;
	}
	$args{on_not_found}->() if !$seen && exists $args{on_not_found};
	$args{on_complete}->() if exists $args{on_complete};
	return @rslt;
}

=head2 adjacent

Returns the adjacent values for the given ID.

Callbacks (included in parameter list above):

=over 4

=item * on_prev - called with the value of the previous item

=item * on_next - called with the value of the next item

=item * on_complete - called when both next and previous values have been identified

=back

=cut

sub adjacent {
	my $self = shift;
	my %args = @_;
	die "Entity not found" unless exists $EntityMap{$args{entity}->name};

	my $entity = $args{entity};
	my $id = $args{id};

# Inefficient? Sure. You shouldn't be using this module in production code anyway.
	my ($prev) = reverse grep {
		$_ < $id
	} sort keys %{$EntityMap{$entity->name}->{store}};
	my ($next) = grep {
		$_ > $id
	} sort keys %{$EntityMap{$entity->name}->{store}};

	$args{on_prev}->($prev) if exists $args{on_prev};
	$args{on_next}->($next) if exists $args{on_next};
	$args{on_complete}->($prev, $next) if exists $args{on_complete};
	return ($prev, $next);
}

=head2 outer

Returns the first and last values for the given ID.

Callbacks (included in parameter list above):

=over 4

=item * on_first - called with the value of the previous item

=item * on_last - called with the value of the next item

=item * on_complete - called when both next and previous values have been identified

=back

=cut

sub outer {
	my $self = shift;
	my %args = @_;
	my $entity = $args{entity};
	die "Entity not found" unless exists $EntityMap{$entity->name};

	my ($first, $last) = (sort keys %{$EntityMap{$entity->name}->{store}})[0,-1];
	$args{on_first}->($first) if exists $args{on_first};
	$args{on_last}->($last) if exists $args{on_last};
	return ($first, $last);
}

sub dump {
	my $self = shift;
	use Data::Dumper;
	warn Dumper \%EntityMap;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
