use Test::More;
use strict;
use IO::String;

use Lemonldap::NG::Portal::Main::Constants qw(
  PE_FIRSTACCESS
);

require 't/test-lib.pm';

my $res;

my $client = register(
    'portal',
    sub {
        LLNG::Manager::Test->new( {
                ini => {
                    logLevel    => 'error',
                    useSafeJail => 1,
                    cda         => 1,
                    logger      => 'Lemonldap::NG::Common::Logger::Std',
                }
            }
        );
    }
);

# Try to authenticate
# -------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
    ),
    'Auth query'
);
count(1);
expectOK($res);
my $id = expectCookie($res);

# CDA with authentified user
ok(
    $res = $client->_get(
        '/',
        query  => 'url=aHR0cDovL3Rlc3QuZXhhbXBsZS5vcmcv',
        accept => 'text/html',
        cookie => "lemonldap=$id",
    ),
    'Auth CDA request'
);
count(1);

my ($query) =
  expectRedirection( $res, qr#^http://test.example.org/\?(lemonldapcda=.*)$# );

# Bug #1650 made the portal store an _url in pdata at this step
my $cookies = getCookies($res);

ok( !defined( $cookies->{lemonldappdata} ), " Make sure no pdata is returned" );
count(1);

# Handler part
use_ok('Lemonldap::NG::Handler::Server');
use_ok('Lemonldap::NG::Common::PSGI::Cli::Lib');
count(2);

my ( $cli, $app );
switch ('app');
$app = register( 'app',
    sub { Lemonldap::NG::Handler::Server->run( $client->ini ) } );

ok(
    $res = $app->( {
            'HTTP_ACCEPT'          => 'text/html',
            'SCRIPT_NAME'          => '/',
            'SERVER_NAME'          => '127.0.0.1',
            'QUERY_STRING'         => $query,
            'HTTP_CACHE_CONTROL'   => 'max-age=0',
            'HTTP_ACCEPT_LANGUAGE' => 'fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3',
            'PATH_INFO'            => '/',
            'REQUEST_METHOD'       => 'GET',
            'REQUEST_URI'          => "/?$query",
            'X_ORIGINAL_URI'       => "/?$query",
            'SERVER_PORT'          => '80',
            'SERVER_PROTOCOL'      => 'HTTP/1.1',
            'HTTP_USER_AGENT'      =>
              'Mozilla/5.0 (VAX-4000; rv:36.0) Gecko/20350101 Firefox',
            'REMOTE_ADDR' => '127.0.0.1',
            'HTTP_HOST'   => 'test.example.org',
            'VHOSTTYPE'   => 'CDA',
        }
    ),
    'Push cda cookie'
);
count(1);
expectRedirection( $res, 'http://test.example.org/' );
my $cid = expectCookie($res);

ok(
    $res = $app->( {
            'HTTP_ACCEPT'          => 'text/html',
            'SCRIPT_NAME'          => '/',
            'SERVER_NAME'          => '127.0.0.1',
            'HTTP_COOKIE'          => "lemonldap=$cid",
            'HTTP_CACHE_CONTROL'   => 'max-age=0',
            'HTTP_ACCEPT_LANGUAGE' => 'fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3',
            'PATH_INFO'            => '/',
            'REQUEST_METHOD'       => 'GET',
            'REQUEST_URI'          => "/",
            'X_ORIGINAL_URI'       => "/",
            'SERVER_PORT'          => '80',
            'SERVER_PROTOCOL'      => 'HTTP/1.1',
            'HTTP_USER_AGENT'      =>
              'Mozilla/5.0 (VAX-4000; rv:36.0) Gecko/20350101 Firefox',
            'REMOTE_ADDR' => '127.0.0.1',
            'HTTP_HOST'   => 'test.example.org',
            'VHOSTTYPE'   => 'CDA',
        }
    ),
    'Authenticated query'
);
count(1);
expectOK($res);
expectAuthenticatedAs( $res, 'dwho' );

clean_sessions();

done_testing( count() );
