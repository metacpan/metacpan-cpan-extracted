use Test::More;
use strict;
use IO::String;
use Data::Dumper;

BEGIN {
    require 't/test-lib.pm';
}

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel             => 'error',
            authentication       => 'Demo',
            userDB               => 'Same',
            loginHistoryEnabled  => 0,
            bruteForceProtection => 0,
            requireToken         => 0,
            restSessionServer    => 1,
            logoutServices       =>
              { 'mytest' => 'http://test1.example.com/logout.html' }
            ,    # page that does not exist
            locationRules => {
                'test1.example.com' => {
                    '(?#logout)^/logout.html' => 'unprotect',
                    'default'                 => 'accept'
                },
            },
            logger => 'Lemonldap::NG::Common::Logger::Std',
        }
    }
);

# Handler part
use_ok('Lemonldap::NG::Handler::Server');
use_ok('Lemonldap::NG::Common::PSGI::Cli::Lib');
count(2);

my ( $cli, $app );
ok( $app = Lemonldap::NG::Handler::Server->run( $client->ini ), 'App' );
count(1);

## First successful connection for 'dwho'
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html',
    ),
    '1st "dwho" Auth query'
);
count(1);
my $cookie = expectCookie( $res, 'lemonldap' );

expectRedirection( $res, 'http://auth.example.com/' );

## Logout request for 'dwho'
ok(
    $res = $client->_get(
        '/',
        query  => 'logout',
        cookie => "lemonldap=$cookie",
        accept => 'text/html'
    ),
    'Logout request for "dwho"'
);
count(1);

ok(
    $res->[2]->[0] =~
      m%<h3 trspan="logoutFromOtherApp">logoutFromOtherApp</h3>%,
    'Found Logout Forward page'
) or explain( $res->[2]->[0], "PE_LOGOUT_OK" );
count(1);

$cookie = expectCookie( $res, 'lemonldap' );
ok( $cookie eq "0", 'Test empty cookie sent at logout' );
count(1);

# Verify that there is no pdata
my $cookies = getCookies($res);
my $id;
ok(
    !defined( $id = $cookies->{'lemonldappdata'} ),
    " Verify absence of cookie lemonldappdata"
) or explain('Get lemonldappdata cookie');
count(1);

my ($logouturl) = grep( /iframe/, split( "\n", $res->[2]->[0] ) );
$logouturl =~ s/.*<iframe src="([^"]+)".*/\1/;
my $ep = $logouturl;
$ep =~ s/https?:\/\/[^\/]+//;

## Forward logout
## TODO: handler behaviour is incomplete here, because it does not check:
##       - locationRules
##       - presence of resource in the server (404,...)
ok(
    $res = $app->( {
            'HTTP_ACCEPT'          => 'text/html',
            'SCRIPT_NAME'          => '/',
            'SERVER_NAME'          => '127.0.0.1',
            'HTTP_CACHE_CONTROL'   => 'max-age=0',
            'HTTP_ACCEPT_LANGUAGE' => 'fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3',
            'PATH_INFO'            => '/',
            'REQUEST_METHOD'       => 'GET',
            'REQUEST_URI'          => "/$ep",
            'X_ORIGINAL_URI'       => "/",
            'SERVER_PORT'          => '80',
            'SERVER_PROTOCOL'      => 'HTTP/1.1',
            'HTTP_USER_AGENT'      =>
              'Mozilla/5.0 (VAX-4000; rv:36.0) Gecko/20350101 Firefox',
            'REMOTE_ADDR' => '127.0.0.1',
            'HTTP_HOST'   => 'test1.example.com',
            'COOKIE'      => "lemonldap=$cookie",
        }
    ),
    'Forward logout'
);
count(1);

# Verify that there is no pdata
$cookies = getCookies($res);
$id;
ok(
    !defined( $id = $cookies->{'lemonldappdata'} ),
    " Verify absence of cookie lemonldappdata"
) or explain('Get lemonldappdata cookie');
count(1);

clean_sessions();

done_testing( count() );
