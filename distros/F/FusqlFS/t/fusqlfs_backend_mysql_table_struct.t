use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
use FusqlFS::Backend::MySQL::Table::Test;
if (FusqlFS::Backend::MySQL::Table::Test->can('set_up'))
{ plan skip_all => 'Initialization failed' unless FusqlFS::Backend::MySQL::Table::Test->set_up(); }
plan 'no_plan';

require_ok 'FusqlFS::Backend::MySQL::Table::Struct';
our $_tobj = FusqlFS::Backend::MySQL::Table::Struct->new();
isa_ok $_tobj, 'FusqlFS::Backend::MySQL::Table::Struct', 'Class FusqlFS::Backend::MySQL::Table::Struct instantiated';

our $_tcls = 'FusqlFS::Backend::MySQL::Table::Struct';
#!class FusqlFS::Backend::MySQL::Table::Test

my $new_field = {
    collation => undef,
    comment => '',
    default => 0,
    extra => '',
    key => '',
    null => 0,
    privileges => [
        'select',
        'insert',
        'update',
        'references',
    ],
    type => 'int(11)',
};


#=begin testing get
{
my $_tname = 'get';
my $_tcount = undef;

is $_tobj->get('fusqlfs_table', 'unknown'), undef, 'Unknown field';
is_deeply $_tobj->get('fusqlfs_table', 'id'), {
    collation => undef,
    comment => '',
    default => undef,
    extra => 'auto_increment',
    key => 'PRI',
    null => 0,
    privileges => [
        'select',
        'insert',
        'update',
        'references',
    ],
    type => 'int(11)',
}, 'Known field';
}


#=begin testing list
{
my $_tname = 'list';
my $_tcount = undef;

is $_tobj->list('unknown'), undef, 'Unknown table';
cmp_set $_tobj->list('fusqlfs_table'), ['id', 'create.sql'], 'Test table listable';
}


#=begin testing create after get list
{
my $_tname = 'create';
my $_tcount = undef;

isnt $_tobj->create('fusqlfs_table', 'field'), undef, 'Create field';
is_deeply $_tobj->get('fusqlfs_table', 'field'), $new_field, 'New field exists';
is_deeply $_tobj->list('fusqlfs_table'), ['id', 'field', 'create.sql'], 'New field is listable';
}


#=begin testing store after create
{
my $_tname = 'store';
my $_tcount = undef;

$new_field->{type} = 'varchar(255)';
$new_field->{default} = undef;
$new_field->{collation} = 'utf8_general_ci';
$new_field->{null} = 1;
isnt $_tobj->store('fusqlfs_table', 'field', $new_field), undef, 'Field changed';
is_deeply $_tobj->get('fusqlfs_table', 'field'), $new_field, 'Field changed correctly';
}


#=begin testing rename after store
{
my $_tname = 'rename';
my $_tcount = undef;

isnt $_tobj->rename('fusqlfs_table', 'field', 'new_field'), undef, 'Field renamed';
is $_tobj->get('fusqlfs_table', 'field'), undef, 'New field is unaccessible by old name';
is_deeply $_tobj->get('fusqlfs_table', 'new_field'), $new_field, 'New field exists';
is_deeply $_tobj->list('fusqlfs_table'), ['id', 'new_field', 'create.sql'], 'New field is listable';
}


#=begin testing drop after rename
{
my $_tname = 'drop';
my $_tcount = undef;

isnt $_tobj->drop('fusqlfs_table', 'new_field'), undef, 'Field is dropped';
is $_tobj->get('fusqlfs_table', 'new_field'), undef, 'Field is not gettable';
is_deeply $_tobj->list('fusqlfs_table'), ['id', 'create.sql'], 'Field is not listable';
}

FusqlFS::Backend::MySQL::Table::Test->tear_down() if FusqlFS::Backend::MySQL::Table::Test->can('tear_down');

1;