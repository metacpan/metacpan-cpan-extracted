#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More 'tests' => 10;

use_ok( 'Hash::AsObject' );

my $h = Hash::AsObject->new(
    'foo' => {
        'bar' => {
            'baz' => 123,
        },
        'qux' => [ 1, 2, 3 ],
    },
);

isa_ok( $h->foo,      'Hash::AsObject', 'hash'        );
isa_ok( $h->foo->bar, 'Hash::AsObject', 'nested hash' );

is( $h->foo->bar->baz,      123, 'get scalar in nested hash' );
is( $h->foo->bar->baz(456), 456, 'set scalar in nested hash' );

is_deeply( $h->foo->qux, [1,2,3], 'get array in nested hash' );

my $people = { 'Frodo' => 'ring bearer', 'Gollum' => 'a bitter end' };
my $people_again = $h->foo->bar->baz($people);

is( ref($people), 'Hash::AsObject', 'stored hash has been reblessed'   );
is( $people,      $people_again,      'stored hash retains its identity' );

is( $h->people(undef), undef, 'undef an element' );
ok( exists($h->{'people'}), 'element still exists' );

