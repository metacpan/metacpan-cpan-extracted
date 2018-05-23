#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Docker::Registry::GCE;
use Docker::Registry::Auth::None;

package TestIO::Fake {
  use Moose;
  with 'Docker::Registry::IO';

  has response_to_return => (is => 'rw', isa => 'Docker::Registry::Response');

  sub send_request {
    my $self = shift;
    return $self->response_to_return;
  }
}

my $auth = Docker::Registry::Auth::None->new;

my $io = TestIO::Fake->new(
  response_to_return => response_200(''),
);

sub response_200 {
  my ($content) = @_;
  registry_response(200, $content);
}

sub registry_response {
  my ($status, $content) = @_;
  return Docker::Registry::Response->new(
    content => $content,
    status => $status,
    headers => {},
  );
}

my $d = Docker::Registry::GCE->new(
  caller => $io,
  auth => $auth,
  region => 'fake',
  account_id => 'fake',
);

{
  $io->response_to_return(
    response_200('{"repositories":["test2-registry","test1-registry"]}'),
  );
  
  my $result = $d->repositories;

  isa_ok($result, 'Docker::Registry::Result::Repositories');
  cmp_ok($result->repositories->[0], 'eq', 'test2-registry');
  cmp_ok($result->repositories->[1], 'eq', 'test1-registry');
}

{
  $io->response_to_return(
    response_200('{"name":"test2-registry","tags":["version1"]}'), 
  );
  
  my $result = $d->repository_tags(repository => 'test2-registry');

  isa_ok($result, 'Docker::Registry::Result::RepositoryTags');
  cmp_ok($result->name, 'eq', 'test2-registry');
  cmp_ok($result->tags->[0], 'eq', 'version1');
}

done_testing;
