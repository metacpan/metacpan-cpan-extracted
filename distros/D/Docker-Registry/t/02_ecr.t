use strict;
use warnings;
use lib qw(t/lib);
use Test::Docker::Registry;

use Docker::Registry::ECR;

my $io   = new_fake_io();
my $auth = new_auth_none();

my $d = Docker::Registry::ECR->new(
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

{
    $io->set_status_code(403);
    $io->set_content(
        '{"errors":[{"code":"DENIED","message":"User: arn:aws:sts::012345678901:assumed-role/xxxxxxxxxxxx/xxxxxxxxxx@xxxxxxxxxxxxx is not authorized to perform: ecr:DescribeRepositories on resource: *"}]}'
    );

    throws_ok(
        sub { $d->repositories },
        'Docker::Registry::Exception::HTTP',
        "An exception is returned by AWS"
    );
    is($@->status, 403, ".. and has the status code of 403");
}

done_testing;
