use strict;
use warnings;
use Test::More;

use Inline CPP => <<'END';

class Foo {
  public:
    Foo(int, int);
};

Foo::Foo(int a, int b) {
}

int add(int, int);
int add(int a, int b) { return a + b; }

END

new_ok( 'Foo', [ 10, 11 ] );

is( add( 2, 3 ), 5, "Simple function." );

done_testing();
