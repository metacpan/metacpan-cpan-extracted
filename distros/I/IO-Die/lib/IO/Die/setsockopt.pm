package IO::Die;

use strict;

sub setsockopt {
    my ( $NS, $socket, $level, $optname, $optval ) = @_;

    local ( $!, $^E );
    my $res = CORE::setsockopt( $socket, $level, $optname, $optval );
    if ( !defined $res ) {
        $NS->__THROW( 'SocketSetOpt', level => $level, optname => $optname, optval => $optval );
    }

    return $res;
}

1;
