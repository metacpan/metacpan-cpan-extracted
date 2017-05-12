package IO::Die;

use strict;

sub readlink {
    my $NS = shift;
    my $path = @_ ? shift : $_;

    local ( $!, $^E );
    my $ok = CORE::readlink($path) or do {
        $NS->__THROW( 'SymlinkRead', path => $path );
    };

    return $ok;
}

1;
