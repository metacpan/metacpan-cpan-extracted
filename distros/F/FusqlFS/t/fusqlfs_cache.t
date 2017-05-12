use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
plan 'no_plan';

require_ok 'FusqlFS::Cache';
our $_tcls = 'FusqlFS::Cache';

#=begin testing init
{
my $_tname = 'init';
my $_tcount = undef;

#!noinst

foreach (qw(Limited File))
{
    my %cache;
    ok !FusqlFS::Cache->init(\%cache, lc $_, 0), $_.' cache strategy not chosen';
    ok !tied(%cache), $_.' cache handler is untied';

    isa_ok FusqlFS::Cache->init(\%cache, lc $_, 10), 'FusqlFS::Cache::'.$_, $_.' cache strategy chosen';
    isa_ok tied(%cache), 'FusqlFS::Cache::'.$_, $_.' cache handler tied';
}

my %cache;
ok !FusqlFS::Cache->init(\%cache, 'memory'), 'Memory cache strategy chosen';
ok !FusqlFS::Cache->init(\%cache, 'xxxxxx'), 'Memory cache strategy chosen (fallback 1)';
ok !FusqlFS::Cache->init(\%cache), 'Memory cache strategy chosen (fallback 2)';
ok !tied(%cache), 'Memory cache handler is untied';
}

1;