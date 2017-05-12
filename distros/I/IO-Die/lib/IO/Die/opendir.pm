package IO::Die;

use strict;

sub opendir {
    my ( $NS, $dir ) = ( shift, @_[ 1 .. $#_ ] );

    #https://github.com/pjcj/Devel--Cover/issues/125
    #my ( $NS, $dh_r, $dir ) = ( shift, \shift, shift );

    local ( $!, $^E );
    my $ok = CORE::opendir( $_[0], $dir ) or do {
        $NS->__THROW( 'DirectoryOpen', path => $dir );
    };

    return $ok;
}

1;
