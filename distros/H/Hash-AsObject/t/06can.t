use strict;
use warnings;

use Test::More tests => 8;

use_ok( 'Hash::AsObject' );

my $o = Hash::AsObject->new({ 'a' => 42 });

my $a = $o->can('a');
my $b = $o->can('b');

is( ref($a), 'CODE', 'can returns a code ref if the key exists' );
is( ref($b), 'CODE', 'can returns a code ref if the key doesn\'t exist' );

is( $a->($o),     42, 'use can to invoke getter'        );
is( $a->($o, 99), 99, 'use can to invoke setter'        );
is( $a->($o, 99), 99, 'setter invoked using can worked' );

is( $b->($o, 23), 23, 'use can to invoke setter (key doesn\'t exist)' );
is( $b->($o),     23, 'use can to invoke getter'                      );
