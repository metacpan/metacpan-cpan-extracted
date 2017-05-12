package IO::Die;

use strict;

sub listen {
    my ( $NS, $socket, $queuesize ) = @_;

    local ( $!, $^E );
    my $ok = CORE::listen( $socket, $queuesize ) or do {
        $NS->__THROW( 'SocketListen', queuesize => $queuesize );
    };

    return $ok;
}

1;
