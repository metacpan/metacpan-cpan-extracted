package IO::Die;

use strict;

sub rmdir {
    my ( $NS, @args ) = @_;

    #Perl's rmdir() doesn’t actually allow batching like this,
    #but we might as well prevent anyone from trying.
    die "Only one path at a time!" if @args > 1;

    if ( !@args ) {
        @args = ($_);
    }

    local ( $!, $^E );
    my $ok = CORE::rmdir( $args[0] ) or do {
        $NS->__THROW( 'DirectoryDelete', path => $args[0] );
    };

    return $ok;
}

1;
