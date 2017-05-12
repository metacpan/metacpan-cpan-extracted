use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array(1, 2, 3);

my $all = $arr->all_items->map(sub { $_[0] });
ok $all->isa('List::Objects::WithUtils::Array::Junction::All'),
  'all_items subclass ok';
ok $all > 0, 'all_items ok';

my $any = $arr->any_items;
ok $any->isa('List::Objects::WithUtils::Array::Junction::Any'),
  'any_items subclass ok';
ok $any > 2, 'any_items ok';

done_testing;
