package IO::Die;

use strict;

sub accept {
    my ( $NS, $generic_socket ) = @_[ 0, 2 ];

    #https://github.com/pjcj/Devel--Cover/issues/125
    #my ( $NS, $new_socket, $generic_socket ) = @_;

    local ( $!, $^E );
    my $ok = CORE::accept( $_[1], $generic_socket ) or do {
        $NS->__THROW('SocketAccept');
    };

    return $ok;
}

1;
