package IO::Die;

use strict;

sub syswrite {
    my ( $NS, $fh, @length_offset ) = ( shift, shift, @_[ 1 .. $#_ ] );

    #https://github.com/pjcj/Devel--Cover/issues/125
    #my ( $NS, $fh, $buffer_sr, @length_offset ) = ( shift, shift, \shift, @_ );

    my ( $length, $offset ) = @length_offset;

    local ( $!, $^E );

    my $ret;
    if ( @length_offset > 1 ) {
        $ret = CORE::syswrite( $fh, $_[0], $length, $offset );
    }
    elsif (@length_offset) {
        $ret = CORE::syswrite( $fh, $_[0], $length );
    }
    else {
        $ret = CORE::syswrite( $fh, $_[0] );
    }

    if ( !defined $ret ) {
        my $real_length = length $_[0];

        if ($offset) {
            if ( $offset > 0 ) {
                $real_length -= $offset;
            }
            else {
                $real_length = 0 - $offset;
            }
        }

        if ( defined $length && $length < $real_length ) {
            $real_length = $length;
        }

        $NS->__THROW( 'Write', length => $real_length );
    }

    return $ret;
}

1;
