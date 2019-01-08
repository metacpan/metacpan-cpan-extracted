#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Kubernetes::REST::CallContext;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;
use Kubernetes::REST::ListToRequest;

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

done_testing;
