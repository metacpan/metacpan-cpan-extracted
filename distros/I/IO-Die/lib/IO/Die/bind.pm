package IO::Die;

use strict;

sub bind {
    my ( $NS, $socket, $name ) = @_;

    local ( $!, $^E );
    my $ok = CORE::bind( $socket, $name ) or do {
        $NS->__THROW( 'SocketBind', name => $name );
    };

    return $ok;
}

1;
