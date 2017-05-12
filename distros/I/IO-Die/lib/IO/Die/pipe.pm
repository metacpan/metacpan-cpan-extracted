package IO::Die;

use strict;

sub pipe {
    my ($NS) = (shift);

    #https://github.com/pjcj/Devel--Cover/issues/125
    #my ( $NS, $read_r, $write_r ) = ( shift, \shift, \shift );

    local ( $!, $^E );
    my $ok = CORE::pipe( $_[0], $_[1] ) or do {
        $NS->__THROW('Pipe');
    };

    return $ok;
}

1;
