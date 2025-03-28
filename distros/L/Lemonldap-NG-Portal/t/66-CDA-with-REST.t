use warnings;
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;

use Lemonldap::NG::Portal::Main::Constants qw(
  PE_FIRSTACCESS
);

require 't/test-lib.pm';

my $res;
my $maintests = 7;
my $debug     = 'error';
my $client;

# Redefine LWP methods for tests
LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        ok( $req->uri =~ m#http://auth.example.com(.*?)(?:\?(.*))?$#,
            " @ REST REQUEST @" );
        count(1);
        my $url   = $1;
        my $query = $2;
        my $res;
        if ( $req->method =~ /^(post|put)$/i ) {
            my $mth = '_' . lc($1);
            my $s   = $req->content;
            ok(
                $res = $client->$mth(
                    $url,
                    IO::String->new($s),
                    length => length($s),
                    type   => $req->header('Content-Type'),
                ),
                ' Post request'
            );
            count(1);
            expectOK($res);
        }
        elsif ( $req->method =~ /^(get|delete)$/i ) {
            my $mth = '_' . lc($1);
            ok(
                $res = $client->$mth(
                    $url,
                    accept => $req->header('Accept'),
                    cookie => $req->header('Cookie'),
                    query  => $query,
                ),
                ' Execute request'
            );
            ok( ( $res->[0] == 200 or $res->[0] == 400 ),
                ' Response is 200 or 400' )
              or explain( $res->[0], '200 or 400' );
            count(2);
        }
        pass(' @ END OF REST REQUEST @');
        count(1);
        return $res;
    }
);

$client = register(
    'portal',
    sub {
        LLNG::Manager::Test->new(
            {
                ini => {
                    logLevel          => $debug,
                    useSafeJail       => 1,
                    cda               => 1,
                    restSessionServer => 1,
                    logger            => 'Lemonldap::NG::Common::Logger::Std',
                }
            }
        );
    }
);

# CDA with unauthentified user
ok(
    $res = $client->_get(
        '/',
        query  => 'url=aHR0cDovL3Rlc3QuZXhhbXBsZS5vcmcv',
        accept => 'text/html',
    ),
    'Unauth CDA request'
);
my ( $host, $url, $query ) = expectForm( $res, undef, undef, 'url' );
ok( $query =~ /\burl=aHR0cDovL3Rlc3QuZXhhbXBsZS5vcmcv\b/, ' check url value' );

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

($query) =
  expectRedirection( $res, qr#^http://test.example.org/\?(lemonldapcda=.*)$# );

# Handler part
use_ok('Lemonldap::NG::Handler::Server');
use_ok('Lemonldap::NG::Common::PSGI::Cli::Lib');

my ( $cli, $app );
&Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
$app = register(
    'app',
    sub {
        Lemonldap::NG::Handler::Server->run(
            {
                %{ $client->ini },
                globalStorage => 'Lemonldap::NG::Common::Apache::Session::REST',
                globalStorageOptions =>
                  { baseUrl => 'http://auth.example.com/sessions/global/' },
                localSessionStorage => undef,
            }
        );
    }
);

ok(
    $res = $app->(
        {
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
expectRedirection( $res, 'http://test.example.org/' );
my $cid = expectCookie($res);

ok(
    $res = $app->(
        {
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
expectOK($res);
expectAuthenticatedAs( $res, 'dwho' );

clean_sessions();

done_testing( count($maintests) );
