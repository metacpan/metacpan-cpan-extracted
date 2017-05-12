#!/usr/bin/perl;
package TEST::Fennec::TODO;
use strict;
use warnings;

use Fennec;

tests blah1 => (
    skip => 'whatever',
    code => sub {
        ok( 0, "fail 1" );
    },
);

tests blah2 => (
    todo => 'whatever',
    code => sub {
        ok( 0, "fail 2" );
    },
);

done_testing;
