use warnings;
use Test::More;
use strict;
use IO::String;
use JSON;
use Time::Fake;
use Plack::Request;
use Plack::Response;
use LWP::Protocol::PSGI;
use Lemonldap::NG::Portal::Main::Constants 'PE_CAPTCHAERROR';
use Plack::Builder;

require 't/test-lib.pm';

our $next_access_token         = "mytoken";
our $expected_access_token     = "mytoken";
our $access_token_called_count = 0;

LWP::Protocol::PSGI->register(
    builder {
        mount "http://oauth/token" => sub {
            $access_token_called_count++;
            my $req = Plack::Request->new(@_);
            is_deeply(
                $req->parameters->as_hashref,
                {
                    'client_id'     => 'myclientid',
                    'client_secret' => 'myclientsecret',
                    'grant_type'    => 'client_credentials',
                    'scope'         => 'myscope'
                }
            );
            return Plack::Response->new(
                200,
                [ "Content-Type" => "application/json" ],
                encode_json {
                    access_token => $next_access_token,
                    expires_in   => 600
                }
            )->finalize;
        };
        mount "http://captcha/api/valider-captcha" => sub {
            my $req = Plack::Request->new(@_);
            is(
                $req->headers->authorization,
                "Bearer $expected_access_token",
                "Found authorization header"
            );
            my $input = decode_json( $req->content );
            is( $input->{uuid}, "111-111", "Expected uuid" );
            ok( $input->{code}, "Code is defined" );
            if ( $input->{code} eq "111" ) {
                return Plack::Response->new( 200,
                    [ "Content-Type" => "application/json" ], "true" )
                  ->finalize;
            }
            else {
                return Plack::Response->new( 200,
                    [ "Content-Type" => "application/json" ], "false" )
                  ->finalize;
            }
        };
        mount "http://captcha/api/simple-captcha-endpoint" => sub {
            my $req = Plack::Request->new(@_);
            if ( $req->headers->authorization eq
                "Bearer $expected_access_token" )
            {
                return Plack::Response->new(
                    200,
                    [ "Content-Type" => "application/json" ],
                    encode_json {
                        "uuid"     => "yyy",
                        "imageb64" => "xxx"
                    }
                )->finalize;
            }
            else {
                return Plack::Response->new( 401,
                    [ "WWW-Authenticate" => 'Bearer error="invalid_token"' ],
                )->finalize;
            }
        };
    }
);

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            captcha        => "::Captcha::CaptchEtat",
            captchaOptions => {
                clientId           => "myclientid",
                clientSecret       => "myclientsecret",
                captchaStyleName   => "mystyle",
                oauthTokenEndpoint => "http://oauth/token",
                oauthScope         => "myscope",
                captchaApiBase     => "http://captcha/api",
            },
            requireToken              => 1,
            useSafeJail               => 1,
            browsersDontStorePassword => 1,
            captcha_login_enabled     => 1,
        }
    }
);

# Try to authenticate without captcha
# -----------------------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
    ),
    'Auth query'
);
expectReject($res);

my $json;
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{error} == PE_CAPTCHAERROR, 'Response is PE_CAPTCHAERROR' )
  or explain( $json, "error => 76" );

subtest "Test API proxy behavior" => sub {
    ok( $res = $client->_get('/simple-captcha-endpoint'),
        'Request to captcha proxy' );
    expectReject( $res, '400' );

    ok(
        $res = $client->_get(
            '/simple-captcha-endpoint', query => 'get=image&c=captchaFR'
        ),
        'Request to captcha proxy'
    );

    is_deeply(
        expectJSON($res),
        {
            'imageb64' => 'xxx',
            'uuid'     => 'yyy'
        },
        "Expected result"
    );
};

subtest "Post auth request with invalid Captcha" => sub {

    # Test normal first access
    # ------------------------
    ok( $res = $client->_get('/'), 'Unauth JSON request' );
    expectReject($res);

    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Unauth request' );

    expectXpath( $res, '//script[contains(@src,"common/js/captchetat-js.min.js")]',
        "Found JS" );
    expectXpath( $res, '//div[@id="captchetat"]', "Found CaptchEtat div" );
    expectXpath(
        $res,
        '//input[@name="captchaCode"]',
        "Found chaptcha code input"
    );

    my ( $host, $url, $query ) = expectForm( $res, '#', undef, 'captchaCode' );

    $query =~ s/user=/user=dwho/;
    $query =~ s/password=/password=dwho/;
    $query =~ s/captchaCode=/captchaCode=666/;
    $query .= "&captchetat-uuid=111-111";

    ok(
        $res = $client->_post(
            '/', $query, accept => 'text/html',
        ),
        'Auth query'
    );
    expectPortalError( $res, PE_CAPTCHAERROR );
    expectXpath( $res, '//script[contains(@src,"common/js/captchetat-js.min.js")]',
        "Found JS" );
    expectXpath( $res, '//div[@id="captchetat"]', "Found CaptchEtat div" );
    expectXpath(
        $res,
        '//input[@name="captchaCode"]',
        "Found chaptcha code input"
    );
};

subtest "Post auth request with valid Captcha" => sub {

    # Test normal first access
    # ------------------------
    ok( $res = $client->_get('/'), 'Unauth JSON request' );
    expectReject($res);

    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Unauth request' );

    expectXpath( $res, '//script[contains(@src,"common/js/captchetat-js.min.js")]',
        "Found JS" );
    expectXpath( $res, '//div[@id="captchetat"]', "Found CaptchEtat div" );
    expectXpath(
        $res,
        '//input[@name="captchaCode"]',
        "Found chaptcha code input"
    );

    my ( $host, $url, $query ) = expectForm( $res, '#', undef, 'captchaCode' );

    $query =~ s/user=/user=dwho/;
    $query =~ s/password=/password=dwho/;
    $query =~ s/captchaCode=/captchaCode=111/;
    $query .= "&captchetat-uuid=111-111";

    ok( $res = $client->_post( '/', $query, ), 'Auth query' );

    expectCookie($res);
};

subtest "Access token refresh" => sub {

    # Reinitialize portal
    $client->ini( $client->ini );

    $access_token_called_count = 0;

    _call_simple_captcha_endpoint($client);

    is( $access_token_called_count, 1, "Access Token endpoint was called" );

    _call_simple_captcha_endpoint($client);

    is( $access_token_called_count, 1,
        "token is still valid, access token was not refreshed" );

    Time::Fake->offset('+1h');

    _call_simple_captcha_endpoint($client);

    is( $access_token_called_count, 2, "token expired and was refreshed" );

    $expected_access_token = "mynewtoken";
    $next_access_token     = "mynewtoken";

    _call_simple_captcha_endpoint($client);

    is( $access_token_called_count, 3, "token failed and was refreshed" );

    $expected_access_token = "somethingelseentirely";

    ok(
        $res = $client->_get(
            '/simple-captcha-endpoint', query => 'get=image&c=captchafr'
        ),
        'request to captcha proxy'
    );
    is( $res->[0], 500, "Request failed" );

    is( $access_token_called_count, 4,
        "token failed, was refreshed, and failed again" );
};

sub _call_simple_captcha_endpoint {
    my ($client) = @_;
    ok(
        $res = $client->_get(
            '/simple-captcha-endpoint', query => 'get=image&c=captchafr'
        ),
        'request to captcha proxy'
    );
    is_deeply(
        expectJSON($res),
        {
            'imageb64' => 'xxx',
            'uuid'     => 'yyy'
        },
        "expected result"
    );
}

clean_sessions();
done_testing();
