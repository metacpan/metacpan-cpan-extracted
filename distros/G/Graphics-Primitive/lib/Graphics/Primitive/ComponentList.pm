package Graphics::Primitive::ComponentList;
use Moose;
use MooseX::Storage;

with Storage (format => 'JSON', io => 'File');

has 'components' => (
    traits => ['Array'],
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] },
    handles => {
        'component_count' => 'count',
        'get_component' => 'get',
        'push_components' => 'push',
        'set_component' => 'set',
    },
);

has 'constraints' => (
    traits => ['Array'],
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] },
    handles => {
        'constraint_count' => 'count',
        'get_constraint' => 'get',
        'push_constraints' => 'push',
        'set_constraint' => 'set',
    },
);


sub add_component {
    my ($self, $component, $constraint) = @_;

    push(@{ $self->components }, $component);
    push(@{ $self->constraints }, $constraint);
}

sub clear {
    my ($self) = @_;

    $self->components([]);
    $self->constraints([]);
}

sub each {
    my ($self, $functor) = @_;

    for(my $i = 0; $i < scalar(@{ $self->components }); $i++) {
        my $component = $self->get_component($i);
        my $constraint = $self->get_constraint($i);

        next unless defined($component);

        $functor->($component, $constraint);
    }
}

sub find {
    my ($self, $predicate) = @_;

    my $newlist = Graphics::Primitive::ComponentList->new;
    for(my $i = 0; $i < scalar(@{ $self->components }); $i++) {

        my $component = $self->get_component($i);
        my $constraint = $self->get_constraint($i);

        next unless defined($component);

        if($component->can('component_list')) {
            my $list = $component->find($predicate);

            next unless(scalar(@{ $list->components }));

            $newlist->push_components(@{ $list->components });
            $newlist->push_constraints(@{ $list->constraints });
        }

        if($predicate->($component, $constraint)) {
            $newlist->add_component($component, $constraint);
        }
    }

    return $newlist;
}

sub find_component {
    my ($self, $name) = @_;

    for(my $i = 0; $i <= scalar(@{ $self->components }); $i++) {
        my $comp = $self->get_component($i);

        if(defined($comp) && defined($comp->name) && $comp->name eq $name) {

            return $i;
        }
    }

    return undef;
}

sub remove_component {
    my ($self, $component) = @_;

    my $name;

    # Handle either a component object or a scalar name
    if(ref($component)) {
        if($component->can('name')) {
            $name = $component->name();
        } else {
            die('Must supply a Component or a scalar name.');
        }
    } else {
        $name = $component;
    }

    my $count = 0;
    my @dels = ();
    foreach my $comp (@{ $self->components }) {

        if(defined($comp) && defined($comp->name) && $comp->name eq $name) {

            push(@dels, $self->components->[$count]);
            delete($self->components->[$count]);
            delete($self->constraints->[$count]);
        }
        $count++;
    }

    return \@dels;
}

no Moose;
1;

=head1 NAME

Graphics::Primitive::ComponentList - List of Components

=head1 DESCRIPTION

Maintains a list of components and their constraints.  This is implemented
as a class to provide functionality above and beyond a simple array.

=head1 SYNOPSIS

  my $c = Graphics::Primitive::ComponentList->new;
  $c->add_component($comp, $constraint);

  my $cindex = $c->find_component($comp->name);

=head1 METHODS

=head2 Constructor

=over 4

=item I<new>

Creates a new Container.

=back

=head2 Instance Methods

=over 4

=item I<add_component ($component, $constraint)>

Add a component to the list.  Returns a true value if the component
was added successfully. A second argument may be required, please consult the
POD for your specific layout manager implementation.

Before the component is added, it is passed to the validate_component method.
If validate_component does not return a true value, then the component is not
added.

=item I<clear>

Reset components and constraints to empty arrayrefs.

=item I<component_count>

Returns the number of components in this list.

=item I<constraint_count>

Returns the number of constraints in this list.

=item I<each>

Calls the supplied CODEREF for each component in this list, passing the
component and it's constraints as arguments.

  my $flist = $list->each(
    sub{
        my ($component, $constraint) = @_; $comp->class('foo)
    }
  );


=item I<find>

Returns a new ComponentList containing only the components for which the
supplied CODEREF returns true.  The coderef is called for each component and
is passed the component and it's constraints.  Undefined components (the ones
left around after a remove_component) are automatically skipped.

  my $flist = $list->find(
    sub{
      my ($component, $constraint) = @_; return $comp->class eq 'foo'
    }
  );

If no matching components are found then a new list is returned so that simple
calls liked $container->find(...)->each(...) don't explode.

=item I<find_component>

Returns the index of the first component with the supplied name.  Returns
undef if no component with that name is found.

=item I<get_component>

Get the component at the specified index.

=item I<get_constraint>

Get the constraint at the specified index.

=item I<remove_component>

Removes a component and it's constraint.  B<Components must have names to be
removed.>  Returns an arrayref of Components that were removed.

=back

=head1 AUTHOR

Copyright 2008-2009 by Cory G Watson.

=head1 BUGS

Please report any bugs or feature requests to C<bug-geometry-primitive at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geometry-Primitive>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 by Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
