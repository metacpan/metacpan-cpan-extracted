#!/usr/bin/env perl

use strict;
use warnings;
use Test::Lib;
use Test::Docker::Registry;

use Docker::Registry::Gitlab;

my $auth = new_auth_none();
my $io   = new_fake_io();

my $d = Docker::Registry::Gitlab->new(
    username     => 'username',
    access_token => 'access_token',
    caller       => $io,
    auth         => $auth,
);

{
    $io->set_content('{"repositories":["test2-registry","test1-registry"]}');

    my $result = $d->repositories;
    isa_ok($result, 'Docker::Registry::Result::Repositories');
    cmp_ok($result->repositories->[0], 'eq', 'test2-registry');
    cmp_ok($result->repositories->[1], 'eq', 'test1-registry');
}

{
    $io->set_content('{"name":"test2-registry","tags":["version1"]}');

    my $result = $d->repository_tags(repository => 'test2-registry');

    isa_ok($result, 'Docker::Registry::Result::RepositoryTags', "Got the tags from the repository");
    is($result->name, 'test2-registry', ".. and the name is correct");
    cmp_deeply($result->tags, [qw(version1)], ".. and just one tag");;
}

done_testing;
