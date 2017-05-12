use strict;
package Device::Ericsson::AccessoryMenu::State;
use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors( 'parent' );

sub new {
    my $class = shift;
    $class->SUPER::new({ @_ });
}

sub on_exit {}
sub on_enter {}

# XXX should use a proper delegation factory

sub debug { $_[0]->parent->debug }

sub send   { $_[0]->parent->send( $_[1] ) }
sub expect { $_[0]->parent->expect( $_[1] ) }

sub enter_state {
    my $self = shift;
    $self->parent->enter_state( @_ );
}

sub exit_state {
    my $self = shift;
    $self->parent->exit_state( @_ );
}

sub current_state {
    my $self = shift;
    $self->parent->current_state;
}

1;
