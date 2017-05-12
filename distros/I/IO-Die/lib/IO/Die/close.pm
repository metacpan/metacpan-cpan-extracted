package IO::Die;

use strict;

sub close {
    my ( $NS, $fh ) = @_;

    local ( $!, $^E );
    my $ok = ( $fh ? CORE::close($fh) : CORE::close() ) or do {
        $NS->__THROW('Close');
    };

    return $ok;
}

1;
