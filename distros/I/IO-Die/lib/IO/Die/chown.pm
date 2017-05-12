package IO::Die;

use strict;

#NOTE: This will only chown() one thing at a time. It refuses to support
#multiple chown() operations within the same call. This is in order to provide
#reliable error reporting.
#
#You, of course, can still do: IO::Die->chown() for @items;
#
sub chown {
    my ( $NS, $uid, $gid, $target, @too_many_args ) = @_;

    #This is here because it’s impossible to do reliable error-checking when
    #you operate on >1 filesystem node at once.
    die "Only one path at a time!" if @too_many_args;

    local ( $!, $^E );

    my $ok = CORE::chown( $uid, $gid, $target ) or do {
        if ( __is_a_fh($target) ) {
            $NS->__THROW( 'Chown', uid => $uid, gid => $gid );
        }

        $NS->__THROW( 'Chown', uid => $uid, gid => $gid, path => $target );
    };

    return $ok;
}

1;
