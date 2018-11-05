use strict;
use warnings;
use Test::Lib;
use Test::Docker::Registry;

use Docker::Registry::GCE;

my $auth = new_auth_none();
my $io   = new_fake_io();

my $d = Docker::Registry::GCE->new(
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
    $io->set_content('<HTML><HEAD><meta http-equiv="content-type" content="text/html;charset=utf-8">
<TITLE>302 Moved</TITLE></HEAD><BODY>
<H1>302 Moved</H1>
The document has moved
<A HREF="https://console.cloud.google.com/m/gcr/images/redirect?project=infraestructura-global&amp;location=EU&amp;repo_name=v2/_catalog">here</A>.
</BODY></HTML>');
    $io->set_status_code(302);

    throws_ok(sub {
      $d->repositories;
    }, 'Docker::Registry::Exception::HTTP');
}

{
  my $r = Docker::Registry::GCE->new(
    account_id => 'fake',
    caller     => $io,
    auth       => $auth,
  );
  cmp_ok($r->url, 'eq', 'https://gcr.io');
}

{
  my $r = Docker::Registry::GCE->new(
    region     => 'eu',
    account_id => 'fake',
    caller     => $io,
    auth       => $auth,
  );
  cmp_ok($r->url, 'eq', 'https://eu.gcr.io');
}

done_testing;
