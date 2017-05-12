package IO::Die;

use strict;

sub symlink {
    my ( $NS, $old, $new ) = @_;

    local ( $!, $^E );
    my $ok = CORE::symlink( $old, $new ) or do {
        $NS->__THROW( 'SymlinkCreate', oldpath => $old, newpath => $new );
    };

    return $ok;
}

1;
