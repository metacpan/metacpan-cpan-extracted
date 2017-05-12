use strict;
use Test::More;
BEGIN { plan tests => 1 };

SKIP: {
    skip "This test is for Perl 5.005.", 1 if ( $] >= 5.006 );
    ok( eval { require JSON::PP::Compat5005 } );
}


