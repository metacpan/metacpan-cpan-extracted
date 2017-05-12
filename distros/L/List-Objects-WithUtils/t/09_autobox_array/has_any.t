use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [];
ok !$arr->has_any, 'boxed negative bare has_any ok';
$arr->push(qw/ a b c /);
ok $arr->has_any, 'boxed bare has_any ok';
ok $arr->has_any(sub { /b/ }), 'boxed has_any ok';
ok !$arr->has_any(sub { /d/ }), 'boxed negative has_any ok';

done_testing;
