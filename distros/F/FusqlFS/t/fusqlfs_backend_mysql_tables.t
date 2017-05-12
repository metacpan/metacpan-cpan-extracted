use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
use FusqlFS::Backend::MySQL::Test;
if (FusqlFS::Backend::MySQL::Test->can('set_up'))
{ plan skip_all => 'Initialization failed' unless FusqlFS::Backend::MySQL::Test->set_up(); }
plan 'no_plan';

require_ok 'FusqlFS::Backend::MySQL::Tables';
our $_tobj = FusqlFS::Backend::MySQL::Tables->new();
isa_ok $_tobj, 'FusqlFS::Backend::MySQL::Tables', 'Class FusqlFS::Backend::MySQL::Tables instantiated';

our $_tcls = 'FusqlFS::Backend::MySQL::Tables';
#!class FusqlFS::Backend::MySQL::Test


#=begin testing get
{
my $_tname = 'get';
my $_tcount = undef;

is $_tobj->get('fusqlfs_table'), undef, 'Test table doesn\'t exist';
}


#=begin testing list
{
my $_tname = 'list';
my $_tcount = undef;

is_deeply $_tobj->list(), [], 'Tables list is sane';
}


#=begin testing create after get list
{
my $_tname = 'create';
my $_tcount = undef;

isnt $_tobj->create('fusqlfs_table'), undef, 'Table created';
is_deeply $_tobj->get('fusqlfs_table'), $_tobj->{subpackages}, 'New table is sane';
is_deeply $_tobj->list(), ['fusqlfs_table'], 'New table is listed';
}


#=begin testing rename after create
{
my $_tname = 'rename';
my $_tcount = undef;

isnt $_tobj->rename('fusqlfs_table', 'new_fusqlfs_table'), undef, 'Table renamed';
is $_tobj->get('fusqlfs_table'), undef, 'Table is unaccessible under old name';
is_deeply $_tobj->get('new_fusqlfs_table'), $_tobj->{subpackages}, 'Table renamed correctly';
is_deeply $_tobj->list(), ['new_fusqlfs_table'], 'Table is listed under new name';
}


#=begin testing drop after rename
{
my $_tname = 'drop';
my $_tcount = undef;

isnt $_tobj->drop('new_fusqlfs_table'), undef, 'Table dropped';
is $_tobj->get('new_fusqlfs_table'), undef, 'Table dropped correctly';
is_deeply $_tobj->list(), [], 'Tables list is empty';
}

FusqlFS::Backend::MySQL::Test->tear_down() if FusqlFS::Backend::MySQL::Test->can('tear_down');

1;