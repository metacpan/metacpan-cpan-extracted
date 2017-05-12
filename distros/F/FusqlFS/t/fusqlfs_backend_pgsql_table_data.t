use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
use FusqlFS::Backend::PgSQL::Table::Test;
if (FusqlFS::Backend::PgSQL::Table::Test->can('set_up'))
{ plan skip_all => 'Initialization failed' unless FusqlFS::Backend::PgSQL::Table::Test->set_up(); }
plan 'no_plan';

require_ok 'FusqlFS::Backend::PgSQL::Table::Data';
our $_tobj = FusqlFS::Backend::PgSQL::Table::Data->new();
isa_ok $_tobj, 'FusqlFS::Backend::PgSQL::Table::Data', 'Class FusqlFS::Backend::PgSQL::Table::Data instantiated';

our $_tcls = 'FusqlFS::Backend::PgSQL::Table::Data';
#!class FusqlFS::Backend::PgSQL::Table::Test


#=begin testing get
{
my $_tname = 'get';
my $_tcount = undef;

is $_tobj->get('fusqlfs_table', '1'), undef;
}


#=begin testing list
{
my $_tname = 'list';
my $_tcount = undef;

cmp_set $_tobj->list('fusqlfs_table'), [];
}


#=begin testing create after get list
{
my $_tname = 'create';
my $_tcount = undef;

ok $_tobj->create('fusqlfs_table', '1');
is_deeply $_tobj->get('fusqlfs_table', '1'), { id => 1 };
is_deeply $_tobj->list('fusqlfs_table'), [ 1 ];
}


#=begin testing rename after create
{
my $_tname = 'rename';
my $_tcount = undef;

isnt $_tobj->rename('fusqlfs_table', '1', '2'), undef;
is $_tobj->get('fusqlfs_table', '1'), undef;
is_deeply $_tobj->get('fusqlfs_table', '2'), { id => 2 };
is_deeply $_tobj->list('fusqlfs_table'), [ 2 ];
}


#=begin testing drop after rename
{
my $_tname = 'drop';
my $_tcount = undef;

isnt $_tobj->drop('fusqlfs_table', '2'), undef;
is $_tobj->get('fusqlfs_table', '2'), undef;
is_deeply $_tobj->list('fusqlfs_table'), [];
}

FusqlFS::Backend::PgSQL::Table::Test->tear_down() if FusqlFS::Backend::PgSQL::Table::Test->can('tear_down');

1;