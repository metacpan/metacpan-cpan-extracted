use Test::More;
use JSON;
use MIME::Base64;

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
ok(
    $app->addAuthRoute(
        alwaysskip => sub {
            ok( !$_[1]->userData->{uid}, "Cache was cleared" );
            count(1);
            [ 200, [], ['Auth'] ];
        },
        ['GET']
    ),
    'Set auth route'
);
count(5);

my $res;

# Unauth tests
ok( $res = $client->_get('/test'), 'Get response' );
ok( $res->[0] == 200,              'Response code is 200' )
  or print "Expect 200, got $res->[0]\n";
ok( $res->[2]->[0] eq 'Unauth', 'Get unauth result' )
  or print "Expect Unauth, got $res->[2]->[0]\n";
count(3);

ok( $res = $client->_head('/test'), 'Get response with HEAD method' );
ok( $res->[0] == 200,               'Response code is 200' )
  or print "Expect 200, got $res->[0]\n";
ok( ref( $res->[2] ) eq 'ARRAY', 'Get array ref' )
  or print 'Expect array ref, got ' . ref( $res->[2] ) . "\n";
count(3);

# Auth tests
ok( $res = $client->_get( '/test', undef, undef, "lemonldap=$sessionId" ),
    'Get response' );
ok( $res->[0] == 200, 'Response code is 200' )
  or print "Expect 200, got $res->[0]\n";
ok( $res->[2]->[0] eq 'Auth', 'Get auth result' )
  or print "Expect Auth, got $res->[2]->[0]\n";
count(3);

# Skip bug
ok( $res = $client->_get( '/alwaysskip', undef, undef, undef ),
    'Get response' );
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

