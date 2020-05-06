use Test::More;
use JSON;
use MIME::Base64;
use Data::Dumper;

require 't/test-psgi-lib.pm';

my $app;

use_ok('Lemonldap::NG::Handler::PSGI::Try');

ok( $app = module( Lemonldap::NG::Handler::PSGI::Try->new() ), 'New object' );

init();

ok(
    $app->init( {
            configStorage       => { type => 'File', dirName => 't' },
            localSessionStorage => '',
            logLevel            => 'warn',
            cookieName          => 'lemonldap',
            securedCookie       => 2,
            https               => 1,
            userLogger          => 'Lemonldap::NG::Common::Logger::Null',
        }
    ),
    'initialization'
);

ok( $app->addAuthRoute( test => sub { [ 200, [], ['Auth'] ] }, ['GET'] ),
    'Set auth route' );

ok( $app->addUnauthRoute( test => sub { [ 200, [], ['Unauth'] ] }, ['GET'] ),
    'Set auth route' );

count(4);

my $res;

# Unauth tests
ok( $res = $client->_get('/test'), 'Get response' );
ok( $res->[0] == 200,              'Response code is 200' )
  or print "Expect 200, got $res->[0]\n";
ok( $res->[2]->[0] eq 'Unauth', 'Get unauth result' )
  or print "Expect Unauth, got $res->[2]->[0]\n";
count(3);

# Auth tests
ok(
    $res = $client->_get(
        '/test',
        undef,
        undef,
'lemonldap=f5eec18ebb9bc96352595e2d8ce962e8ecf7af7c9a98cb9a43f9cd181cf4b545'
    ),
    'Get response'
);
ok( $res->[0] == 200, 'Response code is 200' )
  or print "Expect 200, got $res->[0]\n";
ok( $res->[2]->[0] eq 'Auth', 'Get auth result' )
  or print "Expect Auth, got $res->[2]->[0]\n";
count(3);

# Bad path test

ok( $res = $client->_get('/[]/test'), 'Try a bad path' );
ok( $res->[0] == 400,                 'Response is 400' );
count(2);

clean();

done_testing( count() );

