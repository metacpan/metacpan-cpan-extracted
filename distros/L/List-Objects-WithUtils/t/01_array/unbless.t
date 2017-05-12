use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array(1 .. 3);

my $ref = $arr->unbless;
ok ref $ref eq 'ARRAY', 'unbless returned ARRAY';
is_deeply $ref, [ 1 .. 3 ], 'unbless ok';

ok ref array->unbless eq 'ARRAY', 'empty array unbless ok';


$ref = $arr->damn;
ok ref $ref eq 'ARRAY', 'damn returned ARRAY';
is_deeply $ref, [ 1 .. 3 ], 'damn ok';


$ref = $arr->TO_JSON;
ok ref $ref eq 'ARRAY', 'TO_JSON returned ARRAY';
is_deeply $ref, [ 1 .. 3 ], 'TO_JSON ok';


$ref = $arr->TO_ZPL;
ok ref $ref eq 'ARRAY', 'TO_ZPL returned ARRAY';
is_deeply $ref, [ 1 .. 3 ], 'TO_ZPL ok';



done_testing;
