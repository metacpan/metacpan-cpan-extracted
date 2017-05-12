package IO::Die;

use strict;

sub closedir {
    my ( $NS, $dh ) = @_;

    local ( $!, $^E );
    my $ok = CORE::closedir($dh) or do {
        $NS->__THROW('DirectoryClose');
    };

    return $ok;
}

1;
