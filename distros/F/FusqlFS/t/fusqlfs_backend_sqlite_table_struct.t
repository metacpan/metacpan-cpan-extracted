use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
use FusqlFS::Backend::SQLite::Table::Test;
if (FusqlFS::Backend::SQLite::Table::Test->can('set_up'))
{ plan skip_all => 'Initialization failed' unless FusqlFS::Backend::SQLite::Table::Test->set_up(); }
plan 'no_plan';

require_ok 'FusqlFS::Backend::SQLite::Table::Struct';
our $_tobj = FusqlFS::Backend::SQLite::Table::Struct->new();
isa_ok $_tobj, 'FusqlFS::Backend::SQLite::Table::Struct', 'Class FusqlFS::Backend::SQLite::Table::Struct instantiated';

our $_tcls = 'FusqlFS::Backend::SQLite::Table::Struct';
#!class FusqlFS::Backend::SQLite::Table::Test

FusqlFS::Backend::SQLite::Table::Test->tear_down() if FusqlFS::Backend::SQLite::Table::Test->can('tear_down');

1;