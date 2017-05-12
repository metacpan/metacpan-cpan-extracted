#!/usr/bin/perl

use strict;
use warnings;
use Test::More 0.96;
use Test::Moose;
use Test::Deep;

use lib 't/lib';

BEGIN {
    use_ok 'MyApp' || print 'Bail out';
}

my $model = new_ok( 'MyApp', [], 'Model' );

isa_ok
    my $ns = $model->namespace('myapp'),
    'Elastic::Model::Namespace',
    'Namespace';

isa_ok
    my $ns2 = $model->namespace('myapp1'),
    'Elastic::Model::Namespace',
    'Namespace2';

## attr:name ##
is $ns->name,  'myapp',  'Namespace name';
is $ns2->name, 'myapp1', 'Namespace2 name';

## attr:type ##
isa_ok $ns->types, 'HASH', 'Types';
cmp_bag [ $ns->all_types ], [ 'user', 'post' ], 'All type names';
isa_ok my $class = $ns->class_for_type('user'), 'MyApp::User', 'Type user';
like $class, qr/WRAPPED/, 'User class is wrapped';
isa_ok $class = $ns->class_for_type('post'), 'MyApp::Post', 'Type post';
like $class, qr/WRAPPED/, 'Post class is wrapped';
is $ns->class_for_type('user'), $ns2->class_for_type('user'),
    'Reused doc class wrappers';

## attr:fixed_domains ##
cmp_bag $ns->fixed_domains, [], 'Namespace has no fixed domains';
cmp_bag $ns2->fixed_domains, ['myapp1_fixed'],
    'Namespace 2 has fixed domains';

## method:index ##
isa_ok $ns->index, 'Elastic::Model::Index', 'Index';
is $ns->index->name, $ns->name, 'Index has namespace name';
is $ns->index('foo')->name, 'foo', 'Index(foo)';
isa_ok $ns2->index, 'Elastic::Model::Index', 'Index2';
is $ns2->index->name, $ns2->name, 'Index2 has namespace2 name';
is $ns2->index('foo')->name, 'foo', 'Index2(foo)';

## method:alias ##
isa_ok $ns->alias, 'Elastic::Model::Alias', 'Alias';
is $ns->alias->name, $ns->name, 'Alias has namespace name';
is $ns->alias('foo')->name, 'foo', 'Alias(foo)';
isa_ok $ns2->alias, 'Elastic::Model::Alias', 'Alias2';
is $ns2->alias->name, $ns2->name, 'Alias2 has namespace2 name';
is $ns2->alias('foo')->name, 'foo', 'Alias2(foo)';

## method:mappings ##
isa_ok my $all_mappings = $ns->mappings, 'HASH', 'All mappings';
cmp_bag [ keys %$all_mappings ], [ 'user', 'post' ], 'Has all types';
isa_ok my $user_mapping = $ns->mappings('user'), 'HASH', 'User mapping';
cmp_bag [ keys %$user_mapping ], ['user'], 'Has just user';
cmp_deeply $user_mapping->{user}, $all_mappings->{user},
    'User mappings equal';

## method:all_domains tested in 03_alias.t ##

done_testing;

__END__

