use strict;
use warnings;

## no critic (Modules::RequireExplicitPackage,Modules::ProhibitMultiplePackages)

use MetaCPAN::Moose;
use Test::Fatal qw( exception );
use Test::More;

package Foo;
use MetaCPAN::Moose;

use Scalar::Util qw( blessed );

## no critic (NamingConventions::Capitalization)
package main;

ok( Foo->new, 'compiles' );

like(
    exception { Foo->new( foo => 'bar' ); },
    qr/Found unknown attribute/,
    'the code died as expected',
);

my $foo = Foo->new;

ok( !$foo->can('blessed'), 'namespace gets cleaned' );

done_testing;
