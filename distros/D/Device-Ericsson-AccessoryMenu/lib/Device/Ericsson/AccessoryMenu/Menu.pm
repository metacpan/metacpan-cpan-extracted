use strict;
package Device::Ericsson::AccessoryMenu::Menu;
use base 'Device::Ericsson::AccessoryMenu::State';
__PACKAGE__->mk_accessors( qw( data selected ) );


sub _get_pairs {
    my $self = shift;

    my @menu = @{ $self->data };
    my @entries = @{ $menu[1] };
    my @pairs;
    while (@entries) {
        push @pairs, [ shift @entries, shift @entries ];
    }
    print map { "$_->[0]: $_->[1]\n"} @pairs
      if $self->debug && 0;
    return @pairs;
}

sub on_enter {
    my $self = shift;
    my $selected = $self->selected || 1;

    my $name   = $self->data->[0];
    my @pairs  = $self->_get_pairs;
    my $titles = join ',', map { qq{"$_->[0]"} } @pairs;
    my $length = scalar @pairs;
    $self->send( qq{AT*EASM="$name",1,$selected,$length,$titles} );
    $self->expect( 'OK' );
}

sub handle {
    my $self = shift;
    my $line = shift;

    if ($line =~ /EAMI: (\d+)/) { # menu item
        my $item = $1;
        if ($item == 0) { # back up
            $self->exit_state;
            return;
        }

        my @pairs = $self->_get_pairs;
        unshift @pairs, []; # dummy one so the offsets all work out
        my ($name, $action) = @{ $pairs[ $item ] };

        $self->selected( $item );
        print "invoking $item: $action\n" if $self->debug;
        $action = $action->( $self->parent ) if ref $action eq 'CODE';

        if (ref $action eq 'ARRAY') { # wander down
            $self->enter_state( 'Menu', data => [ $name => $action ] );
            return;
        }

        if (defined $action && !ref $action) {
            $self->parent->send_text( $name, $action );
            return;
        }

        # update and resend, if we're still in this state
        $self->on_enter if $self->current_state == $self;
    }
}

1;

