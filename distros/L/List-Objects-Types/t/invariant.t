BEGIN {
  unless (eval {; require Moo; 1 } && !$@) {
    require Test::More;
    Test::More::plan(skip_all =>
      'these tests require Moo-2+'
    );
  }

  unless (eval {; Moo->VERSION(2) }) {
    require Test::More;
    Test::More::plan(skip_all =>
      'these tests require Moo-2.x or newer'
    );
  }
}

use Test::More;
use strict; use warnings FATAL => 'all';

{ package
    Foo;
  use Types::Standard -all;
  use List::Objects::Types -all;
  use List::Objects::WithUtils;
  use Moo;

  has mynums => (
    lazy   => 1, 
    is     => 'ro',
    isa    => TypedArray[Num],
    builder => sub { die "Broken test; I shouldn't be called!" },
  );

  has mynums_coercible => (
    lazy   => 1, 
    is     => 'ro',
    isa    => TypedArray[Num],
    coerce => 1,
    builder => sub { die "broken test; I shouldn't be called!" },
  );
}

use List::Objects::WithUtils;
use Types::Standard -all;

my $foo = Foo->new(
  mynums_coercible => array_of(Int, 1,2,3)
);
cmp_ok $foo->mynums_coercible->type, '==', Num,
  'array_of Int coerced to Num';

eval {;
  Foo->new( mynums => array_of(Int, 1,2,3) )
};
like $@, qr/Num/, 'TypedArray[Num] without coercion fails on array_of Int';

done_testing;
