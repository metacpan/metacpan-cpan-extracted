use strict;
use warnings;
use Test::More;

# this is needed to avoid false passes if was done first without 'info'
use Inline CPP => config => force_build => 1, clean_after_build => 0;

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
