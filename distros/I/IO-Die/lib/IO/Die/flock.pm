package IO::Die;

use strict;

sub flock {
    my ( $NS, $fh, $operation ) = @_;

    local ( $!, $^E );
    my $ok = CORE::flock( $fh, $operation ) or do {
        $NS->__THROW( 'Flock', operation => $operation );
    };

    return $ok;
}

1;
