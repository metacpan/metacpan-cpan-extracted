package EntityModel::Definition;
{
  $EntityModel::Definition::VERSION = '0.102';
}
use EntityModel::Class {
	model => { type => 'EntityModel::Model' },
};
no if $] >= 5.017011, warnings => "experimental::smartmatch";

=head1 NAME

EntityModel::Definition - definition support for L<EntityModel>

=head1 VERSION

version 0.102

=head1 SYNOPSIS

See L<EntityModel>.

=head1 DESCRIPTION

See L<EntityModel>.

=head1 METHODS

=cut

=head2 load

Generic load method, passing file or string to the appropriate L</load_file> or L</load_string> methods.

=cut

sub load {
	my $self = shift;
	my %args = @_;

	my $src = delete $args{source};
	my ($k, $v);
	if(ref $src ~~ 'HASH') {
		($k, $v) = %$src;
	} elsif(ref $src ~~ 'ARRAY') {
		($k, $v) = @$src;
	} else {
		$k = $src;
	}
	logDebug("Trying [%s] as [%s] => [%s]", $self, $k, $v);
	die 'Nothing passed' unless defined $k;

	my $structure;
	$structure ||= $self->load_file($v) if $k eq 'file' && defined $v;
	$structure ||= $self->load_string($v) if $k eq 'string' && defined $v;

# Support older interface - single parameter, scalarref for string, plain scalar for XML filename
	$structure ||= $self->load_file($k) if !ref($k) && !$v;
	$structure ||= $self->load_string($$k) if ref($k) && !$v;
	die 'Unable to load ' . $self . " from [$k] and [$v]" unless $structure;
	return $self->apply_model_from_structure(
		model		=> $args{model},
		structure	=> $structure
	);
}

=head2 save

Generic save method, passing file or string to the appropriate L</save_file> or L</save_string> methods.

=cut

sub save {
	my $self = shift;
	my %args = @_;

	my $target = delete $args{target};
	my ($k, $v);
	if(ref $target ~~ 'HASH') {
		($k, $v) = %$target;
	} elsif(ref $target ~~ 'ARRAY') {
		($k, $v) = @$target;
	} else {
		$k = shift;
	}
	logDebug("Trying [%s] as [%s] => [%s]", $self, $k, $v);
	die 'Nothing passed' unless defined $k;

	my %data = (
		model => $self->model,
	);
	return $self->save_file(
		target => $v,
		%data
	) if $k eq 'file' && defined $v;
	return $self->save_string(
		output => 'string',
		%data
	) if $k eq 'string';

	die 'Unable to save ' . $self . " from [$k] and [$v]";
	return $self;
}

=head2 field_structure

=cut

sub field_structure {
	my ($self, $field) = @_;
	return {
		name	=> $field->name,
		type	=> $field->type,
	};
}

=head2 entity_structure

=cut

sub entity_structure {
	my ($self, $entity) = @_;
	return {
		name	=> $entity->name,
		primary	=> $entity->primary,
		field	=> [ map $self->field_structure($_), $entity->field->list ],
	}
}

=head2 structure_from_model

Return a hashref representing the given model.

=cut

sub structure_from_model {
	my ($self, $model) = @_;
	return {
		name => $model->name,
		entity => [
			map $self->entity_structure($_), $model->entity->list
		],
	};
}

=head2 apply_model_from_structure

Applies a definition (given as a hashref) to generate or update a model.

=cut

sub apply_model_from_structure {
	my $self = shift;
	my %args = @_;
	my $model = delete $args{model};
	my $definition = delete $args{structure};

	if(my $name = delete $definition->{name}) {
		$model->name($name);
	}

	if(my $entity = delete $definition->{entity}) {
		my @entity_list = @$entity;
		$self->add_entity_to_model(
			model	=> $model,
			definition => $_
		) foreach @$entity;
	}
	foreach my $k (sort keys %$definition) {
		$model->handle_item(
			item	=> $k,
			data	=> $definition->{$k}
		);
	}
	$model->resolve_entity_dependencies;
	return $self;
}

=head2 add_entity_to_model

Create a new entity and add it to the given model.

=cut

sub add_entity_to_model {
	my $self = shift;
	my %args = @_;

	my $model = delete $args{model};
	my $def = delete $args{definition};
	my $entity = EntityModel::Entity->create_from_definition($def);
	$model->add_entity($entity);
	return $self;
}

=head2 register

Empty default method, implemented by subclasses to register themselves with the model.

=cut

sub register { }

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2012. Licensed under the same terms as Perl itself.
