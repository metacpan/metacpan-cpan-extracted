package EntityModel::Model;
{
  $EntityModel::Model::VERSION = '0.102';
}
use EntityModel::Class {
	_isa		=> [qw{Mixin::Event::Dispatch}],
	name		=> { type => 'string' },
	handler		=> { type => 'hash' },
	entity		=> { type => 'array', subclass => 'EntityModel::Entity' },
# Private mapping for entity name lookup
	entity_map	=> { type => 'hash', scope => 'private', watch => {
		entity => 'name'
	} },
};
no if $] >= 5.017011, warnings => "experimental::smartmatch";

=head1 NAME

EntityModel::Model - base class for model definitions

=head1 VERSION

version 0.102

=head1 SYNOPSIS

see L<EntityModel>.

=head1 DESCRIPTION

see L<EntityModel>.



=head1 METHODS

=cut

use List::Util qw(first);

=pod

=cut

sub table {
	my $self = shift;
	my $name = shift;
	my ($e) = first { $_->name eq $name } $self->entity->list;
	return $e;
}

sub entity_by_name {
	my $self = shift;
	my $name = shift;
	return $self->entity_map->{$name};
}

=head2 pending_entities

Returns a list of all pending entities for this model.

These will be applied on L<commit>, or cleared on L<rollback>.

=cut

sub pending_entities {
	my $self = shift;
	my $type = shift || [ 'update', 'add', 'remove' ];
	$type = [ $type ] unless ref $type eq 'ARRAY';
	my @lst;
	foreach my $t (@$type) {
		push @lst, values %{$self->{pending}->{$t}};
	}
	return @lst;
}

=head2 rollback

Revert any pending changes for this model.

=cut

sub rollback {
	my $self = shift;
	undef $self->{pending};
	return $self;
}

=head2 apply_fields

Apply the field definitions for an entity.

=cut

sub apply_fields {
	my $self = shift;
	my $entity = shift;
	local $SIG{__DIE__} = sub {
		logStack("FAILED HERE ===== $_[0]");
		die @_;
	};
	my @fieldList = $self->read_fields($entity);
	foreach my $details (@fieldList) {
		my $field = $entity->new_field($details->{name});
		foreach (sort keys %$details) {
			$field->$_($details->{$_});
		}
		$entity->field->push($field);
	}
	return $self;
}

=head2 load_model

Populate the entity model from any information we can get from
the data source.

=cut

sub load_model {
	my $self = shift;
	$self->entity->clear;

	logDebug("Reading tables");
	my @tableList = $self->read_tables;
	logDebug("Import " . scalar(@tableList) . " tables");
	foreach (@tableList) {
		my $tbl = $self->add_table($_);
		$self->apply_fields($tbl);
	}
	logDebug("Import complete");
	return $self;
}

=head2 update_from

Update this entity model so that it matches the given model.

=cut

sub update_from {
	my ($self, $src) = @_;
	my %srcNames = map { $_->name => $_ } $src->entity->list;
	foreach my $e ($self->entity->list) {
		if(exists $srcNames{$e->name}) {
			my $es = delete $srcNames{$e->name};
# Mark this for update unless it's the same as the one we have already
			if($es->matches($e)) {
				logDebug("Should keep [%s]", $e->name);
			} else {
				logDebug("Should update [%s]", $e->name);
				$self->{pending}->{update}->{$es->name} = $es;
			}
		} else {
			logDebug("Should remove [%s]", $e->name);
			$self->{pending}->{remove}->{$e->name} = $e;
		}
	}
	foreach my $name (sort keys %srcNames) {
		logDebug("Should add [%s]", $name);
		$self->{pending}->{add}->{$name} = $srcNames{$name};
	}
	return $self;
}

=head2 matches

Returns true if this entity model has identical content to another given model.

=cut

sub matches {
	my ($self, $dst) = @_;
	my @srcList = sort { $a->name cmp $b->name } $self->entity->list;
	my @dstList = sort { $a->name cmp $b->name } $dst->entity->list;
	logDebug("Check match: src " . scalar(@srcList) . ", dest " . scalar(@dstList));
	return \@srcList ~~ \@dstList;
}

=head2 read_tables

Virtual method for reading table definitions.

=cut

sub read_tables { }

sub dump  {
	my $self = shift;
	my $out = shift || sub {
		print join(' ', @_) . "\n";
	};

	$out->('Entity list for ' . $self->name);
	foreach (sort { $a->name cmp $b->name } $self->entity) {
		$out->($_->name);
		$_->dump($out);
	}
	$self;
}

sub apply { }

sub pending {
	my $self = shift;
	return @_ ? ($self->{pending} = shift) : $self->{pending};
}

sub hasPending {
	my $self = shift;
	return $self->pending ? 1 : 0;
}

=head2 new_entity

Helper method to create a new entity.

=cut

sub new_entity {
	my $self = shift;
	my $name = shift;

	my $entity = EntityModel::Entity->new($name);
	return $entity;
}

=head2 create_entity

Helper method to create a new entity and add it to our list.

Takes the following parameters:

=over 4

=item *

=back

Returns

=cut

sub create_entity {
	my $self = shift;
	$self->add_entity(EntityModel::Entity->new(@_))
}

=head2 add_table

Generate an appropriate L<EntityModel::Entity> for the given table name.

=cut

