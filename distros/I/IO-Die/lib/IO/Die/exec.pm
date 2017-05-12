package IO::Die;

use strict;

sub exec {
    my ( $NS, $progname, @args ) = @_;

    my $ok = CORE::exec {$progname} $progname, @args or do {
        $NS->__THROW( 'Exec', program => $progname, arguments => \@args );
    };

    return $ok;
}

1;
