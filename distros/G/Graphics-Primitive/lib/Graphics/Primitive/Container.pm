package Graphics::Primitive::Container;
use Moose;
use MooseX::Storage;

with Storage (format => 'JSON', io => 'File');

use Graphics::Primitive::ComponentList;

use Forest::Tree;

extends 'Graphics::Primitive::Component';

with 'MooseX::Clone';

has 'component_list' => (
    is => 'rw',
    isa => 'Graphics::Primitive::ComponentList',
    default => sub { Graphics::Primitive::ComponentList->new },
    handles => [qw(component_count components constraints each find find_component get_component get_constraint)],
    trigger => sub { my ($self) = @_; $self->prepared(0); }
);
has 'layout_manager' => (
    is => 'rw',
    isa => 'Layout::Manager',
    handles => [ 'do_layout' ],
    trigger => sub { my ($self) = @_; $self->prepared(0); },
);

sub add_component {
    my ($self, $component, $args) = @_;

    return 0 unless $self->validate_component($component, $args);

    $component->parent($self);
    $self->component_list->add_component($component, $args);

    $self->prepared(0);

    return 1;
}

sub clear_components {
    my ($self) = @_;

    # Clear all the component's parent attributes just in case some
    # outside thingie is holding a reference to it
    foreach my $c (@{ $self->components }) {
        next unless(defined($c));
        $c->parent(undef);
    }
    $self->component_list->clear;
    $self->prepared(0);
}

sub get_tree {
    my ($self) = @_;

    my $tree = Forest::Tree->new(node => $self);

    foreach my $c (@{ $self->components }) {
        $tree->add_child($c->get_tree);
    }

    return $tree;
}

sub prepare {
    my ($self, $driver) = @_;

    return if $self->prepared;

    unless($self->minimum_width) {
        $self->minimum_width($self->outside_width);
    }
    unless($self->minimum_height) {
        $self->minimum_height($self->outside_height);
    }
}

sub remove_component {
    my ($self, $component) = @_;

    my $removed = $self->component_list->remove_component($component);
    if(scalar(@{ $removed })) {
        foreach my $r (@{ $removed }) {
            $r->parent(undef);
        }
    }

    return $removed;
}

sub validate_component {
    my ($self, $c, $a) = @_;

    return 1;
}

__PACKAGE__->meta->make_immutable;

no Moose;
1;
__END__

=head1 NAME

Graphics::Primitive::Container - Component that holds other Components

=head1 DESCRIPTION

Containers are components that contain other components.  They can also hold
an instance of a L<Layout::Manager> for automatic layout of their internal
components. See the
L<Component's Lifecycle Section|Graphics::Primitive::Component#LIFECYCLE> for
more information.

=head1 SYNOPSIS

  my $c = Graphics::Primitive::Container->new(
    width => 500, height => 350,
    layout_manager => Layout::Manager::Compass->new
  );
  $c->add_component($comp, { meta => 'data' });

=head1 METHODS

=head2 Constructor

=over 4

=item I<new>

Creates a new Container.

=back

=head2 Instance Methods

=over 4

=item I<add_component ($component, [ $constraint ])>

Add a component to the container.  Returns a true value if the component
was added successfully. A second argument may be required, please consult the
POD for your specific layout manager implementation.

Before the component is added, it is passed to the validate_component method.
If validate_component does not return a true value, then the component is not
added.

=item I<clear_components>

Remove all components from the layout manager.

=item I<component_count>

Returns the number of components in this container.

=item I<component_list>

Returns this Container's L<ComponentList|Graphics::Primitive::ComponentList>.

=item I<find_component>

Returns the index of the first component with the supplied name.  Returns
undef if no component with that name is found.

=item I<get_component>

Get the component at the specified index.

=item I<get_constraint>

Get the constraint at the specified index.

=item I<get_tree>

Returns a Forest::Tree object with this component at the root and all child
components as children.  Calling this from your root container will result
in a tree representation of the entire scene.

=item I<prepare>

Prepares this container.  Does not mark as prepared, as that's done by the
layout manager.

=item I<remove_component>

Removes a component.  B<Components must have names to be removed.>  Returns an
arrayref of removed components.

=item I<validate_component>

Optionally overridden by an implementation, allows it to deem a component as
invalid.  If this sub returns false, the component won't be added.

=back

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-geometry-primitive at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geometry-Primitive>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 by Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.