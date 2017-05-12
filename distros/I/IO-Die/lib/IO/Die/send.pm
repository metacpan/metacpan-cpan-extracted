package IO::Die;

use strict;

sub send {
    my ( $NS, $socket, $flags, $to ) = ( shift, shift, @_[ 1 .. $#_ ] );

    #https://github.com/pjcj/Devel--Cover/issues/125
    #my ( $NS, $socket, $msg_r, $flags, $to ) = ( shift, shift, \shift, @_ );

    local ( $!, $^E );
    my $res;
    if ( defined $to ) {
        $res = CORE::send( $socket, $_[0], $flags, $to );
    }
    else {
        $res = CORE::send( $socket, $_[0], $flags );
    }

    if ( !defined $res ) {
        $NS->__THROW( 'SocketSend', length => length( $_[0] ), flags => $flags );
    }

    return $res;
}

1;
