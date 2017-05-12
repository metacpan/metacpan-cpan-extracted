package IO::Die;

use strict;

sub getsockopt {
    my ( $NS, $socket, $level, $optname ) = @_;

    local ( $!, $^E );
    my $res = CORE::getsockopt( $socket, $level, $optname );
    if ( !defined $res ) {
        $NS->__THROW( 'SocketGetOpt', level => $level, optname => $optname );
    }

    return $res;
}

1;
