use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'hash';

{ package My::Hash;
  use strict; use warnings FATAL => 'all';
  use parent 'List::Objects::WithUtils::Hash';
}

my $foo = My::Hash->new(foo => 1, bar => 2);
isa_ok $foo->sliced('foo', 'bar'), 'My::Hash',
  'subclassed hash ok';

done_testing;
