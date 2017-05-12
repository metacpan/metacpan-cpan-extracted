use strict;
use Test::More tests => 1;

BEGIN {
    my $skip_all;

    eval { require Authen::Htpasswd; };
    $skip_all = ( $@ ) ? 1 : 0;

    eval { require Crypt::CBC; };
    $skip_all++ if ( $@ );

    SKIP: {
        skip
        "Gantry::Plugins::AuthCookie requires:"
        .   " Authen::Htpasswd, Crypt::CBC, and Crypt::Blowfish", 1
                if $skip_all;

        use_ok( 'Gantry::Plugins::AuthCookie' );
    }
}
