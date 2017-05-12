package IO::Die;

use strict;

sub socket {
    my ( $NS, $domain, $type, $protocol ) = ( shift, @_[ 1 .. $#_ ] );

    #https://github.com/pjcj/Devel--Cover/issues/125
    #my ( $NS, $socket_r, $domain, $type, $protocol ) = ( shift, \shift, shift, shift, shift );

    local ( $!, $^E );
    my $ok = CORE::socket( $_[0], $domain, $type, $protocol ) or do {
        $NS->__THROW( 'SocketOpen', domain => $domain, type => $type, protocol => $protocol );
    };

    return $ok;
}

1;
