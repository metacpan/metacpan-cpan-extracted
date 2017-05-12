use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
use FusqlFS::Backend::PgSQL::Test;
if (FusqlFS::Backend::PgSQL::Test->can('set_up'))
{ plan skip_all => 'Initialization failed' unless FusqlFS::Backend::PgSQL::Test->set_up(); }
plan 'no_plan';

require_ok 'FusqlFS::Backend::PgSQL::Views';
our $_tobj = FusqlFS::Backend::PgSQL::Views->new();
isa_ok $_tobj, 'FusqlFS::Backend::PgSQL::Views', 'Class FusqlFS::Backend::PgSQL::Views instantiated';

our $_tcls = 'FusqlFS::Backend::PgSQL::Views';
#!class FusqlFS::Backend::PgSQL::Test


#=begin testing get
{
my $_tname = 'get';
my $_tcount = undef;

is $_tobj->get('unknown'), undef;
}


#=begin testing list
{
my $_tname = 'list';
my $_tcount = undef;

cmp_set $_tobj->list(), [];
}


#=begin testing create after get list
{
my $_tname = 'create';
my $_tcount = undef;

isnt $_tobj->create('fusqlfs_view'), undef;
is_deeply $_tobj->list(), [ 'fusqlfs_view' ];
is_deeply $_tobj->get('fusqlfs_view'), { 'content.sql' => 'SELECT 1;', owner => $_tobj->{owner} };
}


#=begin testing store after create
{
my $_tname = 'store';
my $_tcount = undef;

isnt $_tobj->store('fusqlfs_view', { 'content.sql' => 'SELECT 2' }), undef;
is_deeply $_tobj->get('fusqlfs_view'), { 'content.sql' => 'SELECT 2;', owner => $_tobj->{owner} };
}


#=begin testing rename after store
{
my $_tname = 'rename';
my $_tcount = undef;

isnt $_tobj->rename('fusqlfs_view', 'new_fusqlfs_view'), undef;
is $_tobj->get('fusqlfs_view'), undef;
is_deeply $_tobj->get('new_fusqlfs_view'), { 'content.sql' => 'SELECT 2;', owner => $_tobj->{owner} };
is_deeply $_tobj->list(), [ 'new_fusqlfs_view' ];
}


#=begin testing drop after rename
{
my $_tname = 'drop';
my $_tcount = undef;

isnt $_tobj->drop('new_fusqlfs_view'), undef;
is_deeply $_tobj->list(), [];
is $_tobj->get('new_fusqlfs_view'), undef;
}

FusqlFS::Backend::PgSQL::Test->tear_down() if FusqlFS::Backend::PgSQL::Test->can('tear_down');

1;