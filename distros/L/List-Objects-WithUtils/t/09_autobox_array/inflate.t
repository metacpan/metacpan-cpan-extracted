use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [ foo => 1, bar => 2 ];
my $hash = $arr->inflate;
ok $hash->does('List::Objects::WithUtils::Role::Hash'),
  'boxed inflate ok';
ok $hash->get('foo') == 1 && $hash->get('bar') == 2,
  'boxed inflated hash looks ok';

done_testing;
