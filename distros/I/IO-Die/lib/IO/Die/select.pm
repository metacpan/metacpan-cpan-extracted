package IO::Die;

use strict;

sub select {
    my ( $NS, $timeout ) = ( shift, $_[3] );

    #Perl::Critic says not to use one-arg select() anyway.
    die "Need four args!" if @_ < 4;

    local ( $!, $^E );
    my ( $nfound, $timeleft ) = CORE::select( $_[0], $_[1], $_[2], $timeout );

    if ($^E) {
        $NS->__THROW('Select');
    }

    return wantarray ? ( $nfound, $timeleft ) : $nfound;
}

1;
