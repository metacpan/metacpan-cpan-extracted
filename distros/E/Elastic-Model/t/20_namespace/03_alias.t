#!/usr/bin/perl

use strict;
use warnings;
use Test::More 0.96;
use Test::Deep;
use Test::Exception;

use lib 't/lib';

our $es;
do 'es.pl';

use_ok 'MyApp' || print 'Bail out';

my $model = new_ok( 'MyApp', [ es => $es ], 'Model' );
ok my $ns = $model->namespace('myapp'), 'Got ns';

ok $ns->index('myapp2')->create, 'Create index myapp2';
ok $ns->index('myapp3')->create, 'Create index myapp3';

wait_for_es();

isa_ok
    my $alias = $ns->alias(),
    'Elastic::Model::Alias',
    'alias myapp';

is $alias->name, 'myapp', 'Alias name is myapp';

## Alias to, add, remove ##

ok $alias->to( 'myapp2', 'myapp3' ), 'Alias to myapp2/3';
cmp_deeply $alias->aliased_to, { myapp2 => {}, myapp3 => {} },
    'Aliased to myapp2/3';

ok $alias->to(
    myapp2 => { routing => 'foo' },
    myapp3 => { filterb => { name => 'bar' } }
    ),
    'Alias with settings';
cmp_deeply $alias->aliased_to,
    {
    myapp2 => { index_routing => 'foo', search_routing => 'foo' },
    myapp3 => { filter => { term => { name => 'bar' } } }
    },
    'Aliased to myapp2/3';

ok $alias->to('myapp3'), 'Re-alias to only myapp3';
cmp_deeply $alias->aliased_to, { myapp3 => {} }, 'Is re-aliased';

ok $alias->add(
    myapp2 => { index_routing => 'foo', search_routing => 'bar' } ),
    'Add alias';
cmp_deeply $alias->aliased_to,
    {
    myapp2 => { index_routing => 'foo', search_routing => 'bar' },
    myapp3 => {}
    },
    'Alias added';

ok $alias->remove('myapp3'), 'Remove alias';
cmp_deeply $alias->aliased_to,
    { myapp2 => { index_routing => 'foo', search_routing => 'bar' } },
    'Alias removed';

throws_ok sub { $ns->alias('myapp3')->aliased_to }, qr/not an alias/,
    'index->aliased_to';

ok $alias->to(), 'Delete alias';
ok !$alias->is_alias, 'Alias deleted';

## Namespace->all_domains ##
cmp_bag [ $ns->all_domains ], ['myapp'], 'Domains - only ns name';
ok $alias->to( 'myapp2', 'myapp3' ), 'Alias to myapp2/3';
cmp_bag [ $ns->all_domains ], [ 'myapp', 'myapp2', 'myapp3' ],
    'Domains - all 3';

ok $ns->index('myapp4')->create, 'Create index myapp4';
ok $ns->alias('myapp5')->to( 'myapp3', 'myapp4' ), 'Add alias myapp5';
cmp_bag [ $ns->all_domains ], [ 'myapp', 'myapp2', 'myapp3', 'myapp5' ],
    'Domains - all 4 indices';

ok $alias->to(), 'Remove main alias';

## Fixed domains ##
isa_ok $ns = $model->namespace('myapp1'), 'Elastic::Model::Namespace',
    'Namespace2';
cmp_bag
    [ $ns->all_domains ],
    [ 'myapp1', 'myapp1_fixed' ],
    'Domains - ns name plus fixed';

ok $ns->alias->to( 'myapp2', 'myapp3', 'myapp4' ), 'Alias to myapp2/3/4';
cmp_bag
    [ $ns->all_domains ],
    [ 'myapp1', 'myapp1_fixed', 'myapp2', 'myapp3', 'myapp4', 'myapp5' ],
    'Domains - all plus myapp5';

done_testing;

__END__
