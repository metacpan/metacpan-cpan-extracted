use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;

my $maintests = 16;
SKIP: {
    eval 'use GD::SecurityImage;use Image::Magick;';
    if ($@) {
        skip 'Image::Magick not found', $maintests;
    }

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel              => 'error',
                useSafeJail           => 1,
                loginHistoryEnabled   => 1,
                captcha_login_enabled => 1,
                portalMainLogo        => 'common/logos/logo_llng_old.png',
            }
        }
    );

    # Test normal first access
    # ------------------------
    ok( $res = $client->_get('/'), 'Unauth JSON request' );
    expectReject($res);

    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Unauth request' );
    my ( $host, $url, $query ) = expectForm( $res, '#', undef, 'token' );
    $query =~ s/.*\btoken=([^&]+).*/token=$1/;
    my $token;
    ok( $token = $1, ' Token value is defined' );
    ok( $res->[2]->[0] =~ m#<img src="data:image/png;base64#,
        ' Captcha image inserted' );

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
    ok( $res->[2]->[0] =~ m#<img src="data:image/png;base64#,
        ' New captcha image inserted' );
}
count($maintests);

clean_sessions();

done_testing( count() );
