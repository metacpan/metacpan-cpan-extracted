use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
use FusqlFS::Backend::PgSQL::Test;
if (FusqlFS::Backend::PgSQL::Test->can('set_up'))
{ plan skip_all => 'Initialization failed' unless FusqlFS::Backend::PgSQL::Test->set_up(); }
plan 'no_plan';

require_ok 'FusqlFS::Backend::PgSQL::Functions';
our $_tobj = FusqlFS::Backend::PgSQL::Functions->new();
isa_ok $_tobj, 'FusqlFS::Backend::PgSQL::Functions', 'Class FusqlFS::Backend::PgSQL::Functions instantiated';

our $_tcls = 'FusqlFS::Backend::PgSQL::Functions';
#!class FusqlFS::Backend::PgSQL::Test

my $created_func = {
    'content.sql' => 'SELECT 1;',
    'language' => \'languages/sql',
    'struct' => {
        result => 'integer',
        type => 'normal',
        volatility => 'volatile',
    },
    'owner' => $_tobj->{owner},
    'acl' => $_tobj->{acl},
};

my $new_func = {
    'content.sql' => 'SELECT $1 | $2;',
    'language' => \'languages/sql',
    'struct' => {
        result => 'integer',
        type => 'normal',
        volatility => 'immutable',
    },
    'owner' => $_tobj->{owner},
    'acl' => $_tobj->{acl},
};


#=begin testing get
{
my $_tname = 'get';
my $_tcount = undef;

my $row = $_tobj->get('xxxxx');
is $row, undef, '->get() result is sane';
}


#=begin testing list
{
my $_tname = 'list';
my $_tcount = undef;

my $list = $_tobj->list();
isa_ok $list, 'ARRAY', '->list() result is an array';
cmp_ok scalar(@$list), '==', 0, '->list() result is empty';
}


#=begin testing create after get list
{
my $_tname = 'create';
my $_tcount = undef;

isnt $_tobj->create('fusqlfs_func(integer)'), undef;
is_deeply $_tobj->list(), [ 'fusqlfs_func(integer)' ];
is_deeply $_tobj->get('fusqlfs_func(integer)'), $created_func;
}


#=begin testing rename after create
{
my $_tname = 'rename';
my $_tcount = undef;

isnt $_tobj->rename('fusqlfs_func(integer)', 'fusqlfs_func(integer, integer)'), undef;
is_deeply $_tobj->get('fusqlfs_func(integer, integer)', $created_func), $created_func;
is $_tobj->get('fusqlfs_func(integer)'), undef;
is_deeply $_tobj->list(), [ 'fusqlfs_func(integer, integer)' ];
}


#=begin testing store after rename
{
my $_tname = 'store';
my $_tcount = undef;

isnt $_tobj->store('fusqlfs_func(integer, integer)', $new_func), undef;
is_deeply $_tobj->get('fusqlfs_func(integer, integer)'), $new_func;
}


#=begin testing drop after store
{
my $_tname = 'drop';
my $_tcount = undef;

is $_tobj->drop('fusqlfs_func(integer)'), undef;
isnt $_tobj->drop('fusqlfs_func(integer, integer)'), undef;
is_deeply $_tobj->list(), [];
is $_tobj->get('fusqlfs_func(integer, integer)'), undef;
}

FusqlFS::Backend::PgSQL::Test->tear_down() if FusqlFS::Backend::PgSQL::Test->can('tear_down');

1;