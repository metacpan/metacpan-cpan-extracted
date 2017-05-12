package IO::Die;

use strict;

sub mkdir {
    my ( $NS, @args ) = @_;

    local ( $!, $^E );

    my $ret;
    if ( @args > 1 ) {
        $ret = CORE::mkdir $args[0], $args[1];
    }
    else {
        if ( !@args ) {
            @args = ($_);
        }

        $ret = CORE::mkdir( $args[0] );
    }

    if ( !$ret ) {
        $NS->__THROW( 'DirectoryCreate', path => $args[0], mask => $args[1] );
    }

    return $ret;
}

1;
