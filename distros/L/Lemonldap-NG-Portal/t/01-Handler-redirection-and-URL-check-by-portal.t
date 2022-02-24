use Test::More;
use strict;
use IO::String;

use Lemonldap::NG::Portal::Main::Constants qw(
  PE_FIRSTACCESS
);

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel       => 'error',
            useSafeJail    => 1,
            logger         => 'Lemonldap::NG::Common::Logger::Std',
            trustedDomains => 'courriel.example.com',
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

ok(
    $res = $app->( {
            'HTTP_ACCEPT'          => 'text/html',
            'SCRIPT_NAME'          => '/',
            'SERVER_NAME'          => '127.0.0.1',
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
            'HTTP_HOST'   => 'test1.example.com',
        }
    ),
    'Standard Handler'
);
count(1);

my ( $uri, $query ) =
  expectRedirection( $res, qr#http://auth\.example\.com([^\?])+\??(.*)# );

ok(
    $res = $client->_get(
        '/',
        query  => $query,
        accept => 'text/html',
    ),
    'Unauth portal request'
);
expectForm( $res, undef, undef, 'url' );
count(1);

ok(
    $res = $app->( {
            'HTTP_ACCEPT'          => 'text/html',
            'SCRIPT_NAME'          => '/',
            'SERVER_NAME'          => '127.0.0.1',
            'HTTP_CACHE_CONTROL'   => 'max-age=0',
            'HTTP_ACCEPT_LANGUAGE' => 'fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3',
            'PATH_INFO'            => '/',
            'REQUEST_METHOD'       => 'GET',
            'REQUEST_URI'          => "/service/home/~/",
            'X_ORIGINAL_URI'       => "/service/home/~/",
            'SERVER_PORT'          => '80',
            'SERVER_PROTOCOL'      => 'HTTP/1.1',
            'HTTP_USER_AGENT'      =>
              'Mozilla/5.0 (VAX-4000; rv:36.0) Gecko/20350101 Firefox',
            'REMOTE_ADDR' => '127.0.0.1',
            'HTTP_HOST'   => 'courriel.example.com',
        }
    ),
'Standard Handler with host value that contains a + character after base64 encoding'
);
count(1);

( $uri, $query ) =
  expectRedirection( $res, qr#http://auth\.example\.com([^\?])+\??(.*)# );

ok(
    $res = $client->_get(
        '/',
        query  => $query,
        accept => 'text/html',
    ),
    'Unauth portalrequest'
);
expectForm( $res, undef, undef, 'url' );
count(1);

clean_sessions();

done_testing( count() );
