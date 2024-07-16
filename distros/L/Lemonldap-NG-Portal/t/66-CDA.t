use warnings;
use Test::More;
use strict;
use IO::String;

use Lemonldap::NG::Portal::Main::Constants qw(
  PE_FIRSTACCESS
);

require 't/test-lib.pm';

my $res;
my $client = LLNG::Manager::Test->new(
    {
        ini => {
            logLevel    => 'error',
            useSafeJail => 1,
            cda         => 1,
            logger      => 'Lemonldap::NG::Common::Logger::Std',
        }
    }
);

subtest "Check that external URLs are correctly classified" => sub {
    my $cda_plugin =
      $client->p->loadedModules->{'Lemonldap::NG::Portal::Plugins::CDA'};
    my $req = Lemonldap::NG::Portal::Main::Request->new(
        { REQUEST_URI => "/", PATH_INFO => "" } );

    my @tests = (

        # DOMAIN, URLDC, EXPECTED RESULT
        [ ".example.com", "https://example.com/",       0 ],
        [ ".example.com", "http://auth.example.com/",   0 ],
        [ ".example.com", "https://auth.example.com/",  0 ],
        [ ".example.com", "http://example.org/",        1 ],
        [ ".example.com", "https://example.org/",       1 ],
        [ ".example.com", "https://example.org",        1 ],
        [ ".example.com", "https://auth.example.comx/", 1 ],
        [ ".example.com", "https://otherexample.com/",  1 ],
        [ "",             "https://example.com/",       0 ],
        [ "",             "https://example.comx/",      1 ],
        [ "",             "https://xexample.com/",      1 ],
        [ "",             "http://auth.example.com/",   1 ],
        [ "",             "https://auth.example.com/",  1 ],
        [ "",             "http://example.org/",        1 ],
        [ "",             "https://example.org/",       1 ],
        [ "",             "https://example.org",        1 ],
        [ "",             "https://auth.example.comx/", 1 ],
        [ "",             "https://otherexample.com/",  1 ],
    );
    for (@tests) {
        my ( $domain, $urldc, $result ) = @$_;
        my $log       = $result ? "is external"    : "is not external";
        my $domainlog = $domain ? "domain $domain" : "empty domain";
        is(
            $cda_plugin->_cookie_can_be_seen( "https://example.com",
                $domain, $urldc, $urldc )
              || 0,
            $result,
            "URL $urldc $log for $domainlog"
        );
    }
};
count(1);

# CDA with unauthentified user
ok(
    $res = $client->_get(
        '/',
        query => buildForm(
            {
                url => encodeUrl('http://test.example.org/'),
            }
        ),
        accept => 'text/html',
    ),
    'Unauth CDA request'
);
my ( $host, $url, $query ) = expectForm( $res, undef, undef, 'url' );
ok( $query =~ /\burl=aHR0cDovL3Rlc3QuZXhhbXBsZS5vcmcv\b/, ' check url value' );
count(2);

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
my $id = expectCookie($res);

($query) =
  expectRedirection( $res, qr#^http://test.example.org/\?(lemonldapcda=.*)$# );

# Check URLs are correctly filtered
ok(
    $res = $client->_get(
        '/',
        query => buildForm(
            {
                url => encodeUrl(
'http://your-untrusted-domain.com/?attack=http://test.example.org/'
                ),
            }
        ),
        cookie => "lemonldap=$id",
        accept => 'text/html',
    ),
    'Dangerous request'
);
count(1);

expectPortalError( $res, 109, "Untrusted URL denied by portal" );

# Handler part
use_ok('Lemonldap::NG::Handler::Server');
use_ok('Lemonldap::NG::Common::PSGI::Cli::Lib');
count(2);

my ( $cli, $app );
ok( $app = Lemonldap::NG::Handler::Server->run( $client->ini ), 'App' );
count(1);

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
count(1);
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
count(1);
expectOK($res);
expectAuthenticatedAs( $res, 'dwho' );

clean_sessions();

done_testing( count() );
