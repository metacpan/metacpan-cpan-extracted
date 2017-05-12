package IO::Die;

use strict;

sub shutdown {
    my ( $NS, $socket, $how ) = @_;

    local ( $!, $^E );

    my $res = CORE::shutdown( $socket, $how );
    if ( !$res ) {
        die "Invalid filehandle!" if !defined $res;
        $NS->__THROW( 'SocketShutdown', how => $how );
    }

    return $res;
}

1;
