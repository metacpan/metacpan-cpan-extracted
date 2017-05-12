use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
use FusqlFS::Backend::PgSQL::Table::Test;
if (FusqlFS::Backend::PgSQL::Table::Test->can('set_up'))
{ plan skip_all => 'Initialization failed' unless FusqlFS::Backend::PgSQL::Table::Test->set_up(); }
plan 'no_plan';

require_ok 'FusqlFS::Backend::PgSQL::Table::Triggers';
our $_tobj = FusqlFS::Backend::PgSQL::Table::Triggers->new();
isa_ok $_tobj, 'FusqlFS::Backend::PgSQL::Table::Triggers', 'Class FusqlFS::Backend::PgSQL::Table::Triggers instantiated';

our $_tcls = 'FusqlFS::Backend::PgSQL::Table::Triggers';
#!class FusqlFS::Backend::PgSQL::Table::Test

my $new_trigger = {
    'create.sql' => 'CREATE TRIGGER fusqlfs_trigger BEFORE INSERT OR UPDATE ON fusqlfs_table FOR EACH ROW EXECUTE PROCEDURE fusqlfs_function()',
    handler => \'functions/fusqlfs_function()',
    struct => {
        events => [ 'insert', 'update' ],
        for_each => 'row',
        when => 'before',
    },
};


#=begin testing get
{
my $_tname = 'get';
my $_tcount = undef;

is $_tobj->get('fusqlfs_table', 'xxxxx'), undef;
is $_tobj->get('xxxxx', 'xxxxx'), undef;
}


#=begin testing list
{
my $_tname = 'list';
my $_tcount = undef;

cmp_set $_tobj->list('fusqlfs_table'), [];
}


#=begin testing new
{
my $_tname = 'new';
my $_tcount = undef;

my $triggers = FusqlFS::Backend::PgSQL::Table::Triggers->new();
isa_ok $triggers, $_tcls;
}


#=begin testing store after get list
{
my $_tname = 'store';
my $_tcount = undef;

isnt $_tobj->create('fusqlfs_table', 'fusqlfs_trigger'), undef;
cmp_set $_tobj->list('fusqlfs_table'), [ 'fusqlfs_trigger' ];
is_deeply $_tobj->get('fusqlfs_table', 'fusqlfs_trigger'), $_tobj->{template};

isnt $_tobj->store('fusqlfs_table', 'fusqlfs_trigger', $new_trigger), undef;
cmp_set $_tobj->list('fusqlfs_table'), [ 'fusqlfs_trigger' ];
is_deeply $_tobj->get('fusqlfs_table', 'fusqlfs_trigger'), $new_trigger;
}


#=begin testing rename after store
{
my $_tname = 'rename';
my $_tcount = undef;

isnt $_tobj->rename('fusqlfs_table', 'fusqlfs_trigger', 'new_fusqlfs_trigger'), undef;
is $_tobj->get('fusqlfs_table', 'fusqlfs_trigger'), undef;
$new_trigger->{'create.sql'} =~ s/TRIGGER fusqlfs_trigger/TRIGGER new_fusqlfs_trigger/;
is_deeply $_tobj->get('fusqlfs_table', 'new_fusqlfs_trigger'), $new_trigger;
cmp_set $_tobj->list('fusqlfs_table'), [ 'new_fusqlfs_trigger' ];
}


#=begin testing drop after rename
{
my $_tname = 'drop';
my $_tcount = undef;

is $_tobj->drop('fusqlfs_table', 'fusqlfs_trigger'), undef;
isnt $_tobj->drop('fusqlfs_table', 'new_fusqlfs_trigger'), undef;
cmp_set $_tobj->list('fusqlfs_table'), [];
is $_tobj->get('fusqlfs_table', 'fusqlfs_trigger'), undef;
}

FusqlFS::Backend::PgSQL::Table::Test->tear_down() if FusqlFS::Backend::PgSQL::Table::Test->can('tear_down');

1;