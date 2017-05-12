use strict;
package Device::Ericsson::AccessoryMenu::Text;
use base 'Device::Ericsson::AccessoryMenu::State';
__PACKAGE__->mk_accessors( qw( title lines ) );


sub on_enter {
    my $self = shift;

    my $title = $self->title;
    $self->send( join ',',
                 qq{AT*EAID=14,2,"$title"},
                 map { qq{"$_"} } @{ $self->lines }
                );
    $self->expect( 'OK' );
}

sub handle {
    my $self = shift;
    $self->exit_state;
}

1;
