#!perl

############################################################################
# high-level API test - start a server, use the api to upload a file or two,
# then make sure that those files exist and are what we expect.
############################################################################

use Test::More tests => 39;

use warnings;
use strict;
use Test::Exception;
use Test::Differences;
use lib 't/lib';
use DTest;
use LWP::Simple ();

use Froody::Server::Test;
use Froody::SimpleClient;

ok( Froody::Server::Test->start( "DTest::Test" ), 'got interface to client');
ok( my $real_client = Froody::Server::Test->client, 'got interface to client');

like( LWP::Simple::get(Froody::Server::Test->endpoint . '?foo=1'),
	qr/froody.invoke.nomethod/, 'get a froody error');

is $real_client->repository->get_methods, 14, "Right number of methods.";

eq_or_diff [ sort map { $_->full_name } $real_client->repository->get_errortypes],  
           [ '',  'perl.methodcall.param','test.error',],
           "Right number of error types.";
sleep(1);
ok( my $simple_client = Froody::SimpleClient->new( Froody::Server::Test->endpoint, 
                                                   timeout => 1 ), "got simpleclient" );

my $first = 1;

for my $client ( $real_client, $simple_client ) {
#for my $client ($simple_client ) {
  my $answer;

  lives_ok {
    $client->call('froody.reflection.getErrorTypeInfo', code=> 'test.error');
  } "We have the right error type info for test.error";
  is_deeply $client->call('froody.reflection.getErrorTypes'), {
          'errortype' => [
                         'perl.methodcall.param',
                         'test.error'
                       ]
  }, "we have the expected error shapes"; 
  
  lives_ok {
    $answer = $client->call( 'foo.test.add', values => [1,2,3]);
  } 'can make call';
  ok( $answer, 'got a response');
  
  lives_and {
    $answer = $client->call( 'foo.test.echo', { echo => "\x{e9}" } );
    is $answer, "\x{e9}", "We get the right answer back.";
  } 'can make call';
  
  lives_and {
    $answer = $client->call( 'foo.test.add', {} );
    is $answer, "\x{e9}", "We get the right answer back.";
  } 'can make call';
  
  lives_and {
    $answer = $client->call( 'foo.test.empty' );
    is_deeply $answer, {}, "We get empty response back.";
  } 'can make call';
  
  throws_ok {
    $answer = $client->call('foo.foo.bar');
  } qr/not found/;
  isa_ok($@, "Froody::Error", "right error") or diag $@;
  undef $@;

  throws_ok {
    $answer = $client->call('foo.test.badspec');
  } qr/froody.xml/;
  
  
  throws_ok {
    $client->call('foo.test.haltandcatchfire');
  } qr/I'm on fire/;
  
  isa_ok $@, 'Froody::Error';
  is $@->code, 'test.error';

  
  eq_or_diff $@->data || {}
             , { fire => "++good", napster => '++ungood' }
             , "We threw a data structure.";
  # Die with a non-froody error in the error_handler should return a 500 from the server.
  throws_ok {
    $client->call('foo.test.badhandler');
  } qr/froody.invoke.remote/;
  isa_ok $@, 'Froody::Error';
}

throws_ok {
  $simple_client->call( 'foo.test.sloooow' );
} qr/froody.invoke.remote/, 'we time out really quickly';

