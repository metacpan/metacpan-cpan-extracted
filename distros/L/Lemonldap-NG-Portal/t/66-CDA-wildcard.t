use Test::More;
use strict;
use IO::String;

use Lemonldap::NG::Portal::Main::Constants qw(
  PE_FIRSTACCESS
);

require 't/test-lib.pm';

sub validate_cda {
    my ( $client, $query, $domain, $expectedUser ) = @_;

    # Initialize handler
    use_ok('Lemonldap::NG::Handler::Server');
    use_ok('Lemonldap::NG::Common::PSGI::Cli::Lib');
    count(2);

    my ( $cli, $app, $res );
    ok( $app = Lemonldap::NG::Handler::Server->run( $client->ini ), 'App' );
    count(1);

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
                'HTTP_USER_AGENT' =>
                  'Mozilla/5.0 (VAX-4000; rv:36.0) Gecko/20350101 Firefox',
                'REMOTE_ADDR' => '127.0.0.1',
                'HTTP_HOST'   => $domain,
                'VHOSTTYPE'   => 'CDA',
            }
        ),
        'Push cda cookie'
    );
    count(1);
    expectRedirection( $res, "http://$domain/" );
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
                'HTTP_USER_AGENT' =>
                  'Mozilla/5.0 (VAX-4000; rv:36.0) Gecko/20350101 Firefox',
                'REMOTE_ADDR' => '127.0.0.1',
                'HTTP_HOST'   => $domain,
                'VHOSTTYPE'   => 'CDA',
            }
        ),
        'Authenticated query'
    );
    count(1);
    expectOK($res);
    expectAuthenticatedAs( $res, $expectedUser );
}

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel    => 'error',
            useSafeJail => 1,
            cda         => 1,
            logger      => 'Lemonldap::NG::Common::Logger::Std',
        }
    }
);

# CDA with unauthentified user
ok(
    $res = $client->_get(
        '/',
        query  => 'url=' . encodeUrl('http://cda.example.llng/'),
        accept => 'text/html',
    ),
    'Unauth CDA request'
);
my ( $host, $url, $query ) = expectForm( $res, undef, undef, 'url' );
count(1);

# Authentification
$query .= '&user=dwho&password=dwho';
ok(
    $res = $client->_post(
        '/'    => IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Post credentials'
);
count(1);

($query) =
  expectRedirection( $res, qr#^http://cda.example.llng/\?(lemonldapcda=.*)$# );

my $id = expectCookie($res);

# Check that *.example.llng allows subdomains
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id",
        query  => 'url=' . encodeUrl('http://sub.cda.example.llng/'),
        accept => 'text/html',
    ),
    'CDA request to subdomain'
);
count(1);

my ($querytosub) = expectRedirection( $res,
    qr#^http://sub.cda.example.llng/\?(lemonldapcda=.*)$# );

# Check that %.oneonly.llng rejects subdomains
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id",
        query  => 'url=' . encodeUrl('http://sub.cda.oneonly.llng/'),
        accept => 'text/html',
    ),
    'CDA request to subdomain'
);
count(1);

expectPortalError( $res, 37, "Subdomain CDA request not allowed by wildcard" );

# Check that %.oneonly.llng allows one-level domains
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id",
        query  => 'url=' . encodeUrl('http://cda.oneonly.llng/'),
        accept => 'text/html',
    ),
    'CDA request to one-level wildcard'
);
count(1);
my ($querytoone) =
  expectRedirection( $res, qr#^http://cda.oneonly.llng/\?(lemonldapcda=.*)$# );

validate_cda( $client, $querytosub, 'sub.cda.example.llng', 'dwho' );
validate_cda( $client, $query,      'cda.example.llng',     'dwho' );
validate_cda( $client, $querytoone, 'cda.oneonly.llng',     'dwho' );

clean_sessions();

done_testing( count() );
