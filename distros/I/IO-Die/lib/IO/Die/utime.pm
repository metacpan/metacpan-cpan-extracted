package IO::Die;

use strict;

#NOTE: This will only utime() one thing at a time. It refuses to support
#multiple utime() operations within the same call. This is in order to provide
#reliable error reporting.
#
#You, of course, can still do: IO::Die->utime() for @items;
#
sub utime {
    my ( $NS, $atime, $mtime, $target, @too_many_args ) = @_;

    die "Only one utime() at a time!" if @too_many_args;

    local ( $!, $^E );
    my $ok = CORE::utime( $atime, $mtime, $target ) or do {
        if ( __is_a_fh($target) ) {
            $NS->__THROW( 'Utime', atime => $atime, mtime => $mtime, path => $target );
        }

        $NS->__THROW( 'Utime', atime => $atime, mtime => $mtime );
    };

    return $ok;
}

1;
