use strict;
use Test::More tests => 1;


BEGIN {
    eval { require Data::Random; };
    my $skip_all = ( $@ ) ? 1 : 0;

    SKIP: {
        skip "Gantry::Utils::Captcha requires Data::Random", 1
                if $skip_all;

        use_ok( 'Gantry::Utils::Captcha' );    
    }
}

