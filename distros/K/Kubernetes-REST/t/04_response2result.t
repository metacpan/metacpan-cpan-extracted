#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Kubernetes::REST::Result2Hash;
use Kubernetes::REST::HTTPResponse;

my $l2r = Kubernetes::REST::Result2Hash->new;

{
  throws_ok(sub {
    my $res = $l2r->result2return(
      {},
      {},
      Kubernetes::REST::HTTPResponse->new(
        content => '{"kind":"Status","apiVersion":"v1","metadata":{},"status":"Failure","message":"Unauthorized","reason":"Unauthorized","code":401}',
        status => 401,
      )
    );
  }, 'Kubernetes::REST::RemoteError');
}

done_testing;
