#!/usr/bin/perl

#####################################################################
# checks that the reflection methods return the right info about
# other methods
###################################################################

use Test::More tests => 12;
use Test::Exception;

use strict;
use warnings;

use Data::Dumper;
use Test::Differences;
use Test::XML;
use Froody::Dispatch;

my $client = Froody::Dispatch->config();
ok my $rs = $client->call('froody.reflection.getMethods'), 
  "Dispatch lives without authorization.";

my $dispatch  = Froody::Dispatch->new;
$dispatch->repository( Froody::Repository->new() );
my $repo = $dispatch->repository;
my $methods = [sort map { $_->full_name } $repo->get_methods()];
eq_or_diff( $rs->{method}, $methods, "Get the right list of methods")
  or die Dumper $rs, $methods;

throws_ok { $client->call('froody.reflection.getMethodInfo', 
                         'method_name' => '   froody.reflection.getMethodInfo');
} qr/froody.invoke.nosuchmethod - Method '   froody.reflection.getMethodInfo'/;

# note leading and trailing spaces.
ok $rs = $client->call('froody.reflection.getMethodInfo', 
                         "\nmethod_name   " => 'froody.reflection.getMethodInfo');

my $method = $repo->get_method('froody.reflection.getMethodInfo');

is $rs->{description}, $method->description, "Matching description";
is $rs->{name}, $method->full_name, "Matching full_name";

my $expected_errors = $method->errors;

my $actual;
foreach (@{ $rs->{arguments}{argument} }) {
  ok my $info = $method->arguments->{$_->{name}};
  is $_->{-text}, $info->{doc};
  is $_->{optional}, $info->{optional};
  is $_->{type}, join(',',@{$info->{type}});
}

foreach (@{ $rs->{errors}{error} }) {
  $actual->{$_->{code}} = { description => $_->{-text}, message => $_->{message} };
}
eq_or_diff($actual, $expected_errors);

is_xml $rs->{response},
q{<method name="froody.fakeMethod" needslogin="1">
        <description>A fake method</description> 
        <response>xml-response-example</response> 
        <arguments>
            <argument name="color" optional="1" type="scalar"> Your favorite color.</argument>
            <argument name="fleece" optional="0" type="csv">Your happy fun clothing of choice.</argument>
        </arguments>
        <errors>
          <error code="1" message="it would be bad">Don't cross the streams.</error>
          <error code="1" message="it would be bad">Don't cross the streams.</error>
        </errors>
</method>};
