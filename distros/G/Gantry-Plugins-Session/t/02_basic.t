use strict;
use Test::More tests => 2;

BEGIN {
    eval { require Gantry::Plugins::Cache; };
    my $skip_all = ( $@ ) ? 1 : 0;

    SKIP: {
        skip "Gantry::Plugins::Session requires Gantry::Plugins::Cache", 2
                if $skip_all;
                
        use_ok( 'Gantry::Plugins::Cache' );        
        use_ok( 'Gantry::Plugins::Session' );
    }
}
