use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
plan 'no_plan';

require_ok 'FusqlFS::Formatter::Native';
our $_tcls = 'FusqlFS::Formatter::Native';

#=begin testing
{
my $_tname = '';
my $_tcount = undef;

#!noinst
my $value = { a => 1, b => 2, c => 3 };
is FusqlFS::Formatter::Native::Load(FusqlFS::Formatter::Native::Dump($value)), $value, "pass-through formatter";
}

1;