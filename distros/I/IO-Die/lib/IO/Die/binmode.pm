package IO::Die;

use strict;

my $DEFAULT_BINMODE_LAYER = ':raw';    #cf. perldoc -f binmode

sub binmode {
    my ( $NS, $fh_r, $layer ) = @_;

    if ( !defined $layer ) {
        $layer = $DEFAULT_BINMODE_LAYER;
    }

    local ( $!, $^E );
    my $ok = CORE::binmode( $fh_r, $layer ) or do {
        $NS->__THROW( 'Binmode', layer => $layer );
    };

    return $ok;
}

1;
