use strict;
use Test::More tests => 1;

BEGIN {
    eval { require Date::Calc; };
    my $skip_all = ( $@ ) ? 1 : 0;

    SKIP: {
        skip "Gantry::Utils::Validate requires Date::Calc", 1
                if $skip_all;

        use_ok( 'Gantry::Utils::Validate' );
    }
}
