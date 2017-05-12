use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
use FusqlFS::Backend::PgSQL::Table::Test;
if (FusqlFS::Backend::PgSQL::Table::Test->can('set_up'))
{ plan skip_all => 'Initialization failed' unless FusqlFS::Backend::PgSQL::Table::Test->set_up(); }
plan 'no_plan';

require_ok 'FusqlFS::Backend::PgSQL::Table::Struct';
our $_tobj = FusqlFS::Backend::PgSQL::Table::Struct->new();
isa_ok $_tobj, 'FusqlFS::Backend::PgSQL::Table::Struct', 'Class FusqlFS::Backend::PgSQL::Table::Struct instantiated';

our $_tcls = 'FusqlFS::Backend::PgSQL::Table::Struct';
#!class FusqlFS::Backend::PgSQL::Table::Test

my $new_field = {
    default => "''::character varying",
    dimensions => 0,
    nullable => 1,
    order => 2,
    type => 'character varying(255)',
};


#=begin testing get
{
my $_tname = 'get';
my $_tcount = undef;

is $_tobj->get('fusqlfs_table', 'unknown'), undef;
is_deeply $_tobj->get('fusqlfs_table', 'id'), {
    default => "nextval('fusqlfs_table_id_seq'::regclass)",
    dimensions => 0,
    nullable => 0,
    order => 1,
    type => 'integer',
};
}


#=begin testing list
{
my $_tname = 'list';
my $_tcount = undef;

is $_tobj->list('unknown'), undef;
cmp_set $_tobj->list('fusqlfs_table'), [ 'id' ];
}


#=begin testing create after get list
{
my $_tname = 'create';
my $_tcount = undef;

isnt $_tobj->create('fusqlfs_table', 'field'), undef;
is_deeply $_tobj->list('fusqlfs_table'), [ 'id', 'field' ];
is_deeply $_tobj->get('fusqlfs_table', 'field'), {
    default => 0,
    dimensions => 0,
    nullable => 0,
    order => 2,
    type => 'integer',
};
}


#=begin testing store after create
{
my $_tname = 'store';
my $_tcount = undef;

isnt $_tobj->store('fusqlfs_table', 'field', $new_field), undef;
is_deeply $_tobj->get('fusqlfs_table', 'field'), $new_field;
}


#=begin testing rename after store
{
my $_tname = 'rename';
my $_tcount = undef;

isnt $_tobj->rename('fusqlfs_table', 'field', 'new_field'), undef;
is_deeply $_tobj->list('fusqlfs_table'), [ 'id', 'new_field' ];
is $_tobj->get('fusqlfs_table', 'field'), undef;
is_deeply $_tobj->get('fusqlfs_table', 'new_field'), $new_field;
}


#=begin testing drop after rename
{
my $_tname = 'drop';
my $_tcount = undef;

isnt $_tobj->drop('fusqlfs_table', 'new_field'), undef;
is $_tobj->get('fusqlfs_table', 'new_field'), undef;
is_deeply $_tobj->list('fusqlfs_table'), [ 'id', '........pg.dropped.2........' ];
}

FusqlFS::Backend::PgSQL::Table::Test->tear_down() if FusqlFS::Backend::PgSQL::Table::Test->can('tear_down');

1;