package IO::Die;

use strict;

sub link {
    my ( $NS, $old, $new ) = @_;

    local ( $!, $^E );
    my $ok = CORE::link( $old, $new ) || do {
        $NS->__THROW( 'Link', oldpath => $old, newpath => $new );
    };

    return $ok;
}

1;
