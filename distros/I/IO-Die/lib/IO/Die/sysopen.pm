package IO::Die;

use strict;

sub sysopen {
    my ( $NS, @post_handle_args ) = ( shift, @_[ 1 .. $#_ ] );

    #https://github.com/pjcj/Devel--Cover/issues/125
    #my ( $NS, $handle_r, @post_handle_args ) = ( shift, \shift, @_ );

    my ( $path, $mode, $perms ) = @post_handle_args;

    local ( $!, $^E );

    my $ret;
    if ( @post_handle_args < 3 ) {
        $ret = CORE::sysopen( $_[0], $path, $mode );
    }
    else {
        $ret = CORE::sysopen( $_[0], $path, $mode, $perms );
    }

    #XXX: Perl bug? $! is often set here even when $ret is truthy.

    if ( !$ret ) {
        $NS->__THROW( 'FileOpen', path => $path, mode => $mode, mask => $perms );
    }

    return $ret;
}

1;
