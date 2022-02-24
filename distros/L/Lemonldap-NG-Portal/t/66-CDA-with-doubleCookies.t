use Test::More;
use strict;
use IO::String;

use Lemonldap::NG::Portal::Main::Constants qw(
  PE_FIRSTACCESS
);

require 't/test-lib.pm';

my $res;

# Portal
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel      => 'error',
            useSafeJail   => 1,
            cda           => 1,
            logger        => 'Lemonldap::NG::Common::Logger::Std',
            https         => -1,
            securedCookie => 2,
        }
    }
);

# Handler
use_ok('Lemonldap::NG::Handler::Server');
use_ok('Lemonldap::NG::Handler::Main');
use_ok('Lemonldap::NG::Common::PSGI::Cli::Lib');
my $app;
ok( $app = Lemonldap::NG::Handler::Server->run( $client->ini ), 'App' );
count(4);

# Authentification
my $query = 'user=dwho&password=dwho';
ok(
    $res = $client->_post(
        '/'    => IO::String->new($query),
        length => length($query),
        accept => 'text/html',
        secure => 1,
    ),
    'Post credentials'
);
count(1);
my $id     = expectCookie($res);
my $httpid = expectCookie( $res, 'lemonldaphttp' );

# CDA to http
ok(
    $res = $client->_get(
        '/',
        query  => 'url=' . encodeUrl('http://test.example.org/'),
        accept => 'text/html',
        cookie => "lemonldap=$id, lemonldaphttp=$httpid",
        secure => 1,
    ),
    'CDA request to http vhost'
);
count(1);

($query) =
  expectRedirection( $res, qr#^http://test.example.org/\?(lemonldapcda=.*)$# );

validateCda( $query, 'http' );

# CDA to https
ok(
    $res = $client->_get(
        '/',
        query  => 'url=' . encodeUrl('https://test.example.org/'),
        accept => 'text/html',
        cookie => "lemonldap=$id, lemonldaphttp=$httpid",
        secure => 1,
    ),
    'CDA request to https vhost'
);
count(1);

($query) =
  expectRedirection( $res, qr#^https://test.example.org/\?(lemonldapcda=.*)$# );

validateCda( $query, 'https' );

# Try to CDA to http when accessing the portal over http (#2382)
ok(
    $res = $client->_get(
        '/',
        query  => 'url=' . encodeUrl('http://test.example.org/'),
        accept => 'text/html',
        cookie => "lemonldap=$id, lemonldaphttp=$httpid",
        secure => 0,
    ),
    'CDA request to https vhost'
);
count(1);

expectPortalError( $res, 24 );

clean_sessions();

done_testing( count() );

sub validateCda {
    my ( $query, $scheme ) = @_;
    my $cookiename = ( $scheme eq 'https' ? 'lemonldap' : 'lemonldaphttp' );
    my $port       = ( $scheme eq 'https' ? 443         : 80 );
    my $res;
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
                'SERVER_PORT'          => $port,
                'SERVER_PROTOCOL'      => 'HTTP/1.1',
                'HTTP_USER_AGENT'      =>
                  'Mozilla/5.0 (VAX-4000; rv:36.0) Gecko/20350101 Firefox',
                'REMOTE_ADDR'     => '127.0.0.1',
                'HTTP_HOST'       => 'test.example.org',
                'VHOSTTYPE'       => 'CDA',
                'psgi.url_scheme' => $scheme,
            }
        ),
        'Push cda cookie'
    );
    count(1);
    expectRedirection( $res, $scheme . '://test.example.org/' );
    my $cid = expectCookie( $res, $cookiename );

    ok(
        $res = $app->( {
                'HTTP_ACCEPT'          => 'text/html',
                'SCRIPT_NAME'          => '/',
                'SERVER_NAME'          => '127.0.0.1',
                'HTTP_COOKIE'          => "$cookiename=$cid",
                'HTTP_CACHE_CONTROL'   => 'max-age=0',
                'HTTP_ACCEPT_LANGUAGE' => 'fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3',
                'PATH_INFO'            => '/',
                'REQUEST_METHOD'       => 'GET',
                'REQUEST_URI'          => "/",
                'X_ORIGINAL_URI'       => "/",
                'SERVER_PORT'          => $port,
                'SERVER_PROTOCOL'      => 'HTTP/1.1',
                'HTTP_USER_AGENT'      =>
                  'Mozilla/5.0 (VAX-4000; rv:36.0) Gecko/20350101 Firefox',
                'REMOTE_ADDR'     => '127.0.0.1',
                'HTTP_HOST'       => 'test.example.org',
                'VHOSTTYPE'       => 'CDA',
                'psgi.url_scheme' => $scheme,
            }
        ),
        'Authenticated query'
    );
    count(1);
    expectOK($res);
    expectAuthenticatedAs( $res, 'dwho' );
}
