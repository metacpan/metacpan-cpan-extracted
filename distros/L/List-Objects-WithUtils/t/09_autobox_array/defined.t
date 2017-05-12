use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [1, undef, 3];

ok $arr->defined(0),  'boxed defined ok';
ok !$arr->defined(1), 'boxed !defined ok';

done_testing
