package IO::Die;

use strict;

#----------------------------------------------------------------------
#NOTE: read() and sysread() implementations are exactly the same except
#for the CORE:: function call.  Alas, Perl’s prototyping stuff seems to
#make it impossible not to duplicate code here.

sub sysread {
    my ( $NS, $fh, @length_offset ) = ( shift, shift, @_[ 1 .. $#_ ] );

    #https://github.com/pjcj/Devel--Cover/issues/125
    #my ( $NS, $fh, $buffer_sr, @length_offset ) = ( shift, shift, \shift, @_ );

    my ( $length, $offset ) = @length_offset;

    local ( $!, $^E );

    #NOTE: Perl’s prototypes can throw errors on things like:
    #(@length_offset > 1) ? $offset : ()
    #...so the following writes out the two forms of sysread():

    my $ret;
    if ( @length_offset > 1 ) {
        $ret = CORE::sysread( $fh, $_[0], $length, $offset );
    }
    else {
        $ret = CORE::sysread( $fh, $_[0], $length );
    }

    if ( !defined $ret ) {
        $NS->__THROW( 'Read', length => $length );
    }

    return $ret;
}

1;
