use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
use FusqlFS::Backend::PgSQL::Test;
if (FusqlFS::Backend::PgSQL::Test->can('set_up'))
{ plan skip_all => 'Initialization failed' unless FusqlFS::Backend::PgSQL::Test->set_up(); }
plan 'no_plan';

require_ok 'FusqlFS::Backend::PgSQL';
our $_tcls = 'FusqlFS::Backend::PgSQL';

#=begin testing
{
my $_tname = '';
my $_tcount = undef;

#!class FusqlFS::Backend::PgSQL::Test
#!noinst

my $fusqlh = FusqlFS::Backend::PgSQL->new(
    host     => '',
    port     => '',
    database => 'fusqlfs_test',
    user     => 'postgres',
    password => ''
);

isa_ok $fusqlh, 'FusqlFS::Backend::PgSQL', 'PgSQL backend initialization';

my $new_fusqlh = FusqlFS::Backend::PgSQL->new();
is $new_fusqlh, $fusqlh, 'PgSQL backend is singleton';
}

FusqlFS::Backend::PgSQL::Test->tear_down() if FusqlFS::Backend::PgSQL::Test->can('tear_down');

1;