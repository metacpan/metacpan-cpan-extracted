use strict;
use Test::More tests => 2;

BEGIN {
    eval { require Cache::Memcached; };
    my $skip_all = ( $@ ) ? 1 : 0;

    SKIP: {
        skip "Gantry::Plugins::Cache::Memcached requires Cache::Memcached", 2
                if $skip_all;

        use_ok( 'Gantry::Plugins::Cache' );  
        use_ok( 'Gantry::Plugins::Cache::Memcached' );
    }
}
