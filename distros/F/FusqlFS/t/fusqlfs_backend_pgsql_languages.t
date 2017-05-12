use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
use FusqlFS::Backend::PgSQL::Test;
if (FusqlFS::Backend::PgSQL::Test->can('set_up'))
{ plan skip_all => 'Initialization failed' unless FusqlFS::Backend::PgSQL::Test->set_up(); }
plan 'no_plan';

require_ok 'FusqlFS::Backend::PgSQL::Languages';
our $_tobj = FusqlFS::Backend::PgSQL::Languages->new();
isa_ok $_tobj, 'FusqlFS::Backend::PgSQL::Languages', 'Class FusqlFS::Backend::PgSQL::Languages instantiated';

our $_tcls = 'FusqlFS::Backend::PgSQL::Languages';
#!class FusqlFS::Backend::PgSQL::Test

my $new_lang = {
    owner     => $_tobj->{owner},
    handler   => \"functions/plperl_call_handler()",
    validator => \"functions/plperl_validator(oid)",
    struct    => { ispl => 1, trusted => 1 },
};


#=begin testing get
{
my $_tname = 'get';
my $_tcount = undef;

is $_tobj->get('xxxxxx'), undef;
my $data = $_tobj->get('internal');
is_deeply $data, {
    owner => $_tobj->{owner},
    validator => \"functions/fmgr_internal_validator(oid)",
    struct => { ispl => 0, trusted => 0, },
};
}


#=begin testing list
{
my $_tname = 'list';
my $_tcount = undef;

my $list = $_tobj->list();
isa_ok $list, 'ARRAY';
cmp_set $list, [ qw(c internal sql plpgsql) ];
}


#=begin testing new
{
my $_tname = 'new';
my $_tcount = undef;

my $instance = FusqlFS::Backend::PgSQL::Languages->new();
isa_ok $instance, $_tcls;
}


#=begin testing create after get list
{
my $_tname = 'create';
my $_tcount = undef;

isnt $_tobj->create('plperl'), undef;
is_deeply $_tobj->get('plperl'), $new_lang;
cmp_set $_tobj->list(), [ qw(c internal sql plpgsql plperl) ];
}


#=begin testing store after create
{
my $_tname = 'store';
my $_tcount = undef;

isnt $_tobj->store('plperl', $new_lang), undef;
is_deeply $_tobj->get('plperl'), $new_lang;
}


#=begin testing rename after store
{
my $_tname = 'rename';
my $_tcount = undef;

isnt $_tobj->rename('plperl', 'plperl1'), undef;
cmp_set $_tobj->list(), [ qw(c internal sql plpgsql plperl1) ];
is $_tobj->get('plperl'), undef;
is_deeply $_tobj->get('plperl1'), $new_lang;
}


#=begin testing drop after rename
{
my $_tname = 'drop';
my $_tcount = undef;

isnt $_tobj->drop('plperl1'), undef;
cmp_set $_tobj->list(), [ qw(c internal sql plpgsql) ];
is $_tobj->get('plperl1'), undef;
}

FusqlFS::Backend::PgSQL::Test->tear_down() if FusqlFS::Backend::PgSQL::Test->can('tear_down');

1;