use strict;
use Test::More tests => 1;

BEGIN {
    eval { require Data::FormValidator; };
    my $skip_all = ( $@ ) ? 1 : 0;

    SKIP: {
        skip "Gantry::Plugins::AutoCRUD requires Data::FormValidator", 1
                if $skip_all;

        use_ok( 'Gantry::Plugins::AutoCRUD' );
    }
}
