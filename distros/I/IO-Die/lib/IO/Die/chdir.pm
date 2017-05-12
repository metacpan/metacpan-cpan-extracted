package IO::Die;

use strict;

sub chdir {
    my ( $NS, @args ) = @_;

    local ( $!, $^E );

    my $ret;

    if (@args) {
        $ret = CORE::chdir( $args[0] ) or do {
            if ( __is_a_fh( $args[0] ) ) {
                $NS->__THROW('Chdir');
            }
            else {
                $NS->__THROW( 'Chdir', path => $args[0] );
            }
        };
    }
    else {
        $ret = CORE::chdir or do {
            my $path = _get_what_chdir_took_as_homedir();

            if ( !defined $path ) {
                $NS->__THROW('Chdir');
            }

            $NS->__THROW( 'Chdir', path => $path );
        };
    }

    return $ret;
}

sub _get_what_chdir_took_as_homedir {
    my $path = $ENV{'HOME'};
    if ( !defined $path ) {
        $path = $ENV{'LOGDIR'};

        if ( !defined($path) && $^O eq 'VMS' ) {
            $path = $ENV{'SYS$LOGIN'};
        }
    }

    return $path;
}

1;
