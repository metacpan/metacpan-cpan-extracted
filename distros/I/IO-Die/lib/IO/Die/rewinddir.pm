package IO::Die;

use strict;

sub rewinddir {
    my ( $NS, $dh ) = @_;

    local ( $!, $^E );
    my $ok = CORE::rewinddir($dh) or do {
        $NS->__THROW('DirectoryRewind');
    };

    return $ok;
}

1;
