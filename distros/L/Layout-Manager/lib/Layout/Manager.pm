package Layout::Manager;
use Moose;

our $AUTHORITY = 'cpan:GPHAT';
our $VERSION = '0.35';

sub do_layout {
    my ($self, $container) = @_;

    die('Need a container') unless defined($container);

    return 0 unless $container->component_count;

    return 0 if $container->prepared && $self->_check_container($container);

    # Layout child containers first, since we can't fit them into this one
    # without knowing the sizes.
    foreach my $comp (@{ $container->components }) {

        next unless defined($comp) && $comp->visible;

        if($comp->can('do_layout')) {
            $comp->do_layout($comp);
        }
    }

    $container->prepared(1);
    return 1;
}

sub _check_container {
    my ($self, $cont) = @_;

    foreach my $comp (@{ $cont->components }) {

        unless($comp->prepared) {
            $cont->prepared(0);
            return 0;
        }
        if($comp->can('do_layout')) {
            if(!$self->_check_container($comp)) {
                $comp->prepared(0);
                return 0;
            }
        }
    }

    return 1;
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;
__END__
=head1 NAME

Layout::Manager - 2D Layout Management

=head1 SYNOPSIS

Layout::Manager provides a simple interface for creating layout managers, or
classes that size and position components within a container.

A few managers are provided for reference, but this module is primarily meant
to serve as a base for outside implementations.

    use Layout::Manager;

    my $foo = Layout::Manager->new;
    $foo->do_layout($component);

=head1 USING A LAYOUT MANAGER

Layout::Manager relies on L<Graphics::Primitive::Container> as a source for
it's components.

Various implementations of Layout::Manager will require you do add components
with slightly different second arguments, but the general case will be:

  $lm->add_component($comp, $constraints);

The contents of B<$constraints> must be discerned by reading the documentation
for the layout manager you are using.

The B<$comp> argument must be a L<Graphics::Primitive::Component>.

Layout manager works hand-in-hand with Graphics::Primitive, so you'll want to
check out the L<lifecyle|Graphics::Primitive::Component#LIFECYCLE> documented
in L<Graphics::Primitive::Component>.  It will look something like this:

  $cont->add_component($foo, { some => metadata });
  $driver->prepare($cont);
  my $lm = new Layout::Manager::SomeImplementation;
  $lm->do_layout($cont);
  $driver->pack($cont);
  $driver->draw($cont);

When you are ready to lay out your container, you'll need to call the
L<do_layout> method with a single argument: the component in which you are
laying things out. When I<do_layout> returns all of the components should be
resized and repositioned according to the rules of the Layout::Manager
implementation.

=head2 PREPARATION

Subsequent calls to do_layout will be ignored if the Container is prepared.
The Container's C<prepared> flag and the flags of all it's children are
checked, so any modifications to B<any> child component will cause the entire
container (and any container children) to be laid out again.

=head1 WRITING A LAYOUT MANAGER

Layout::Manager provides all the methods necessary for your implementation,
save the I<do_layout> method.  This method will be called when it is time to
layout the components.

The I<add_component> method takes two arguments: the component and a second,
abritrary piece of data.  If your layout manager is simple, like 
L<Compass|Layout::Manager::Compass>, you may only require a simple variable
like "NORTH".  If you create something more complex the second argument may be
a hashref or an object.

The value of the I<components> method is an arrayref of hashrefs.  The
hashrefs have two keys:

=over 

=item B<component>

The component to be laid out.

=item B<args>

The argument provided to I<add_component>.

=back

=head1 TIPS

Layout manager implementations should honor the I<visible> attribute of a
component, as those components need to be ignored.

=head1 METHODS

=head2 do_layout

Lays out this manager's components in the specified container.

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

=head1 SEE ALSO

perl(1), L<Graphics::Primitive>

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2010 Cory G Watson

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
