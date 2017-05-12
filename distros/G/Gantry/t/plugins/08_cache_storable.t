use strict;
use Test::More tests => 2;

BEGIN {
    eval { require Storable; };
    my $skip_all = ( $@ ) ? 1 : 0;

    SKIP: {
        skip "Gantry::Plugins::Cache::Storable requires Storable", 2
                if $skip_all;

        use_ok( 'Gantry::Plugins::Cache' );  
        use_ok( 'Gantry::Plugins::Cache::Storable' );
    }
}
