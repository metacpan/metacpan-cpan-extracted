#!perl -T
use 5.006;
use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 2;

use Deep::Hash::Exists qw( some_keys );

my $hash_ref = {
        A => 'one',
        B => [ 'one', 'two' ],
        C => { 
            'one' => 1, 
            'two' => 2, 
        },
};
 
ok( some_keys( $hash_ref, [ ['A'], ['B', 0], ['C', 'one'] ] ), q(Some key is exists) );
ok( ! some_keys( $hash_ref, [ ['D'], ['B', 0], ['C', 'six'] ] ), q(Some key isn't exists) );
