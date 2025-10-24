#! perl


use v5.10;
use Test2::V0;
use Hash::Util 'hash_locked';
use Hash::Wrap ( {
    -immutable =>  0,
} );


my $obj     = wrap_hash( { a => { b => { c => 1 } } } );

is ( hash_locked( %$obj ), F(), 'hash is not locked' );

done_testing;
