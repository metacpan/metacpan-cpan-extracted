package IO::Die;

use strict;

#NOTE: This will only chmod() one thing at a time. It refuses to support
#multiple chmod() operations within the same call. This is in order to provide
#reliable error reporting.
#
#You, of course, can still do: IO::Die->chmod() for @items;
#
sub chmod {
    my ( $NS, $mode, $target, @too_many_args ) = @_;

    #This is here because it’s impossible to do reliable error-checking when
    #you operate on >1 filesystem node at once.
    die "Only one path at a time!" if @too_many_args;

    #NOTE: This breaks chmod’s error reporting when a file handle is passed in.
    #cf. https://rt.perl.org/Ticket/Display.html?id=122703
    local ( $!, $^E );

    my $ok = CORE::chmod( $mode, $target ) or do {
        if ( __is_a_fh($target) ) {
            $NS->__THROW( 'Chmod', permissions => $mode );
        }

        $NS->__THROW( 'Chmod', permissions => $mode, path => $target );
    };

    return $ok;
}

1;