sub add_table {
	my ($self, $tbl) = @_;
	my $entity = $self->new_entity($tbl->{name});
	my @fieldList = $self->read_fields($entity);
	my @primaryList = $self->read_primary($entity);
	logDebug("Import " . scalar(@fieldList) . " fields for " . $tbl->{name});
	my %fieldName;
	foreach (@fieldList) {
		my $name = delete $_->{name};
#		logDebug("Set $name");
		$fieldName{ $name } = $entity->new_field($name, $_);
	}
	$entity->primary(join('-', @primaryList)) if @primaryList;
	# logDebug("Primary for $_ is " . $_->name) foreach $entity->list_primary;
	$self->entity->push($entity);
	return $entity;
}

=head2 add_entity

Add an L<EntityModel::Entity> to this model.

=cut

sub add_entity {
	my $self = shift;
	my $entity = shift;
	$self->entity->push($entity);
	return $self;
}

sub resolve_entity_dependencies {
	my $self = shift;
	foreach my $entity ($self->entity->list) {
		my @deps = grep { $_->refer } $entity->field->list;
		$_->refer->entity($self->entity_by_name($_->refer->table)) foreach @deps;
	}
	return $self;
}

=head2 commit

Apply the actions, starting with the longest names first for removal, and shortest
first for update and create.

=cut

sub commit {
	my $self = shift;

	logDebug("Commit $self");
	$self->commit_pending_remove;
	$self->commit_pending_add;
	$self->commit_pending_update;
	delete $self->{pending};
# Don't really want to commit here, since having everything in an uncommitted transaction can be useful.
#	$self->postCommit if $self->can('postCommit');
	return $self->load_model;
}

=head2 commit_pending_update

=cut

sub commit_pending_update {
	my $self = shift;
	logInfo("Update " . join(',', map { $_->name } $self->pending_entities('update')));
	$self->update_table($_) foreach $self->pending_entities('update');
	return $self;
}

=head2 commit_pending_remove

=cut

sub commit_pending_remove {
	my $self = shift;
	logInfo("Remove " . join(',', map { $_->name } $self->pending_entities('remove')));
	$self->remove_table($_) foreach $self->pending_entities('remove');
	return $self;
}

=head2 commit_pending_add

Add all pending items, ordering to resolve dependencies as required.

=cut

sub commit_pending_add {
	my $self = shift;
	logInfo("Create " . join(',', map { $_->name } $self->pending_entities('add')));
	my @pending = $self->pending_entities('add');
	ITEM:
	while(@pending) {
		my $e = shift(@pending);
		# TODO Not hugely efficient, perhaps could do with a profile run here?
		my @deps = map { $_->name } $e->dependencies;
		my @pendingNames = map { $_->name } @pending;
		my @unsatisfied = grep { $_ ~~ @deps } @pendingNames;
		my @existing = map { $_->name } $self->entity->list;
		# Include current entity in list of available entries, so that we can allow self-reference
		my @unresolved = grep { !($_ ~~ [@pendingNames, @existing, $e->name]) } @deps;
		if(@unresolved) {
			logError("%s unresolved (pending %s, deps %s for %s)", join(',', @unresolved), join(',', @pendingNames), join(',', @deps), $e->name);
			die "Dependency error";
		}
		if(@unsatisfied) {
			logInfo("%s has %d unsatisfied deps, postponing: %s", $e->name, scalar @unsatisfied, join(',',@unsatisfied));
			push @pending, $e;
			next ITEM;
		}
		$self->create_table($e);
	}
	return $self;
}

sub remove_entity { shift->remove_table(@_) }

sub remove_table {
	my $self = shift;
	my $tbl = shift;
	logDebug("Remove table " . $tbl->name);
	$self->entity->remove(sub { $_[0]->name ne $tbl->name });
	return $self;
}

sub create_table {
	my $self = shift;
	my $tbl = shift;
	logDebug("Create table " . $tbl->name);
	$self->entity->push($tbl);
	return $self;
}

sub update_table {
	my $self = shift;
	my $src = shift;
	my ($e) = grep { $_->name eq $src->name } $self->entity->list;
	logDebug("Found table [%s] for [%s]", $e->name, $src->name);
	my $dst = $self->entity_map->get($src->name);
	logDebug("Update table [%s], dest has fields: [%s]", $src->name, join(',', map { $_->name // "undef" } $dst->field->list));
	my @add = grep { !$dst->field_map->get($_->name) } $src->field->list;
	logDebug("Want to add [%s]", join(',', map { $_->name } @add));
	$self->add_field_to_table($dst, $_) foreach @add;
	return $self;
}

=head2 add_field_to_table

=cut

sub add_field_to_table {
	my $self = shift;
	my $entity = shift;
	my $field = shift;
	$entity->field->push($field->clone);
	return $self;
}

sub handler_for {
	my $self = shift;
	my $name = shift;
	logDebug("Check for handlers for [%s] node", $name);
	return;
}

sub provide_handler_for {
	my $self = shift;
	my @args = @_;
	while(@args) {
		my $k = shift(@args);
		my $v = shift(@args);
		$self->handler->set($k, $v);
	}
	return $self;
}

sub handle_item {
	my $self = shift;
	my %args = @_;
	if(my $code = $self->handler->get($args{item})) {
		logDebug("Handling [%s] with plugin", $args{item});
		$code->($self, item => $args{item}, data => $args{data});
	} else {
		logError("No handler for [%s]", $args{item});
	}
	return $self;
}

sub flush {
	my $self = shift;
	$self->commit;
}

=head2 DESTROY

Notify when there are pending uncommitted entries.

=cut

sub DESTROY {
	my $self = shift;
	if($self->hasPending) {
		logError("Had pending commits for $self");
	}
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
