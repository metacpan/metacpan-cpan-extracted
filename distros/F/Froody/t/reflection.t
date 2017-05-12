#!/usr/bin/perl

#####################################################################
# checks the reflection methods are loaded by the repository
#####################################################################

use strict;
use warnings;

use Test::More tests => 12;
use Test::Exception;

use Froody::Repository;
use Test::Differences;
use Froody::Response::Terse;

use lib 't/lib';

use_ok ('Other');
use Froody::Dispatch;

my $client = Froody::Dispatch->config({modules=>['Other']});
my $repo = $client->repository;

is scalar $repo->get_methods(), 6, 'One method plus the reflection methods';
is scalar $repo->get_methods(qr'^reflection'), 0, 'partial query';
is scalar $repo->get_methods(qr'^other'), 1, 'partial query';
is scalar @{
    $client->call('froody.reflection.getMethods')->{method}
}, 6, '1 method plus reflection ones';

my $method = $repo->get_method('other.object.method');

is $method->module, 'Other::Object', 'namespace transform worked';

isa_ok $repo->get_method('other.object.method'), 'Froody::Method';

throws_ok {
  $repo->get_method('Ack.Bar');
} qr/Method 'Ack.Bar' not found/;

isa_ok $method, 'Froody::Method';

ok my $ret = $client->call('froody.reflection.getMethodInfo', 
    method_name => 'froody.reflection.getSpecification');
ok $method = $repo->get_method('froody.reflection.getSpecification');

my $buggy = $method->example_response->as_terse->content;
eq_or_diff $buggy->{errortypes}, { 
                          'errortype' => [
                                         {
                                           '-text' => 'Internal structure of your error type goes here (including XML)',
                                           'code' => 'mycode'
                                         },
                                         {
                                            '-text' => 'Internal structure of your error type goes here (including XML)',
                                           'code' => 'mycode'
                                         }
                                       ]
}, "So... we were doing bad things with our examples.";
