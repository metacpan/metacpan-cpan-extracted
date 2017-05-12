package IO::Die;

use strict;

#NOTE: See about read/sysread; the same duplicated code problem
#applies to seek/sysseek.

sub seek {
    my ( $NS, $fh, $pos, $whence ) = @_;

    local ( $!, $^E );
    my $ok = CORE::seek( $fh, $pos, $whence ) or do {
        $NS->__THROW( 'FileSeek', whence => $whence, position => $pos );
    };

    return $ok;
}

1;
