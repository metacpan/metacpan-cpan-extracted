#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Kubernetes::REST::Error;

throws_ok(sub {
  Kubernetes::REST::Error->throw(type => 'ErrorType', message => 'mymessage');
}, 'Kubernetes::REST::Error');
like($@->as_string, qr/ErrorType/);
like($@->as_string, qr/mymessage/);

throws_ok(sub {
  Kubernetes::REST::Error->throw(type => 'ErrorType', message => 'mymessage', detail => 'mydetail');
}, 'Kubernetes::REST::Error');
like($@->as_string, qr/ErrorType/);
like($@->as_string, qr/mymessage/);
like($@->as_string, qr/mydetail/);

throws_ok(sub {
  Kubernetes::REST::RemoteError->throw(message => 'mymessage', status => 400);
}, 'Kubernetes::REST::RemoteError');
cmp_ok($@->status, '==', 400);
like($@->as_string, qr/with type: Remote/);
like($@->as_string, qr/mymessage/);

throws_ok(sub {
  Kubernetes::REST::RemoteError->throw(message => 'mymessage', status => 400, detail => 'mydetail');
}, 'Kubernetes::REST::RemoteError');
cmp_ok($@->status, '==', 400);
like($@->as_string, qr/with type: Remote/);
like($@->as_string, qr/mymessage/);
like($@->as_string, qr/mydetail/);




done_testing;
