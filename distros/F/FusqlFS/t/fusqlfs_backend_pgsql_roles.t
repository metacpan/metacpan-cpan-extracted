use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
use FusqlFS::Backend::PgSQL::Test;
if (FusqlFS::Backend::PgSQL::Test->can('set_up'))
{ plan skip_all => 'Initialization failed' unless FusqlFS::Backend::PgSQL::Test->set_up(); }
plan 'no_plan';

require_ok 'FusqlFS::Backend::PgSQL::Roles';
our $_tobj = FusqlFS::Backend::PgSQL::Roles->new();
isa_ok $_tobj, 'FusqlFS::Backend::PgSQL::Roles', 'Class FusqlFS::Backend::PgSQL::Roles instantiated';

our $_tcls = 'FusqlFS::Backend::PgSQL::Roles';
#!class FusqlFS::Backend::PgSQL::Test

my $new_role = {
    struct => {
        can_login => 1,
        cat_update => 1,
        config => undef,
        conn_limit => 1,
        create_db => 1,
        create_role => 1,
        inherit => 0,
        superuser => 1,
        valid_until => '2010-01-01 00:00:00+02',
    },
    postgres => \"roles/postgres",
    owned => $_tobj->{owned},
};


#=begin testing get
{
my $_tname = 'get';
my $_tcount = undef;

is $_tobj->get('unknown'), undef, 'Unknown role not exists';
is_deeply $_tobj->get('postgres'), { struct => {
    can_login => 1,
    cat_update => 1,
    config => undef,
    conn_limit => '-1',
    create_db => 1,
    create_role => 1,
    inherit => 1,
    superuser => 1,
    valid_until => undef,
},
owned => $_tobj->{owned},
}, 'Known role is sane';
}


#=begin testing list
{
my $_tname = 'list';
my $_tcount = undef;

cmp_deeply $_tobj->list(), supersetof('postgres'), 'Roles list is sane';
}


#=begin testing create after get list
{
my $_tname = 'create';
my $_tcount = undef;

isnt $_tobj->create('fusqlfs_test'), undef, 'Role created';
is_deeply $_tobj->get('fusqlfs_test')->{struct}, {
    can_login => 0,
    cat_update => 0,
    config => undef,
    conn_limit => '-1',
    create_db => 0,
    create_role => 0,
    inherit => 1,
    superuser => 0,
    valid_until => undef,
}, 'New role is sane';

my $list = $_tobj->list();
ok grep { $_ eq 'fusqlfs_test' } @$list;
}


#=begin testing store after create
{
my $_tname = 'store';
my $_tcount = undef;

isnt $_tobj->store('fusqlfs_test', $new_role), undef, 'Role saved';
is_deeply $_tobj->get('fusqlfs_test'), $new_role, 'Role saved correctly';
}


#=begin testing rename after store
{
my $_tname = 'rename';
my $_tcount = undef;

isnt $_tobj->rename('fusqlfs_test', 'new_fusqlfs_test'), undef, 'Role renamed';
is_deeply $_tobj->get('new_fusqlfs_test'), $new_role, 'Role renamed correctly';
is $_tobj->get('fusqlfs_test'), undef, 'Role is unaccessable under old name';
my $list = $_tobj->list();
ok grep { $_ eq 'new_fusqlfs_test' } @$list;
ok !grep { $_ eq 'fusqlfs_test' } @$list;
}


#=begin testing drop after rename
{
my $_tname = 'drop';
my $_tcount = undef;

isnt $_tobj->drop('new_fusqlfs_test'), undef, 'Role deleted';
is $_tobj->get('new_fusqlfs_test'), undef, 'Deleted role is absent';
my $list = $_tobj->list();
ok !grep { $_ eq 'new_fusqlfs_test' } @$list;
}

FusqlFS::Backend::PgSQL::Test->tear_down() if FusqlFS::Backend::PgSQL::Test->can('tear_down');

1;