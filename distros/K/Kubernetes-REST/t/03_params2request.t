#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Kubernetes::REST::CallContext;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;
use Kubernetes::REST::ListToRequest;
use JSON::MaybeXS;

my $l2r = Kubernetes::REST::ListToRequest->new;

{
  my $call = Kubernetes::REST::CallContext->new(
    method => 'GetAllAPIVersions',
    params => [ ],
    server => Kubernetes::REST::Server->new(endpoint => 'http://example.com'),
    credentials => Kubernetes::REST::AuthToken->new(token => 'FakeToken'),
  );

  my $req = $l2r->params2request($call);
  cmp_ok($req->method, 'eq', 'GET');
  cmp_ok($req->url, 'eq', 'http://example.com/');
}

{
  my $body = {
          'apiVersion' => 'v1',
          'kind' => 'Namespace',
          'metadata' => {
                          'name' => 'nsX'
                        }
  };

  my $call = Kubernetes::REST::CallContext->new(
    method => 'v1::Core::CreateNamespace',
    params => [ body => $body ],
    server => Kubernetes::REST::Server->new(endpoint => 'http://example.com'),
    credentials => Kubernetes::REST::AuthToken->new(token => 'FakeToken'),
  );

  my $req = $l2r->params2request($call);

  cmp_ok($req->method, 'eq', 'POST');
  cmp_ok($req->url, 'eq', 'http://example.com/api/v1/namespaces?');
  is_deeply(decode_json($req->content), $body, 'The body of the requests contains the JSON in the body parameter');
}


done_testing;
