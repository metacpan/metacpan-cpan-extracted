use warnings;
use Test::More;
use strict;
use IO::String;
use JSON;
use Lemonldap::NG::Portal::Main::Constants 'PE_CAPTCHAERROR';

require 't/test-lib.pm';

my $res;

my $maintests = 13;
SKIP: {
    eval 'use GD::SecurityImage; use Image::Magick;';
    if ($@) {
        skip 'Image::Magick not found', $maintests;
    }

    my $client = LLNG::Manager::Test->new(
        {
            ini => {
                useSafeJail               => 1,
                browsersDontStorePassword => 1,
                loginHistoryEnabled       => 1,
                captcha_login_enabled     => 'inSubnet("127.0.0.0/8")',
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
            ip => '10.2.3.4',
        ),
        'Auth query from non captcha network'
    );
    expectCookie($res);
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23,
        ),
        'Auth query from captcha network'
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
    $query .= "&user=dwho&password=dwho&captcha=$captcha";
    ok(
        $res = $client->_post(
            '/',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Try to auth with captcha value'
    );
    expectCookie($res);
}
count($maintests);

clean_sessions();

done_testing( count() );
