package IO::Die;

use strict;

sub rename {
    my ( $NS, $old, $new ) = @_;

    local ( $!, $^E );
    my $ok = CORE::rename( $old, $new ) or do {
        $NS->__THROW( 'Rename', oldpath => $old, newpath => $new );
    };

    return $ok;
}

1;
