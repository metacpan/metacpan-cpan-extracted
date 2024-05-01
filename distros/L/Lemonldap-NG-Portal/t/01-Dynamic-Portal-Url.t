use warnings;
use Test::More;
use strict;
use IO::String;

use Lemonldap::NG::Portal::Main::Constants qw(
  PE_FIRSTACCESS
);

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
}

my $res;
my $debug = "error";

# Handler part
use_ok('Lemonldap::NG::Handler::Server');
use_ok('Lemonldap::NG::Common::PSGI::Cli::Lib');

my ( $handler, $portal );
$portal  = portal();
$handler = Lemonldap::NG::Handler::Server->run( $portal->ini );

sub runTest {
    my ( $portal, $handler, $domain ) = @_;

    $res = handler_req( $handler, "test1.$domain" );
    my ($query) = expectRedirection( $res, qr,http://auth\Q.$domain\E/\?(.*), );

    ok(
        $res = $portal->_get(
            "/",
            query  => $query,
            accept => "text/html",
            host   => "auth.$domain"
        )
    );

    ( my $host, my $uri, $query ) =
      expectForm( $res, undef, undef, 'user', 'password' );
    $query =~ s/user=/user=dwho/;
    $query =~ s/password=/password=dwho/;

    ok(
        $res = $portal->_post(
            '/',
            $query,
            accept => 'text/html',
            host   => "auth.$domain",
        ),
        'Auth query'
    );
    expectCookie($res);
    my $set_cookie = getHeader( $res, "Set-Cookie" );
    like( $set_cookie, qr/domain=\Q.$domain\E/,
        "Cookie set on correct domain" );
    expectRedirection( $res, qr,http://test1.$domain/, );

    # Check dynamic portal URL in js
    ok(
        $res = $portal->_get(
            "/psgi.js",
            accept => "text/html",
            host   => "auth.$domain"
        )
    );
    like(
        $res->[2]->[0],
        qr#portal="http://auth\Q.$domain\E/"#,
        "Correct domain in psgi.js"
    );
}

runTest( $portal, $handler, "example.com" );
runTest( $portal, $handler, "acme.com" );

clean_sessions();

done_testing();

sub handler_req {
    my ( $handler, $host, $cookie ) = @_;
    return $handler->( {
            'HTTP_ACCEPT'        => 'text/html',
            'SCRIPT_NAME'        => '/',
            'SERVER_NAME'        => '127.0.0.1',
            'HTTP_CACHE_CONTROL' => 'max-age=0',
            'PATH_INFO'          => '/',
            'REQUEST_METHOD'     => 'GET',
            'REQUEST_URI'        => '/',
            'X_ORIGINAL_URI'     => '/',
            'SERVER_PORT'        => '80',
            'SERVER_PROTOCOL'    => 'HTTP/1.1',
            'REMOTE_ADDR'        => '127.0.0.1',
            'HTTP_HOST'          => $host,
            ( $cookie ? ( HTTP_COOKIE => "lemonldap=$cookie" ) : () ),
        }
    );
}

sub portal {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel => $debug,
                domain   => '#PORTALDOMAIN#',
                portal   =>
'inDomain("acme.com") ? "http://auth.acme.com/" : "http://auth.example.com/"',
                authentication => 'Demo',
                userDB         => 'Same',
                vhostOptions   => {
                    'test1.example.com' => {
                        'vhostType' => 'Main'
                    },
                    'test1.acme.com' => {
                        'vhostType' => 'Main'
                    },
                },
                locationRules => {
                    'auth.example.com' => {
                        default => 'accept',
                    },
                    'test1.example.com' => {
                        'default' => 'accept',
                    },
                    'test1.acme.com' => {
                        'default' => 'accept',
                    },
                },
            }
        }
    );
}
