#!/usr/bin/perl

#########################################################################
# This test tests the functionality of Froody::Dispatch
#########################################################################

use warnings;
use strict;

use Test::More;

plan tests => 19;
use Test::Exception;
use File::Spec::Functions;
use Encode qw(encode_utf8);

# we've got mock classes in t/lib
unshift @INC, catdir('t', 'lib');

# The classes we're testing
use Froody::Dispatch;
use Froody::Repository;
use Froody::Response::PerlDS;

# loading this alone should put it in the default repository
use_ok('DTest::Test');

my @methods = (
  { method => 'foo.test.add',        value => "\x{e9}" },
  { method => 'foo.test.getGroups',  value => "\x{2264}" },
);

my $dispatcher = Froody::Dispatch->config({
  modules => ['DTest::Test']
});
my ($response, $xml);

# Check that we get back the class and method names we expect
for my $method (@methods) {
  ok( $response = $dispatcher->dispatch( 
    method => $method->{method},
  ), "dispatched" );
  is( $response->status, "ok", "status is ok");
  ok( $xml = $response->render, "got xml");
  is( $xml, encode_utf8( <<XML ), "expected XML" );
<?xml version="1.0" encoding="utf-8"?>
<rsp stat="ok">
  <value>$method->{value}</value>
</rsp>
XML
}

throws_ok {
  $dispatcher->call('y.y.y')
} qr/Method \'y.y.y\' not found/;

throws_ok {
  $dispatcher->dispatch( method => 'y.y.y')
} qr/Method \'y.y.y\' not found/;


ok( $response = $dispatcher->dispatch(
  method => "foo.test.thunktest   ",
  params => { foo => 1 }
),"dispatched" );
is( $response->as_terse->content, 2, "got '2' back, class_thunker run");


# leading space should be stripped.
ok( $response = $dispatcher->call( "foo.test.thunktest", foo => ' 1' ),"dispatched" );
is( $response, 2, "got '2' back, class_thunker run");

throws_ok {
  $dispatcher->call('foo.test.haltandcatchfire');
} qr/I'm on fire/;

isa_ok $@, 'Froody::Error';
is_deeply $@->data, { fire => "++good", napster => '++ungood' }, "We threw a data structure.";
is $@->code, 'test.error';

