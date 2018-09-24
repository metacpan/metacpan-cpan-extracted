#!/usr/bin/env perl

use warnings;
use strict;

use lib './';

use Test::More;
use MikroTik::Client::Query 'build_query';

my $r = build_query({a => 1, b => 2, c => 3, d => 4});
is_deeply $r, ['?a=1', '?b=2', '?c=3', '?d=4', '?#&&&'], 'simple AND';

$r = build_query([a => 1, b => 2, c => 3]);
is_deeply $r, ['?a=1', '?b=2', '?c=3', '?#||'], 'simple OR';

$r = build_query({-and => [a => 1, b => 2, c => 3]});
is_deeply $r, ['?a=1', '?b=2', '?c=3', '?#&&'], 'specific logic AND';

$r = build_query({-or => {a => 1, b => 2, c => 3, d => 4}});
is_deeply $r, ['?a=1', '?b=2', '?c=3', '?d=4', '?#|||'], 'specific logic OR';

$r = build_query({-or => {a => 1, b => 2}, -and => [c => 3, d => 4, e => 5]});
is_deeply $r, ['?c=3', '?d=4', '?e=5', '?#&&', '?a=1', '?b=2', '?#|', '?#&'],
    'nested ops';

$r = build_query(
    [
        -or  => {a => 1, b => 2, -and => {e => 5, f => 6, g => 7}},
        -and => [c => 3, d => 4],
        {h => 8, i => 9}
    ]
);
is_deeply $r,
    [
    '?e=5', '?f=6', '?g=7', '?#&&', '?a=1', '?b=2', '?#||', '?c=3',
    '?d=4', '?#&',  '?h=8', '?i=9', '?#&',  '?#||'
    ],
    'nested ops 2';

$r = build_query(\['?e=5', '?f=6', '?g=7', '?#&&', '?a=1', '?b=2', '?#||']);
is_deeply $r, ['?e=5', '?f=6', '?g=7', '?#&&', '?a=1', '?b=2', '?#||'],
    'literal query';

$r = build_query();
is_deeply $r, [], 'empty query';

$r = build_query({a => [1, 2, 3]});
is_deeply $r, ['?a=1', '?a=2', '?a=3', '?#||'], 'arrayref value';

$r = build_query([a => [-and => 1, 2, 3]]);
is_deeply $r, ['?a=1', '?a=2', '?a=3', '?#&&'],
    'arrayref value with specific logic';

$r = build_query({a => {'>', [1, 2, 3]}});
is_deeply $r, ['?a>1', '?a>2', '?a>3', '?#||'],
    'arrayref value with specific operator';

$r = build_query({a => {'=', [-and => 1, 2, 3]}});
is_deeply $r, ['?a=1', '?a=2', '?a=3', '?#&&'],
    'arrayref value with logic and operator';

$r = build_query({a => {'<' => 3, '>' => 1}});
is_deeply $r, ['?a<3', '?a>1', '?#&'], 'hashref value';

$r = build_query({a => [-or => {'>', 1}, {'<', 2}, {'>', 3, '<', 4}]});
is_deeply $r, ['?a>1', '?a<2', '?a<4', '?a>3', '?#&', '?#||'],
    'list of hashrefs';

$r = build_query({a => {-not => 1}, -has => 'b', -has_not => 'c'});
is_deeply $r, ['?b', '?-c', '?a=1', '?#!', '?#&&'], 'special cases';

$r = build_query({a => {-not => [-and => 1, 2, 3]}});
is_deeply $r, ['?a=1', '?#!', '?a=2', '?#!', '?a=3', '?#!', '?#&&'],
    '-not with arrayref value';

$r = build_query([[], a => 1, [{}, {}, \[]], b => [], c => 5, d => {}]);
is_deeply $r, ['?a=1', '?c=5', '?#|'], 'ignore empty structs';

$r = build_query([a => [{'=', []}, 2, {}]]);
is_deeply $r, ['?a=2'], 'ignore empty structs';

my $err;
$SIG{__WARN__} = sub { $err = $_[0] };
$r = build_query([a => undef, b => [1, undef, 2], c => {'=', undef}]);
ok !$err, 'no warning';
is_deeply $r, ['?a=', '?b=1', '?b=', '?b=2', '?#||', '?c=', '?#||'],
    'right result';

done_testing();

