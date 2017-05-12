use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
plan 'no_plan';

require_ok 'FusqlFS::Cache::Base';
our $_tcls = 'FusqlFS::Cache::Base';

#=begin testing new
{
my $_tname = 'new';
my $_tcount = undef;

#!noinst

my $test = $_tcls->new();
isa_ok $test, 'HASH';
is tied($test), undef;
}

1;