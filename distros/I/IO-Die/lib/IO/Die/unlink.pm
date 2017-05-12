package IO::Die;

use strict;

#NOTE: This will only unlink() one file at a time. It refuses to support
#multiple unlink() operations within the same call. This is in order to provide
#reliable error reporting.
#
#You, of course, can still do: IO::Die->unlink() for @files;
#
sub unlink {
    my ( $NS, @paths ) = @_;

    #This is here because it’s impossible to do reliable error-checking when
    #you operate on >1 filesystem node at once.
    die "Only one path at a time!" if @paths > 1;

    if ( !@paths ) {
        @paths = ($_);
    }

    local ( $!, $^E );
    my $ok = CORE::unlink(@paths) or do {
        $NS->__THROW( 'Unlink', path => $paths[0] );
    };

    return $ok;
}

1;
