use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
use FusqlFS::Backend::PgSQL::Table::Test;
if (FusqlFS::Backend::PgSQL::Table::Test->can('set_up'))
{ plan skip_all => 'Initialization failed' unless FusqlFS::Backend::PgSQL::Table::Test->set_up(); }
plan 'no_plan';

require_ok 'FusqlFS::Backend::PgSQL::Table::Constraints';
our $_tobj = FusqlFS::Backend::PgSQL::Table::Constraints->new();
isa_ok $_tobj, 'FusqlFS::Backend::PgSQL::Table::Constraints', 'Class FusqlFS::Backend::PgSQL::Table::Constraints instantiated';

our $_tcls = 'FusqlFS::Backend::PgSQL::Table::Constraints';
#!class FusqlFS::Backend::PgSQL::Table::Test

my $new_constraint = {
    'content.sql' => 'CHECK (id > 5)',
    '.type' => 'c',
};


#=begin testing get
{
my $_tname = 'get';
my $_tcount = undef;

is $_tobj->get('fusqlfs_table', 'unknown'), undef;
is_deeply $_tobj->get('fusqlfs_table', 'fusqlfs_table_pkey'), { 'content.sql' => 'PRIMARY KEY (id)', '.type' => 'p' };
}


#=begin testing list
{
my $_tname = 'list';
my $_tcount = undef;

#is $_tobj->list('unknown'), undef;
cmp_set $_tobj->list('fusqlfs_table'), [ 'fusqlfs_table_pkey' ];
}


#=begin testing create after get list
{
my $_tname = 'create';
my $_tcount = undef;

isnt $_tobj->create('fusqlfs_table', 'fusqlfs_constraint'), undef;
isnt $_tobj->get('fusqlfs_table', 'fusqlfs_constraint'), $_tobj->{template};
is_deeply $_tobj->get('fusqlfs_table', 'fusqlfs_constraint'), $_tobj->{template};
is_deeply [ sort(@{$_tobj->list('fusqlfs_table')}) ], [ sort('fusqlfs_table_pkey', 'fusqlfs_constraint') ];
}


#=begin testing store after create
{
my $_tname = 'store';
my $_tcount = undef;

isnt $_tobj->store('fusqlfs_table', 'fusqlfs_constraint', $new_constraint), undef;
is_deeply $_tobj->get('fusqlfs_table', 'fusqlfs_constraint'), $new_constraint;
}


#=begin testing rename after store
{
my $_tname = 'rename';
my $_tcount = undef;

isnt $_tobj->rename('fusqlfs_table', 'fusqlfs_constraint', 'new_fusqlfs_constraint'), undef;
is $_tobj->get('fusqlfs_table', 'fusqlfs_constraint'), undef;
is_deeply $_tobj->get('fusqlfs_table', 'new_fusqlfs_constraint'), $new_constraint;
is_deeply [ sort(@{$_tobj->list('fusqlfs_table')}) ], [ sort('fusqlfs_table_pkey', 'new_fusqlfs_constraint') ];
}


#=begin testing drop after rename
{
my $_tname = 'drop';
my $_tcount = undef;

isnt $_tobj->drop('fusqlfs_table', 'new_fusqlfs_constraint'), undef;
is $_tobj->get('fusqlfs_table', 'new_fusqlfs_constraint'), undef;
is_deeply $_tobj->list('fusqlfs_table'), [ 'fusqlfs_table_pkey' ];
}

FusqlFS::Backend::PgSQL::Table::Test->tear_down() if FusqlFS::Backend::PgSQL::Table::Test->can('tear_down');

1;