#!perl -T
use 5.006;
use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 2;

use Deep::Hash::Exists qw( every_keys );

my $hash_ref = {
        A => 'one',
        B => [ 'one', 'two' ],
        C => { 
            'one' => 1, 
            'two' => 2, 
        },
};

ok( every_keys( $hash_ref, [ ['A'], ['B'], ['C', 'one'] ] ), q(Every keys is exists) );
ok( ! every_keys( $hash_ref, [ ['A'], ['B', 0], ['C', 'one'] ] ), q(Every keys isn't exists) );
