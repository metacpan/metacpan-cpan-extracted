package Gapp::Action::Registry;
{
  $Gapp::Action::Registry::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

use MooseX::Types::Moose qw( Object HashRef );

has 'actions' => (
    is => 'bare',
    isa => HashRef,
    default => sub { { } },
    traits => [ qw( Hash )],
    handles => {
        _set_action => 'set',
        actions => 'values',
        action => 'get',
        action_list => 'keys',
        has_action => 'exists',
    }
);

sub add_action {
    my ( $self, $action ) = @_;
    
    
    $action = Gapp::Action->new( $action ) if ! is_Object($action);
    $self->_set_action( $action->name, $action );
}

sub perform {
    my ( $self, $action, @args ) = @_;
    
    $self->meta->throw_error( qq[action ($action) does not exist] )
        if ! $self->has_action( $action );
        
    $self->action( $action )->perform( $self, @args );
}



no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Gapp::Action::Registry - Registry of L<Gapp::Action> objects

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Action::Registry>

=back

=head1 PROVIDED METHODS

=over 4

=item B<action $name>

Returns the L<Gapp::Action> in the regisry with the given name.

=item B<actions>

Returns a list all of the L<Gapp::Action> objects in the registry.

=item B<action_list>

Returns a list of all the action names in the registry.

=item B<add_action $action|\%opts>

Add an action to the registry. Takes either a L<Gapp::Action> object or a C<HashRef>.
If a C<HashRef> is supplied, the values will be used to create a new L<Gapp::Action>
object.

=item B<has_action $name>

Returns C<true> if an action with the given C<$name> exists in the registry, C<false> otherwise.

=item B<perform $name, @args>

Calls C<perform> on the action with the given name, passing in C<args> as parameters.


=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut