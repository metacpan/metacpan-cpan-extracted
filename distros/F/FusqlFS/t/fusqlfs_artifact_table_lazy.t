use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
plan 'no_plan';

require_ok 'FusqlFS::Artifact::Table::Lazy';
our $_tobj = FusqlFS::Artifact::Table::Lazy->new();
isa_ok $_tobj, 'FusqlFS::Artifact::Table::Lazy', 'Class FusqlFS::Artifact::Table::Lazy instantiated';

our $_tcls = 'FusqlFS::Artifact::Table::Lazy';

#=begin testing clone
{
my $_tname = 'clone';
my $_tcount = undef;

is_deeply FusqlFS::Artifact::Table::Lazy::clone({ a => 1, b => 2, c => 3 }), { a => 1, b => 2, c => 3 };
is_deeply FusqlFS::Artifact::Table::Lazy::clone([ 3, 2, 1 ]), [ 3, 2, 1 ];
is_deeply FusqlFS::Artifact::Table::Lazy::clone(\'string'), \'string';
is_deeply FusqlFS::Artifact::Table::Lazy::clone({ a => [ 3, 2, 1 ], b => { c => 1, d => [ 6, \5, 4 ] }, c => \"string" }),
    { a => [ 3, 2, 1 ], b => { c => 1, d => [ 6, \5, 4 ] }, c => \"string" };
}


#=begin testing get
{
my $_tname = 'get';
my $_tcount = undef;

is $_tobj->get('table', 'name'), undef, 'get is sane';
is $_tobj->get('table', 'name'), undef, 'get has no side effects';
}


#=begin testing list
{
my $_tname = 'list';
my $_tcount = undef;

is_deeply $_tobj->list('table'), [], 'list is sane';
}


#=begin testing create after get list
{
my $_tname = 'create';
my $_tcount = undef;

isnt $_tobj->create('table', 'name'), undef;
isnt $_tobj->get('table', 'name'), $_tobj->{template};
is_deeply $_tobj->get('table', 'name'), $_tobj->{template};
is_deeply $_tobj->list('table'), [ 'name' ];
}


#=begin testing rename after create
{
my $_tname = 'rename';
my $_tcount = undef;

is $_tobj->rename('table', 'aname', 'anewname'), undef;
is $_tobj->get('table', 'aname'), undef;
is $_tobj->get('table', 'anewname'), undef;

isnt $_tobj->rename('table', 'name', 'newname'), undef;
is $_tobj->get('table', 'name'), undef;
is_deeply $_tobj->get('table', 'newname'), $_tobj->{template};
is_deeply $_tobj->list('table'), [ 'newname' ];
}


#=begin testing drop after rename
{
my $_tname = 'drop';
my $_tcount = undef;

isnt $_tobj->drop('table', 'newname'), undef;
is $_tobj->get('table', 'newname'), undef;
is_deeply $_tobj->list('table'), [];
}

1;