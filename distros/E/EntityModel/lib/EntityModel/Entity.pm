package EntityModel::Entity;
{
  $EntityModel::Entity::VERSION = '0.102';
}
use EntityModel::Class {
	name		=> { type => 'string' },
	'package'	=> { type => 'string' },
	type		=> { type => 'string' },
	description	=> { type => 'string' },
	primary		=> { type => 'string' },
	keyfield	=> { type => 'EntityModel::Field' },
	constraint	=> { type => 'array', subclass => 'EntityModel::Entity::Constraint' },
	field		=> { type => 'array', subclass => 'EntityModel::Field' },
	field_map	=> { type => 'hash', scope => 'private', watch => { field => 'name' } },
};
no if $] >= 5.017011, warnings => "experimental::smartmatch";

use overload '""' => sub { 'entity:' . shift->name }, fallback => 1;

=head1 NAME

EntityModel::Entity - entity definition for L<EntityModel>

=head1 VERSION

version 0.102

=head1 SYNOPSIS

See L<EntityModel>.

=head1 DESCRIPTION

See L<EntityModel>.

=head1 METHODS

=cut

=head2 new

Creates a new entity with the given name.

=cut

sub new_from_name {
	my $class = shift;
	my $name = shift;
	return bless { name => $name }, $class;
}

=head2 new

Instantiates a new object.

Takes the following parameters:

=over 4

=item * name - the name to apply to this entity

=item * field - an arrayref defining the field structure, see L<EntityModel::Field/new> for
more information on the expected format here.

=item * primary - which field(s) to use as the primary key, as a string or arrayref

=item * auto_primary (optional) - automatically create an appropriate
primary key and sequence

=item * type (optional) - type information, currently unused

=back

Returns the new instance

For backwards-compatibility reasons, when called with a single parameter
this will have the same effect as the L</new_from_name> method.
Use of this interface is strongly discouraged in new code, since it is
likely to be deprecated in the near future.

=cut

sub new {
	my $class = shift;
	# Support the deprecated ->new('name') interface
	return $class->new_from_name(@_) if @_ == 1;

	my %args = @_;
	my $self = bless { }, $class;

	$self->name(delete $args{name});
	my @fields = @{delete $args{field} || []};
	my $primary = delete $args{primary};
	if($args{auto_primary}) {
		unshift @fields, {
			name => $primary = 'id' . $self->name,
			type => 'bigserial',
		};
	}
	$self->add_field(EntityModel::Field->new(%$_)) for @fields;
	$self->primary($primary);
	$self->keyfield(delete $args{keyfield}) if exists $args{keyfield};
	$self
}

=head2 new_field

Helper method to create a new field.

=cut

sub new_field {
	my $self = shift;
	my $name = shift;
	my $param = shift || { };

	my $field = EntityModel::Field->new({ %$param, name => $name });
	return $field;
}

=head2 dependencies

Report on the dependencies for this entity.

Returns a list of L<EntityModel::Entity> instances required for this entity.

=cut

sub dependencies {
	my $self = shift;
	return map { $_->refer->entity } grep { $_->refer } $self->field->list;
}

=head2 matches

Returns true if this entity has identical content to another L<EntityModel::Entity>.

=cut

sub matches {
	my ($self, $dst) = @_;
	die "Not an EntityModel::Entity" unless $dst->isa('EntityModel::Entity');

	return 0 if $self->name ne $dst->name;
	return 0 if $self->field->count != $dst->field->count;
	return 0 unless $self->primary ~~ $dst->primary;

	my @srcF = sort { $a->name cmp $b->name } $self->field->list;
	my @dstF = sort { $a->name cmp $b->name } $dst->field->list;
	while(@srcF && @dstF) {
		my $srcf = shift(@srcF);
		my $dstf = shift(@dstF);
		return 0 unless $srcf && $dstf;
		return 0 unless $srcf->name eq $dstf->name;
	}
	return 0 if @srcF || @dstF;
	return 1;
}

sub dump {
	my $self = shift;
	my $out = shift || sub {
		print join(' ', @_) . "\n";
	};

	$self;
}

sub asString { shift->name }

=head2 create_from_definition

Create a new L<EntityModel::Entity> from the given definition (hashref).

=cut

sub create_from_definition {
	my $class = shift;
	my $def = shift;
	my $self = $class->new(delete $def->{name});

	if(my $field = delete $def->{field}) {
		$self->add_field(EntityModel::Field->create_from_definition($_)) foreach @$field;
	}

# Apply any remaining parameters
	$self->$_($def->{$_}) foreach keys %$def;
	return $self;
}

=head2 add_field

Add a new field to this entity.

=cut

sub add_field {
	my $self = shift;
	my $field = shift;
	$self->field->push($field);
	return $self;
}

=head2 field_by_name

Returns the L<EntityModel::Field> matching the given name.

Takes $name as a single parameter.

Returns undef if not found.

=cut

sub field_by_name { my $self = shift; my $name = shift; shift->field_map->{$name} }

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
