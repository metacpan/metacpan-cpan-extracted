use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
use FusqlFS::Backend::PgSQL::Table::Test;
if (FusqlFS::Backend::PgSQL::Table::Test->can('set_up'))
{ plan skip_all => 'Initialization failed' unless FusqlFS::Backend::PgSQL::Table::Test->set_up(); }
plan 'no_plan';

require_ok 'FusqlFS::Backend::PgSQL::Table::Indices';
our $_tobj = FusqlFS::Backend::PgSQL::Table::Indices->new();
isa_ok $_tobj, 'FusqlFS::Backend::PgSQL::Table::Indices', 'Class FusqlFS::Backend::PgSQL::Table::Indices instantiated';

our $_tcls = 'FusqlFS::Backend::PgSQL::Table::Indices';
#!class FusqlFS::Backend::PgSQL::Table::Test

my $new_index = { 'id' => \'tables/fusqlfs_table/struct/id', '.order' => [ 'id' ], '.unique' => 1,
    'create.sql' => 'CREATE UNIQUE INDEX fusqlfs_index ON fusqlfs_table USING btree (id)' };


#=begin testing get
{
my $_tname = 'get';
my $_tcount = undef;

is_deeply $_tobj->get('fusqlfs_table', 'fusqlfs_table_pkey'), {
    '.primary' => 1,
    '.unique'  => 1,
    '.order'   => [ 'id' ],
    'id'       => \'tables/fusqlfs_table/struct/id',
    'create.sql' => 'CREATE UNIQUE INDEX fusqlfs_table_pkey ON fusqlfs_table USING btree (id)',
};
is $_tobj->get('fusqlfs_table', 'fusqlfs_index'), undef;
}


#=begin testing list
{
my $_tname = 'list';
my $_tcount = undef;

cmp_set $_tobj->list('fusqlfs_table'), [ 'fusqlfs_table_pkey' ];
}


#=begin testing create after get list
{
my $_tname = 'create';
my $_tcount = undef;

ok $_tobj->create('fusqlfs_table', 'fusqlfs_index');
is_deeply $_tobj->get('fusqlfs_table', 'fusqlfs_index'), {
    '.order' => [],
};
is_deeply $_tobj->list('fusqlfs_table'), [ 'fusqlfs_table_pkey', 'fusqlfs_index' ];
}


#=begin testing store after create
{
my $_tname = 'store';
my $_tcount = undef;

ok $_tobj->store('fusqlfs_table', 'fusqlfs_index', $new_index);
is_deeply $_tobj->get('fusqlfs_table', 'fusqlfs_index'), $new_index;
is_deeply [ sort(@{$_tobj->list('fusqlfs_table')}) ], [ sort('fusqlfs_table_pkey', 'fusqlfs_index') ];
}


#=begin testing rename after store
{
my $_tname = 'rename';
my $_tcount = undef;

isnt $_tobj->rename('fusqlfs_table', 'fusqlfs_index', 'new_fusqlfs_index'), undef;
is_deeply $_tobj->list('fusqlfs_table'), [ 'fusqlfs_table_pkey', 'new_fusqlfs_index' ];
is $_tobj->get('fusqlfs_table', 'fusqlfs_index'), undef;

$new_index->{'create.sql'} =~ s/INDEX fusqlfs_index ON/INDEX new_fusqlfs_index ON/;
is_deeply $_tobj->get('fusqlfs_table', 'new_fusqlfs_index'), $new_index;
}


#=begin testing drop after rename
{
my $_tname = 'drop';
my $_tcount = undef;

isnt $_tobj->drop('fusqlfs_table', 'new_fusqlfs_index'), undef;
is $_tobj->get('fusqlfs_table', 'new_fusqlfs_index'), undef;
is_deeply $_tobj->list('fusqlfs_table'), [ 'fusqlfs_table_pkey' ];
}

FusqlFS::Backend::PgSQL::Table::Test->tear_down() if FusqlFS::Backend::PgSQL::Table::Test->can('tear_down');

1;