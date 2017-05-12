use Test::More;
use strict; use warnings FATAL => 'all';

{ package My::List;
  use strict; use warnings FATAL => 'all';
  require List::Objects::WithUtils::Array;
  use parent 'List::Objects::WithUtils::Array';
}

my $foo = My::List->new;
isa_ok $foo->map(sub { $_ }), 'My::List', 'subclassed obj map ok';

done_testing;
