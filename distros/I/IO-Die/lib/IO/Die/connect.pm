package IO::Die;

use strict;

sub connect {
    my ( $NS, $socket, $name ) = @_;

    local ( $!, $^E );
    my $ok = CORE::connect( $socket, $name ) or do {
        $NS->__THROW( 'SocketConnect', name => $name );
    };

    return $ok;
}

1;
