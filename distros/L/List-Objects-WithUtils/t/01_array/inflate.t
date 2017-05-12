use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array( foo => 1, bar => 2 );

my $hash = $arr->inflate;

ok $hash->does('List::Objects::WithUtils::Role::Hash'),
  'inflate ok';

ok $hash->get('foo') == 1 && $hash->get('bar') == 2,
  'inflated hash looks ok';


$hash = array->inflate;
ok $hash->is_empty, 'empty array inflate ok';

done_testing;
