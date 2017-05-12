package IO::Die;

use strict;

#A bit more restrictive than Perl’s built-in print():
#   - A file handle is still optional, but it MUST be a reference.
#
#This does still fall back to $_ and does still use the default file handle
#if either the LIST or FILEHANDLE is omitted (cf. perldoc -f print).
#
sub print {
    my ( $NS, $args_ar ) = ( shift, \@_ );

    local ( $!, $^E );

    my $ret;
    if ( __is_a_fh( $args_ar->[0] ) ) {
        $ret = CORE::print { shift @$args_ar } ( @$args_ar ? @$args_ar : $_ );
    }
    else {
        $ret = CORE::print( @$args_ar ? @$args_ar : $_ );
    }

    if ($^E) {

        #Figure out the "length" to report to the exception object.
        my $length;
        if (@$args_ar) {
            $length = 0;
            $length += length for @$args_ar;
        }
        else {
            $length = length;
        }

        $NS->__THROW( 'Write', length => $length );
    }

    return $ret;
}

1;
