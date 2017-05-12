use strict;
package Device::Ericsson::AccessoryMenu::Mouse;
use base 'Device::Ericsson::AccessoryMenu::State';
__PACKAGE__->mk_accessors( qw( callback title upup ) );

sub on_enter {
    my $self = shift;

    my $title = $self->title;

    # show the user a dialog they can quit from
    $self->send( qq{AT*EAID=13,2,"$title"} );
    $self->expect( 'OK' );
    # and put them into Event Reporting mode.
    $self->send( qq{AT+CMER=3,2,0,0,0} );
    $self->expect( 'OK' );
}

sub on_exit {
    my $self = shift;

    # reset spy mode
    $self->send( qq{AT+CMER=0,0,0,0,0} );
    $self->expect( 'OK' );
}

sub handle {
    my $self = shift;
    my $got = shift;

    if ($got =~ /\+CKEV: (?:(.),(.))?/) {
        my ($key, $updown) = ($1, $2);
        unless (defined $key) {
            # this seems glitchy on my phone. oh well - hack it
            $key    = "^";
            $updown = $self->upup;
            $updown ^= 1;
            $self->upup( $updown );
        }
        $self->callback->($key, $updown) if $self->callback;
    }
    if ($got =~ /\*EAII/) { # backup
        $self->exit_state;
        return;
    }

    warn "Mouse got unexpected 'line'\n" if $self->debug;
}

1;
