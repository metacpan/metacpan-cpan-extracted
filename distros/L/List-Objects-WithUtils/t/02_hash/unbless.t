use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'hash';

my $hr = hash(foo => 1, bar => 2);

my $ref = $hr->unbless;
ok ref $ref eq 'HASH', 'unbless returned HASH';
is_deeply $ref, +{ foo => 1, bar => 2 }, 'unbless ok';


$ref = $hr->damn;
ok ref $ref eq 'HASH', 'damn returned HASH';
is_deeply $ref, +{ foo => 1, bar => 2 }, 'damn ok';


$ref = $hr->TO_JSON;
ok ref $ref eq 'HASH', 'TO_JSON returned HASH';
is_deeply $ref, +{ foo => 1, bar => 2 }, 'TO_JSON ok';


$ref = $hr->TO_ZPL;
ok ref $ref eq 'HASH', 'TO_ZPL returned HASH';
is_deeply $ref, +{ foo => 1, bar => 2 }, 'TO_ZPL ok';



done_testing;
