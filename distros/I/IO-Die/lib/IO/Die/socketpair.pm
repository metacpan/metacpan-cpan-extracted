package IO::Die;

use strict;

sub socketpair {
    my ( $NS, $domain, $type, $protocol ) = ( shift, @_[ 2 .. $#_ ] );

    #https://github.com/pjcj/Devel--Cover/issues/125
    #my ( $NS, $socket1_r, $socket2_r, $domain, $type, $protocol ) = ( \shift, \shift, shift, shift );

    local ( $!, $^E );
    my $ok = CORE::socketpair( $_[0], $_[1], $domain, $type, $protocol ) or do {
        $NS->__THROW( 'SocketPair', domain => $domain, type => $type, protocol => $protocol );
    };

    return $ok;
}

1;
