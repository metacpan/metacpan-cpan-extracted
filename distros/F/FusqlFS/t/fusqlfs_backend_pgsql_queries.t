use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
use FusqlFS::Backend::PgSQL::Test;
if (FusqlFS::Backend::PgSQL::Test->can('set_up'))
{ plan skip_all => 'Initialization failed' unless FusqlFS::Backend::PgSQL::Test->set_up(); }
plan 'no_plan';

require_ok 'FusqlFS::Backend::PgSQL::Queries';
our $_tobj = FusqlFS::Backend::PgSQL::Queries->new();
isa_ok $_tobj, 'FusqlFS::Backend::PgSQL::Queries', 'Class FusqlFS::Backend::PgSQL::Queries instantiated';

our $_tcls = 'FusqlFS::Backend::PgSQL::Queries';
#!class FusqlFS::Backend::PgSQL::Test


#=begin testing get
{
my $_tname = 'get';
my $_tcount = undef;

is $_tobj->get('query'), undef;
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

isnt $_tobj->create('query'), undef;
isa_ok $_tobj->get('query'), 'CODE';
is_deeply $_tobj->list(), [ 'query' ];
}


#=begin testing rename after create
{
my $_tname = 'rename';
my $_tcount = undef;

my $oldquery = $_tobj->get('query');
isnt $_tobj->rename('query', 'new_query'), undef;
is $_tobj->get('query'), undef;
is $_tobj->get('new_query'), $oldquery;
is_deeply $_tobj->list(), [ 'new_query' ];
}


#=begin testing drop after rename
{
my $_tname = 'drop';
my $_tcount = undef;

isnt $_tobj->drop('new_query'), undef;
is $_tobj->get('new_query'), undef;
is_deeply $_tobj->list(), [];
}

FusqlFS::Backend::PgSQL::Test->tear_down() if FusqlFS::Backend::PgSQL::Test->can('tear_down');

1;