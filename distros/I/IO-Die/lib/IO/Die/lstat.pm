package IO::Die;

use strict;

#NOTE: To get lstat(_), do lstat(\*_).
sub lstat {
    my ( $NS, $path_or_fh ) = @_;

    local ( $!, $^E );

    my $ret = wantarray ? [ CORE::lstat($path_or_fh) ] : CORE::lstat($path_or_fh);

    if ($^E) {
        if ( __is_a_fh($path_or_fh) ) {
            $NS->__THROW('Stat');
        }

        $NS->__THROW( 'Stat', path => $path_or_fh );
    }

    return wantarray ? @$ret : $ret;
}

1;
