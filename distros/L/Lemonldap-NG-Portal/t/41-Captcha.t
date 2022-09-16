use Test::More;
use strict;
use IO::String;
use JSON;
use Lemonldap::NG::Portal::Main::Constants 'PE_CAPTCHAERROR';

require 't/test-lib.pm';

my $res;

my $maintests = 29;
SKIP: {
    eval 'use GD::SecurityImage; use Image::Magick;';
    if ($@) {
        skip 'Image::Magick not found', $maintests;
    }

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                  => 'error',
                useSafeJail               => 1,
                browsersDontStorePassword => 1,
                loginHistoryEnabled       => 1,
                captcha_login_enabled     => 1,
                portalMainLogo            => 'common/logos/logo_llng_old.png',
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

    # Test normal first access
    # ------------------------
    ok( $res = $client->_get('/'), 'Unauth JSON request' );
    expectReject($res);

    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Unauth request' );
    my ( $host, $url, $query ) = expectForm( $res, '#', undef, 'token' );
    ok( $res->[2]->[0] =~ m%<input[^>]*name="password"%,
        'Password: Found text input' );

    $query =~ s/.*\btoken=([^&]+).*/token=$1/;
    my $token;
    ok( $token = $1, ' Token value is defined' );
    ok( $res->[2]->[0] =~ m#<img id="captcha" src="data:image/png;base64#,
        ' Captcha image inserted' )
      or
      explain( $res->[2]->[0], '<img id="captcha" src="data:image/png;base64' );

    # Try to get captcha value
    my ( $ts, $captcha );
    ok( $ts = getCache()->get($token), ' Found token session' );
    $ts = eval { JSON::from_json($ts) };
    ok( $captcha = $ts->{captcha}, ' Found captcha value' );
    ok(
        $res->[2]->[0] =~ qr%<img src="/static/common/logos/logo_llng_old.png"%,
        'Found custom Main Logo'
    ) or print STDERR Dumper( $res->[2]->[0] );

    # Try to authenticate
    $query .= "&user=dwho&password=dwho&captcha=$captcha&checkLogins=1";
    ok(
        $res = $client->_post(
            '/',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Try to auth with captcha value'
    );
    expectOK($res);
    my $id = expectCookie($res);
    ok( $res->[2]->[0] =~ /trspan="lastLogins"/, 'History found' )
      or explain( $res->[2]->[0], 'trspan="noHistory"' );
    my @c = ( $res->[2]->[0] =~ /<td>127.0.0.1/gs );

    # History with 1 successLogin
    ok( @c == 1, " -> One entry found" );

    # Verify auth
    ok( $res = $client->_get( '/', cookie => "lemonldap=$id" ), 'Verify auth' );
    expectOK($res);

    # New try (with bad captcha)
    ok( $res = $client->_get( '/', accept => 'text/html' ),
        'New unauth request' );
    ( $host, $url, $query ) = expectForm( $res, '#', undef, 'token' );
    $query =~ s/.*\b(token=[^&]+).*/$1/;
    ok( $token = $1, ' Token value is defined' );

    # Try to auth with bad captcha
    $query .= '&user=dwho&password=dwho&captcha=00000';
    ok(
        $res = $client->_post(
            '/',
            IO::String->new($query),
            length => length($query)
        ),
        'Try to auth with bad captcha value'
    );
    expectReject($res);
    ok(
        $res = $client->_post(
            '/', IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Verify that there is a new captcha image'
    );
    ( $host, $url, $query ) = expectForm( $res, '#', undef, 'token' );
    $query =~ s/.*\b(token=[^&]+).*/$1/;
    my $newtoken = $1;
    ok( $newtoken ne $token, ' Token is refreshed' );
    ok( $res->[2]->[0] =~ m#<img id="captcha" src="data:image/png;base64#,
        ' New captcha image inserted' );
    ok(
        $res->[2]->[0] =~
m#<img class="renewcaptchaclick" src="/static/common/icons/arrow_refresh.png" alt="Renew Captcha" title="Renew Captcha" class="img-thumbnail mb-3" />#,
        ' Renew Captcha button found'
    ) or explain( $res->[2]->[0], 'Renew captcha button not found' );
    ok( $res->[2]->[0] =~ /captcha\.(?:min\.)?js/, 'Get captcha javascript' );

    # Try to renew captcha
    ok( $res = $client->_get( '/renewcaptcha', accept => 'text/html' ),
        'Unauth request to renew Captcha' );
    $json = eval { JSON::from_json( $res->[2]->[0] ) };
    ok( ( defined $json->{newtoken} and $json->{newtoken} =~ /^\w+$/ ),
        'New token has been received' )
      or explain( $json->{newtoken}, 'New token not received' );
    ok( (
            defined $json->{newimage}
              and $json->{newimage} =~ m%^data:image/png;base64,.+%
        ),
        'New image has been received'
    ) or explain( $json->{newimage}, 'NO image received' );

    # Try to submit new captcha
    ok( $ts = getCache()->get( $json->{newtoken} ),
        ' Found new token session' );
    $ts = eval { JSON::from_json($ts) };
    $query =
      "user=dwho&password=dwho&captcha=$ts->{captcha}&token=$json->{newtoken}";
    ok(
        $res = $client->_post(
            '/',
            IO::String->new($query),
            length => length($query)
        ),
        'Try to auth with new captcha value'
    );
    expectOK($res);
    $id = expectCookie($res);
    ok(
        $res = $client->_get(
            '/',
            query  => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==',
            cookie => "lemonldap=$id",
            accept => 'text/html'
        ),
        'Auth request with redirection'
    );
    expectRedirection( $res, 'http://test1.example.com/' );
    expectAuthenticatedAs( $res, 'dwho' );
}
count($maintests);

clean_sessions();

done_testing( count() );
