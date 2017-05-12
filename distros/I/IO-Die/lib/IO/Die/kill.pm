package IO::Die;

use strict;

sub kill {
    my ( $NS, $sig, @list ) = @_;

    die "Only 1 process!" if @list > 1;

    local ( $!, $^E );
    my $ret = CORE::kill( $sig, @list );
    if ($!) {
        $NS->__THROW( 'Kill', signal => $sig, process => $list[0] );
    }

    return $ret;
}

1;
