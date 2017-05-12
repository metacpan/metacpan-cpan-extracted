package IO::Die;

use strict;

#NOTE: To get stat(_), do stat(\*_).
sub stat {
    my ( $NS, $path_or_fh ) = @_;

    local ( $!, $^E );

    my $ret = wantarray ? [ CORE::stat($path_or_fh) ] : CORE::stat($path_or_fh);

    if ($^E) {
        if ( __is_a_fh($path_or_fh) ) {
            $NS->__THROW('Stat');
        }

        $NS->__THROW( 'Stat', path => $path_or_fh );
    }

    return wantarray ? @$ret : $ret;
}

1;
