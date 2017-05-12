use strict;
package Device::Ericsson::AccessoryMenu::Slider;
use base 'Device::Ericsson::AccessoryMenu::State';
__PACKAGE__->mk_accessors( qw( callback value steps title ) );


sub on_enter {
    my $self = shift;

    my $title = $self->title;
    my $steps = $self->steps;
    my $value = int( $self->value / 100 * $steps ); # starting step

    $self->send( qq{AT*EAID=4,2,"$title",$steps,$value} );
    $self->expect( 'OK' );
}

sub handle {
    my $self = shift;
    my $line = shift;

    if ($line =~ /^\*EAII: 15,(\d+)$/) {
        my $value = $1;
        $self->callback->($value) if $self->callback;
        return;
    }
    if ($line =~ /\*EAII: [04]/) {
        $self->exit_state;
        return;
    }
    warn "Slider got unexpected 'line'\n" if $self->debug;
}

1;
