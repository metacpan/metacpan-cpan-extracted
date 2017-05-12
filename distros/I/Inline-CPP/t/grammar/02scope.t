use strict;
use warnings;
use Test::More;

# Testing proper handling of class scopes.

use Inline CPP => <<'END';

class Foo {
   void priv(int a) { q = a; }
   int q;
public:
   Foo() {}
   ~Foo() {}
   void zippo(int quack) { printf("Hello, world!\n"); }
};

END

my $obj = new_ok( 'Foo' );

can_ok( $obj, 'zippo' );

is( $obj->zippo( 10 ), undef, "Execute void public member function." );

ok( ! $obj->can( 'priv' ), "Can't access private member function." );

done_testing();
