package EntityModel::Support::Perl;
{
  $EntityModel::Support::Perl::VERSION = '0.102';
}
use EntityModel::Class {
	_isa		=> [qw{EntityModel::Support}],
	namespace	=> { type => 'string' },
	baseclass	=> { type => 'string' },
	model		=> { type => 'EntityModel::Model' },
};
no if $] >= 5.017011, warnings => "experimental::smartmatch";

=head1 NAME

EntityModel::Support::Perl - language support for L<EntityModel>

=head1 VERSION

version 0.102

=head1 SYNOPSIS

See L<EntityModel>.

=head1 DESCRIPTION

Generate Perl packages and methods based on an entity model definition.
See L<EntityModel>.

=head1 ASYNCHRONOUS MODE

See L<EntityModel::Support::PerlAsync>.

=head1 METHODS

=cut

use Symbol ();
use Module::Load ();
use Scalar::Util ();
use POSIX ();

=head2 setup

=cut

sub setup {
	my $self = shift;
	my $def = shift;
	logDebug("Trying [%s] with [%s]", $self, $def);
	$self->namespace(exists $def->{namespace} ? delete $def->{namespace} : 'Entity');
	$self->baseclass(exists $def->{baseclass} ? delete $def->{baseclass} : 'EntityModel::Support::Perl::Base');

	$self->ensure_loaded($self->baseclass);
	return $self;
}

sub apply_model {
	my $self = shift;
	my $model = shift;
	$self->model($model);
# FIXME Need a better way to link storage instances to entities.
	return $self->SUPER::apply_model($model);
}

=head2 apply_entity

=cut

sub apply_entity {
	my $self = shift;
	my $entity = shift;

	logDebug("Create table " . $entity->name);
	$self->load_package($self->package_name($entity) => $entity);
	$self->create_field($entity, $_) foreach $entity->field->list;

# With 3 references, we currently don't really know what to do, so bail out for now
	my @ref = grep { $_->refer } $entity->field->list;
	die qq{Too many references to handle\nThis module currently only handles 1:1, 1:N and N:M,\nso an entity with more than 3 external references\nneeds to have the relationships specified explicitly.} if @ref > 2;

# Create a back collection for each reference
	foreach my $ref (@ref) {
		my $r = $ref->refer->entity;
		my $f = $r->field_map->{$ref->refer->field} or die "no field found";
		$self->back_link(
			src => {
				entity	=> $r,
				field	=> $f
			},
			dst => {
				entity	=> $entity,
				field	=> $ref
			}
		);
	}

# 2 references usually means we have an N:M relationship, so create 2-way collections
	if(@ref == 2) {
		my $src = {
			entity	=> $ref[0]->refer->entity,
			field	=> $ref[0]->refer->entity->field_map->{$ref[0]->refer->field},
		};
		my $dst = {
			entity	=> $ref[1]->refer->entity,
			field	=> $ref[1]->refer->entity->field_map->{$ref[1]->refer->field},
		};
		$self->cross_link(join_table => $entity, src => $src, dst => $dst);
		$self->cross_link(join_table => $entity, src => $dst, dst => $src);
	}

	return $self;
}

