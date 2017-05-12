use strict;
use Test::More tests => 3;

BEGIN {
    eval { require Gantry::Plugins::Cache; };
    my $skip_1 = ( $@ ) ? 1 : 0;
    eval { require Gantry::Plugins::Session; };
    my $skip_2 = ( $@ ) ? 1 : 0;

    SKIP: {
        skip "Gantry::Plugins::Uaf requires Gantry::Plugins::Cache", 2
                if $skip_1;
        skip "Gantry::Plugins::Uaf requires Gantry::Plugins::Session", 2
                if $skip_2;

        use_ok( 'Gantry::Plugins::Cache' );        
        use_ok( 'Gantry::Plugins::Session' );
        use_ok( 'Gantry::Plugins::Uaf' );
    }
}
