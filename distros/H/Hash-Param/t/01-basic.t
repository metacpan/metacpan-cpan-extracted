#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;
plan qw/no_plan/;

use Hash::Param;

my $store;
$store = Hash::Param->new(parameters => {
    qw/a 1 b 2 c 3/,
    d => [qw/4 5 6 7/],
});

is($store->parameter('a'), '1');
is($store->param('a'), '1');
is($store->get('a'), '1');

is($store->parameter('c'), '3');
is($store->param('c'), '3');
is($store->get('c'), '3');

is($store->parameter('d'), '4');
is($store->param('d'), '4');
is($store->get('d'), '4');

cmp_deeply([ $store->parameter('d') ], [ qw/4 5 6 7/ ]);
cmp_deeply([ $store->param('d') ], [ qw/4 5 6 7/ ]);
cmp_deeply([ $store->get('d') ], [ qw/4 5 6 7/ ]);

cmp_deeply(scalar $store->get(qw/c b a d/), [ 3, 2, 1, [ qw/4 5 6 7/ ] ]);
cmp_deeply(scalar $store->params(qw/c b a d/), [ 3, 2, 1, [ qw/4 5 6 7/ ] ]);

$store->parameter(a => 8);
cmp_deeply(scalar $store->get(qw/c b a d/), [ 3, 2, 8, [ qw/4 5 6 7/ ] ]);
cmp_deeply(scalar $store->params(qw/c b a d/), [ 3, 2, 8, [ qw/4 5 6 7/ ] ]);

$store->parameter(a => 8, 9);
cmp_deeply(scalar $store->get(qw/c b a d/), [ 3, 2, [ 8, 9], [ qw/4 5 6 7/ ] ]);
cmp_deeply(scalar $store->params(qw/c b a d/), [ 3, 2, [ 8, 9], [ qw/4 5 6 7/ ] ]);

cmp_deeply(scalar $store->slice(qw/a b c d/), { a => [ 8, 9 ], b => 2, c => 3, d => [ qw/4 5 6 7/ ] });
cmp_deeply(scalar $store->slice(qw/a b c/), { a => [ 8, 9 ], b => 2, c => 3 });

cmp_deeply([ sort $store->params ], [qw/a b c d/]);
cmp_deeply(scalar $store->params, { a => [ 8, 9 ], b => 2, c => 3, d => [ qw/4 5 6 7/ ] });

cmp_ok(scalar $store->params, '==', $store->{parameters});
cmp_ok(scalar $store->params('d')->[0], '==', $store->{parameters}->{d});

$store = Hash::Param->new(qw/is ro/, parameters => {
    qw/a 1 b 2 c 3/,
    d => [qw/4 5 6 7/],
});

is($store->parameter('a'), '1');
is($store->param('a'), '1');
is($store->get('a'), '1');

is($store->parameter('c'), '3');
is($store->param('c'), '3');
is($store->get('c'), '3');

is($store->parameter('d'), '4');
is($store->param('d'), '4');
is($store->get('d'), '4');

cmp_deeply([ $store->parameter('d') ], [ qw/4 5 6 7/ ]);
cmp_deeply([ $store->param('d') ], [ qw/4 5 6 7/ ]);
cmp_deeply([ $store->get('d') ], [ qw/4 5 6 7/ ]);

cmp_deeply(scalar $store->get(qw/c b a d/), [ 3, 2, 1, [ qw/4 5 6 7/ ] ]);
cmp_deeply(scalar $store->params(qw/c b a d/), [ 3, 2, 1, [ qw/4 5 6 7/ ] ]);

throws_ok {
    $store->parameter(a => 8);
} qr/Hash::Param::parameter\(\): Unable to modify readonly parameter "a"/;

throws_ok {
    $store->parameter(a => 8, 9);
} qr/Hash::Param::parameter\(\): Unable to modify readonly parameter "a"/;

cmp_deeply(scalar $store->slice(qw/a b c d/), { a => 1, b => 2, c => 3, d => [ qw/4 5 6 7/ ] });
cmp_deeply(scalar $store->slice(qw/a b c/), { a => 1, b => 2, c => 3 });

cmp_deeply([ sort $store->params ], [qw/a b c d/]);
cmp_deeply(scalar $store->params, { a => 1, b => 2, c => 3, d => [ qw/4 5 6 7/ ] });

cmp_ok(scalar $store->params, '!=', $store->{parameters});
cmp_ok(scalar $store->params('d')->[0], '!=', $store->{parameters}->{d});