sub back_link {
	my $self = shift;
	my %args = @_;

# Need to make method on the source entity which does a ->find on the destination
	my $pkg = $self->package_name($args{src}->{entity});
	my $method = $args{dst}->{entity}->name;
	my $target = $self->package_name($args{dst}->{entity});
	my $search_field = $args{dst}->{field}->name;
	my $code = sub {
		my $self = shift;
		EntityModel::Array->new([ $target->find({ $search_field => $self->id }) ]);
	};
	my $sym = join('::', $pkg, $method);
	my $exists = eval { $pkg->can($sym) };
	{ no strict 'refs'; *$sym = $code unless $exists; }
	logDebug("Created [%s] for [%s] as a back link, previous [%s]", $sym, $pkg, $exists // 'not found');
	return $self;
}

sub cross_link {
	my $self = shift;
	my %args = @_;

# Need to make method on the source entity which does a ->find on the destination
	my $pkg = $self->package_name($args{src}->{entity});
	my $method = $args{dst}->{entity}->name;
	my $target = $self->package_name($args{dst}->{entity});
	my $search_field = $args{src}->{field}->name;
	my $pri = $args{dst}->{field}->name;
	my $join = $self->package_name($args{join_table});
	my $code = sub {
		my $self = shift;
		EntityModel::Array->new([
			map { $target->new($_->$pri) } $join->find({ $search_field => $self->id })
		]);
	};
	my $sym = join('::', $pkg, $method);
	{ no strict 'refs'; *$sym = $code unless eval { $pkg->can($sym) }; }
	return $self;
}

=head2 ensure_loaded

=cut

sub ensure_loaded {
	my $self = shift;
	my $class = shift;
	Module::Load::load($class) unless eval { $class->can('new') };
	return $self;
}

=head2 package_name

Generate the package name string from the given entity.

=cut

sub package_name {
	my ($self, $entity) = @_;
	logStack("No entity?") unless $entity; # don't think this should ever happen but if it's really a fault other stuff will break anyway!
	my $name = ref($entity) ? $entity->name : $entity;

	logDebug("Get package name for [%s] with namespace [%s]", $name, $self->namespace);
	return $self->namespace unless $entity;

	return join('::', $self->namespace, map {
		ucfirst($_)
	} split('_', $name));
}

=head2 entity_name

Generate the entity name string from the given package name.

=cut

sub entity_name {
	my ($self, $pkg) = @_;
	$pkg =~ s/^\Q$self->namespace\E:://;

	return join('_', map {
		lc($_)
	} split(/::/, $pkg));
}

=head2 create_field

Create new field for the given entity.

=cut

sub create_field {
	my ($self, $entity, $field) = @_;

	my $pkg = $self->package_name($entity);
	my $k = join('::', $pkg, $field->name);
	logDebug("Create accessor [%s] on [%s]", $field->name, $pkg);

	given($field) {
		when($_->type eq 'timestamp') {
# Timestamp has some formatting / validation additions
			my $accessor = $self->accessor('timestamp', $entity, $field);
			{ no strict 'refs'; *{$k} = $accessor; }
		}
		when($_->refer) {
# Regular ID column access
			my $accessor = $self->accessor('default', $entity, $field);
			{ no strict 'refs'; *{$k} = $accessor; }

# And also provide an accessor which instantiates the object, with the id prefix removed from the fieldname
			$accessor = $self->accessor('ref', $entity, $field);
			$k =~ s/::\Kid([^:]+)$/$1/;
			{ no strict 'refs'; *{$k} = $accessor; }
			logDebug("Accessor for %s on %s hits %s", $k, $entity->name, $field->name);
		}
		default {
			my $accessor = $self->accessor('default', $entity, $field);
			{ no strict 'refs'; *{$k} = $accessor; }
		}
	}

	return $self;
}

=head2 recurse_packages

EntityModel::ObjectBase::Test -> test
EntityModel::ObjectBase::Test::One -> test_one
EntityModel::ObjectBase::Test::Two -> test_two

=cut

sub recurse_packages {
	my ($self, $prefix, $sub) = @_;
	my $pkg = $self->package_name($prefix);

	my @pkgKeys;
	{ no strict 'refs'; @pkgKeys = keys %{$pkg . '::'}; }

	logInfo("Recurse for [%s]", $prefix);
	foreach my $k (@pkgKeys) {
		logInfo("Got [%s]", $k);
		if($k =~ /^(.*)::$/) {
			my $tbl = $self->entity_name($prefix ? $prefix . '_' . $1 : $1);
			$sub->($tbl) if $tbl;
			$self->recurse_packages($tbl, $sub);
		}
	}
}

=head2 load_package

=cut

sub load_package {
	my $self = shift;
	my $pkg = shift;
	my $entity = shift;

	my @primaryKeys = 'id';
	my $entity_name = $entity->name;
	logInfo("Load package for [%s]", $pkg);

	my ($storage) = $self->model->storage->list;
	die "no storage?" unless $storage;

	try {
		local $SIG{__DIE__};
		Module::Load::load($pkg);

		unless(eval { $pkg->isa($self->baseclass); }) {
			# Doesn't inherit as expected, add the base module anyway
			no strict 'refs';
			push @{$pkg . '::ISA'}, $self->baseclass;
		}
	} catch {
		logWarning("Failed: [%s]", $_) unless /^Can't locate /;

		# Couldn't read the module - either invalid, or missing. Create it.
		no strict 'refs';
		push @{$pkg . '::ISA'}, $self->baseclass;
	};

	{
		no strict 'refs';
		*{$pkg . '::()'} = sub () { } unless *{ $pkg . '::()' };

		# Apply default string representation
		*{ $pkg . '::(""' } = sub {
			my $self = shift;
			ref($self) . '(' . $self->id . ')';
		} unless *{ $pkg . '::(""' };

		# List of primary keys
		*{ $pkg . '::_primary' } = sub () { @primaryKeys; }
		 unless eval { $pkg->can('_primary') };
		# Table
		*{ $pkg . '::_entity' } = sub () { $entity; }
		 unless eval { $pkg->can('_entity') };

		*{ $pkg . '::_storage' } = sub () { $storage; }
		 unless eval { $pkg->can('_storage') };
	}
}

sub accessor {
	my $self = shift;
	my $type = shift;
	return $self->timestamp_accessor(@_) if $type eq 'timestamp';
	return $self->ref_accessor(@_) if $type eq 'ref';
	return $self->default_accessor(@_);
}

=head2 default_accessor

Regular accessor.

=over 4

=item * $entity - L<EntityModel::Entity>

=item * $field - L<EntityModel::Field>

=back

Returns a coderef which can act as an accessor, e.g. $ref->($self, $value).

=cut

sub default_accessor {
	my $self = shift;
	my ($entity, $field) = @_;

	my $keyName = $field->name;

	return sub {
		my $self = shift;

		if(@_) {
			my $v = shift;
			$self->{ $keyName } = $v;
			$self->{ _update_required } = 1;
			$self->commit;
			return $self;
		}

# Populate where required
		$self->_select(key => $keyName) if $self->{_incomplete} && !exists($self->{ $keyName });

		return $self->{ $keyName };
	};
}

=head2 timestamp_accessor

Accessor for timestamp values.

=over 4

=item * $entity - L<EntityModel::Entity>

=item * $field - L<EntityModel::Field>

=back

Returns a coderef which can act as an accessor, e.g. $ref->($self, $value).

Accessor accepts the following input formats:

=over 4

=item * DateTime - a L<DateTime> object (or subclassed variant)

=item * Epoch time - numeric value containing seconds since epoch

=item * String - standard date/time string in ISO8601 format.

=back


=cut

sub timestamp_accessor {
	my $self = shift;
	my ($entity, $field) = @_;

	my $field_name = $field->name;
	my $keyName = $field->name;
	my $fieldType = $field->type;
	my $fieldRefer = undef;

	return sub {
		my $self = shift;

		if(@_) {
			my $v = shift;
			if(defined $v) {
				if(Scalar::Util::blessed($v) && $v->isa('DateTime')) {
					$v = sprintf "%s.%09d", $v->iso8601, $v->nanosecond;
				} else {
					$v = POSIX::strftime('%Y-%m-%dT%H:%M:%S', gmtime $v) if $v =~ /^\d+(\.\d*)?$/;
					$v .= substr sprintf('%11.9f', $1), 1 if $1;
				}
			}
			$self->{ $keyName } = $v;
			$self->{ _update_required } = 1;
			$self->commit;
			return $self;
		}

# Populate where required
		$self->_select(key => $keyName) if $self->{_incomplete} && !exists($self->{ $keyName });

		return $self->_timeStamp($field_name);
	};
}

=head2 ref_accessor

Accessor for reference fields.

=over 4

=item * $entity - L<EntityModel::Entity>

=item * $field - L<EntityModel::Field>

=back

Returns a coderef which can act as an accessor, e.g. $ref->($self, $value).

=cut

sub ref_accessor {
	my $self = shift;
	my ($entity, $field) = @_;

	my $field_name = $field->name;
	my $keyName = $field_name;
	my $fieldType = $field->type;
	my $refEntity = $field->refer->entity;
	my $refpkg = $self->package_name($refEntity->name);
	my $rf = $field->refer->field;

# Return an accessor which instantiates this class if set
	return sub {
		my $self = shift;

		if(@_) {
			my $v = shift;
			$self->{ $keyName } = $v->id;
			$self->{ _update_required } = 1;
			return $self;
		}

		# First check whether we're complete and so have some value for the ID (could be undef)
		my $target;
		if(exists $self->{$keyName}) {
			# Return a NULL version of the target class if we know that we're dealing with NULL in the
			# foreign key. We don't just pass back undef, since we want to support chained methods.
			return $refpkg->new({ }, null => 1) unless defined $self->{$keyName};

			# We have an ID, so we'll use this to instantiate the object. With luck, we have it cached
			# or readily available so this instantiation should be relatively cheap. If not, we'll queue
			# a storage pull request.
			$target = $refpkg->new($self->{ $keyName });
		} else {
			# If we're incomplete and don't have the ID for this, we'll queue a completion request on $self,
			# and instantiate the target class in a way that allows us to populate with ID when we have it.
			$target = $refpkg->new({
			}, pending => 1);

			$self->_request_load(
				on_complete	=> $self->sap(sub {
					my $self = shift;
					$target->id($self->{ $keyName });
					$target->_request_load;
				}),
				on_error	=> sub { die "some error occurred and we are not sure what to do about it"; }
			);
		}
		return $target;
	};
}


1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
