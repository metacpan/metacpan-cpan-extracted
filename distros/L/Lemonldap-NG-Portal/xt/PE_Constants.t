use strict;
use Test::More tests => 6;

SKIP: {
    eval 'use Lemonldap::NG::Handler::Status';
    if ($@) {
        skip 'Lemonldap::NG::Handler::Status not available', 6;
    }
    else {
        use_ok('Lemonldap::NG::Portal::Simple');

        ok( open( F, $INC{'Lemonldap/NG/Portal/Simple.pm'} ) );

        my ( %h1, %h2, @missingInStatus, @differentValues );

        # Load constants
        while (<F>) {
            $h1{$1} = $2 if (/^\s*PE_(\w+)\s*=>\s*(-?\d+),$/);
            last if (/^sub/);
        }
        close F;
        ok( open( F, $INC{'Lemonldap/NG/Handler/Status.pm'} ) );
        while (<F>) {
            $h2{$2} = $1 if (/^\s*(-?\d+)\s*=>\s*'PORTAL_(\w+)',$/);
        }

        foreach my $k ( sort keys %h1 ) {
            if ( defined( $h2{$k} ) ) {
                unless ( $h1{$k} == $h2{$k} ) {
                    push @differentValues, $k;
                }
                delete $h2{$k};
            }
            else {
                push @missingInStatus, $k;
            }
            delete $h1{$k};
        }

        ok( !@differentValues,
            'Search different constant values between Status.pm and portal' );
        ok(
            !@missingInStatus,
            join( ', ',
                'Search missing constants in Status.pm',
                @missingInStatus )
        );
        ok( !( keys %h2 ), 'Constants set in Status.pm and not in portal' );
    }
}
