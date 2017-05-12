package IO::Die;

use strict;

sub truncate {
    my ( $NS, $fh_or_expr, $length ) = @_;

    local ( $!, $^E );
    my $ok = CORE::truncate( $fh_or_expr, $length ) or do {
        $NS->__THROW( 'FileTruncate', length => $length );
    };

    return $ok;
}

1;
