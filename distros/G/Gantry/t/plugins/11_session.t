use strict;
use Test::More tests => 2;

BEGIN {
    eval { require Gantry::Plugins::Cache; require Gantry::Plugins::Session; };
    my $skip_all = ( $@ ) ? 1 : 0;

    SKIP: {
        skip "Gantry::Plugins::Session or Gantry::Plugins::Cache is not installed", 2
                if $skip_all;
                
        use_ok( 'Gantry::Plugins::Cache' );        
        use_ok( 'Gantry::Plugins::Session' );
    }
}
