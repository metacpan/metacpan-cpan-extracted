use strict;
use warnings;
use lib qw(t/lib);

use Test::Docker::Registry;

use Docker::Registry::GCE;

my $auth = new_auth_none();
my $io   = new_fake_io();

my $d = Docker::Registry::GCE->new(
    region     => 'fake',
    account_id => 'fake',
    caller     => $io,
    auth       => $auth,
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

    isa_ok($result, 'Docker::Registry::Result::RepositoryTags');
    cmp_ok($result->name,      'eq', 'test2-registry');
    cmp_ok($result->tags->[0], 'eq', 'version1');
}

done_testing;
