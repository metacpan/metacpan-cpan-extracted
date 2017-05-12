use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
plan 'no_plan';

require_ok 'FusqlFS::Cache::File';
our $_tcls = 'FusqlFS::Cache::File::Record';

#=begin testing
{
my $_tname = '';
my $_tcount = undef;

#!req FusqlFS::Cache::File
#!noinst

my $string = '';

use File::Temp qw(:mktemp);
my $tempfile = mktemp('fusqlfs_test_XXXXXXX');

isa_ok tie($string, 'FusqlFS::Cache::File::Record', $tempfile, 'stored value'), 'FusqlFS::Cache::File::Record', 'File cache record tied';
is $string, 'stored value', 'File cache record is sane';
$string = 'new value';
is $string, 'new value', 'File cache record is sane after rewrite';
}

1;