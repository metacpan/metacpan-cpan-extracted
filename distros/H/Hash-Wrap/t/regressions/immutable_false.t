#! perl

use v5.10;
use Test2::V0;
use Hash::Wrap ( {
    -immutable => 0,
} );


my $obj = wrap_hash( { a => { b => { c => 1 } } } );

ok( lives { $obj->{bar} = 3 }, 'hash is not locked' );

done_testing;
