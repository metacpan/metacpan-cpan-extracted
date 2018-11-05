use strict;
use warnings;
use Test::Lib;
use Test::Docker::Registry;

use Docker::Registry::Azure;

my $io   = new_fake_io();

my $d = Docker::Registry::Azure->new(
    name       => 'azure-repo',    
    caller     => $io,
    password => 'MyPass',
);

cmp_ok($d->url, 'eq', 'https://azure-repo.azurecr.io');

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

{
    $io->set_status_code(400);
    $io->set_content(
        '<html><head><title>400 Bad Request</title></head><body bgcolor="white"><center><h1>400 Bad Request</h1></center><hr><center>nginx</center></body></html>'
    );

    throws_ok(
        sub { $d->repositories },
        'Docker::Registry::Exception::HTTP',
        "A 400 error message is returned by the serice"
    );
    is($@->status, 400, ".. and has the status code of 400");
}


done_testing;
