use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array(1 .. 3);

ok $arr->exists(0),     'array exists ok';
ok $arr->exists(1),     'array exists(1) ok';
ok $arr->exists(2),     'array exists(2) ok';
ok !$arr->exists(3),    '!array exists(3) ok';
ok !$arr->exists(4),    '!array exists(4) ok';

ok $arr->exists(-1),    'array exists(-1) ok';
ok $arr->exists(-2),    'array exists(-2) ok';
ok $arr->exists(-3),    'array exists(-3) ok';
ok !$arr->exists(-4),   'array !exists(-4) ok';

ok !array->exists(0),   'empty array !exists(0) ok';
ok !array->exists(1),   'empty array !exists(1) ok'; 
ok !array->exists(-1),  'empty array !exists(-1) ok';

ok array(1)->exists(0),   'single-element array exists(0) ok';
ok !array(1)->exists(1),  'single-element array !exists(1) ok';
ok !array(1)->exists(2),  'single-element array !exists(2) ok';
ok array(1)->exists(-1),  'single-element array exists(-1) ok';
ok !array(1)->exists(-2), 'single-element array exists(-2) ok';

done_testing
