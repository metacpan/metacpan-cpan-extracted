use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
plan 'no_plan';

require_ok 'FusqlFS::Formatter';
our $_tcls = 'FusqlFS::Formatter';

#=begin testing init
{
my $_tname = 'init';
my $_tcount = undef;

#!noinst
my ($dump, $load) = FusqlFS::Formatter->init('native');
is ref $dump, 'CODE', 'Dumper defined';
is ref $load, 'CODE', 'Loader defined';
}

1;