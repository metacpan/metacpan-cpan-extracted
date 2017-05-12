use v5.14;
use strict; use warnings FATAL => 'all';

# Parameterized TypedArray example courtesy of TOBYINK:

package Foo {
  use Moo;
  use MooX::late;

  use List::Objects::Types 'TypedArray';
  use Types::Standard      'Int', 'Num';

  has integers => (
    is     => 'ro',
    isa    => TypedArray[ Int->plus_coercions(Num, 'int($_)') ],
    coerce => 1,
  );
}

my $foo = Foo->new( integers => [1, 2, 3.14159] );
$foo->integers->push(4.4);
say $foo->integers->join("\n")
