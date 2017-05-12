use strict;
use Test::More tests => 1;

BEGIN {
    eval { require DBIx::Class; };
    my $skip_all = ( $@ ) ? 1 : 0;

    SKIP: {
        skip "Gantry::Utils::DBIxClass requires DBIx::Class", 1
                if $skip_all;

        use_ok( 'Gantry::Utils::DBIxClass' );
    }
}
