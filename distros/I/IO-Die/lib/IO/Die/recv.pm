package IO::Die;

use strict;

sub recv {
    my ( $NS, $socket, $length, $flags ) = ( shift, shift, @_[ 1 .. $#_ ] );

    #https://github.com/pjcj/Devel--Cover/issues/125
    #my ( $NS, $socket, $scalar_r, $length, $flags ) = ( shift, shift, \shift, @_ );

    local ( $!, $^E );
    my $res = CORE::recv( $socket, $_[0], $length, $flags );
    if ( !defined $res ) {
        $NS->__THROW( 'SocketReceive', length => $length, flags => $flags );
    }

    return $res;
}

1;
