package IO::Die;

use strict;

sub fcntl {
    my ( $NS, $fh, $func, $scalar ) = @_;

    local ( $!, $^E );
    my $ok = CORE::fcntl( $fh, $func, $scalar ) or do {
        $NS->__THROW( 'Fcntl', function => $func, scalar => $scalar );
    };

    return $ok;
}

1;
