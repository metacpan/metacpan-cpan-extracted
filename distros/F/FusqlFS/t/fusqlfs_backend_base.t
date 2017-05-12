use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
plan 'no_plan';

require_ok 'FusqlFS::Backend::Base';
our $_tcls = 'FusqlFS::Backend::Base';

#=begin testing dsn
{
my $_tname = 'dsn';
my $_tcount = undef;

#!noinst

is FusqlFS::Backend::Base->dsn('host', 'port', 'database'), 'host=host;port=port;database=database;', 'FusqlFS::Backend::Base->dsn is sane';
}

1;