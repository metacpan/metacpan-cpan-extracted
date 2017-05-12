use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
use FusqlFS::Backend::PgSQL::Test;
if (FusqlFS::Backend::PgSQL::Test->can('set_up'))
{ plan skip_all => 'Initialization failed' unless FusqlFS::Backend::PgSQL::Test->set_up(); }
plan 'no_plan';

require_ok 'FusqlFS::Backend::PgSQL::Sequences';
our $_tobj = FusqlFS::Backend::PgSQL::Sequences->new();
isa_ok $_tobj, 'FusqlFS::Backend::PgSQL::Sequences', 'Class FusqlFS::Backend::PgSQL::Sequences instantiated';

our $_tcls = 'FusqlFS::Backend::PgSQL::Sequences';
#!class FusqlFS::Backend::PgSQL::Test

my $new_sequence = { struct => {
    cache_value => 4,
    increment_by => 2,
    is_called => 0,
    is_cycled => 1,
    last_value => 6,
    log_cnt => 0,
    max_value => 1000,
    min_value => '-10',
    sequence_name => 'fusqlfs_sequence',
    start_value => 1,
}, owner => $_tobj->{owner}, acl => $_tobj->{acl} };


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

isnt $_tobj->create('fusqlfs_sequence'), undef;
is_deeply $_tobj->get('fusqlfs_sequence'), { struct => {
    cache_value => 1,
    increment_by => 1,
    is_called => 0,
    is_cycled => 0,
    last_value => 1,
    log_cnt => 0,
    max_value => 9223372036854775807,
    min_value => 1,
    sequence_name => 'fusqlfs_sequence',
    start_value => 1,
}, owner => $_tobj->{owner}, acl => $_tobj->{acl} };
is_deeply $_tobj->list(), [ 'fusqlfs_sequence' ];
}


#=begin testing store after create
{
my $_tname = 'store';
my $_tcount = undef;

isnt $_tobj->store('fusqlfs_sequence', $new_sequence), undef;
is_deeply $_tobj->get('fusqlfs_sequence'), $new_sequence;
}


#=begin testing rename after store
{
my $_tname = 'rename';
my $_tcount = undef;

isnt $_tobj->rename('fusqlfs_sequence', 'new_fusqlfs_sequence'), undef;
is $_tobj->get('fusqlfs_sequence'), undef;
is_deeply $_tobj->get('new_fusqlfs_sequence'), $new_sequence;
is_deeply $_tobj->list(), [ 'new_fusqlfs_sequence' ];
}


#=begin testing drop after rename
{
my $_tname = 'drop';
my $_tcount = undef;

isnt $_tobj->drop('new_fusqlfs_sequence'), undef;
is $_tobj->get('new_fusqlfs_sequence'), undef;
is_deeply $_tobj->list(), [];
}

FusqlFS::Backend::PgSQL::Test->tear_down() if FusqlFS::Backend::PgSQL::Test->can('tear_down');

1;