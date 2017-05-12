use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $obj = +{foo => 'bar', baz => 'quux'}->inflate;
ok $obj->foo eq 'bar', 'boxed inflate ok (1)';
ok $obj->baz eq 'quux', 'boxed inflate ok (2)';

done_testing;
