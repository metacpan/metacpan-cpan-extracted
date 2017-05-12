use strict;
use warnings;
use Test::More tests => 5;;
use ESPPlus::Storage::Util;

ok( ! defined *test{CODE},
    "test() doesn't exist" );

attribute_builder( 'test' );
ok( defined *test{CODE},
    "test() now exists" );

my $o = bless { 'test', 'test' };
is( $o->test,
    'test',
    '->test returns "test"' );

is( $o->test("still testing"),
    "still testing",
    "->test('still testing') returns 'still testing'" );

is( $o->test,
    "still testing",
    "->test returns 'still testing'" );
