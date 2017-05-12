package IO::Die;

use strict;

sub chroot {
    my ( $NS, $filename ) = @_;

    local ( $!, $^E );

    if ( !defined $filename ) {
        $filename = $_;
    }

    my $ok = CORE::chroot($filename) or do {
        $NS->__THROW( 'Chroot', filename => $filename );
    };

    return $ok;
}

1;
