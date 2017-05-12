package IO::Die;

use strict;

sub fileno {
    my ( $NS, $fh ) = @_;

    local ( $!, $^E );
    my $fileno = CORE::fileno($fh);

    if ( !defined $fileno ) {
        $NS->__THROW('Fileno');
    }

    return $fileno;
}

1;
