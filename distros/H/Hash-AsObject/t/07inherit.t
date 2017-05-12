use strict;
use warnings;
use diagnostics;

use Test::More tests => 4;

use_ok( 'Hash::AsObject' );

package Hash::AsObject::Foo;

@Hash::AsObject::Foo::ISA = qw(Hash::AsObject);
*Hash::AsObject::Foo::AUTOLOAD = \&Hash::AsObject::AUTOLOAD;

my $foo = *Hash::AsObject::Foo::AUTOLOAD;  # Suppress "used only once" warning

package main;

my $hash = Hash::AsObject::Foo->new;
is( ref($hash), 'Hash::AsObject::Foo', 'blessing' );

is( $hash->abc('123'), 123, 'set scalar' );
is( $hash->abc, 123, 'get scalar' );
