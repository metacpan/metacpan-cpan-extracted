use strict;
use v5.10.0;
use Test::More;
use Test::Deep;
plan 'no_plan';

require_ok 'FusqlFS::Artifact';
our $_tcls = 'FusqlFS::Artifact';

#=begin testing Artifact
{
my $_tname = 'Artifact';
my $_tcount = undef;

#!noinst

isa_ok FusqlFS::Artifact->new(), 'FusqlFS::Artifact';
is FusqlFS::Artifact->get(), '';
is FusqlFS::Artifact->list(), undef;
foreach my $method (qw(rename drop create store))
{
    is FusqlFS::Artifact->$method(), 1;
}
}

1;