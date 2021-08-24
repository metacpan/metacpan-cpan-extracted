use Test::More;
use strict;
use JSON;
use IO::String;

require 't/test-lib.pm';

my $res;
my $json;
my $ts;
my $captcha;
my $maintests = 16;
SKIP: {
    eval 'use GD::SecurityImage;use Image::Magick;';
    if ($@) {
        skip 'Image::Magick not found', $maintests;
    }
    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                    => 'error',
                authentication              => 'Demo',
                userDB                      => 'Same',
                useSafeJail                 => 1,
                captcha_login_enabled       => 1,
                findUser                    => 1,
                impersonationRule           => 1,
                findUserSearchingAttributes => {
                    'uid##1' => 'Login',
                    'guy##1' => 'Kind',
                    'cn##1'  => 'Name'
                }
            }
        }
    );

    ## Simple access
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Portal', );
    my ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'user', 'password', 'spoofId', 'token' );
    ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'uid', 'guy', 'cn', 'token' );
    ok(
        $res->[2]->[0] =~
          m%<input id="token" type="hidden" name="token" value="([\d_]+?)" />%,
        'Token value found'
    ) or explain( $res->[2]->[0], 'Token value' );
    my $count = $res->[2]->[0] =~ s/$1//g;
    ok( $count == 2, 'Two token found' )
      or explain( $res->[2]->[0], 'Two token found' );
    ok( $res->[2]->[0] =~ m#<img id="captcha" src="data:image/png;base64#,
        ' Captcha image inserted' );
    ok(
        $res->[2]->[0] =~
m#<img class="renewcaptchaclick" src="/static/common/icons/arrow_refresh.png"#,
        ' Renew Captcha button found'
    ) or explain( $res->[2]->[0], 'Renew captcha button not found' );
    ok( $res->[2]->[0] =~ /captcha\.(?:min\.)?js/, 'Get captcha javascript' );

    ## FindUser request
    $query =~ s/uid=/uid=rt*/;
    ok(
        $res = $client->_post(
            '/finduser', IO::String->new($query),
            accept => 'application/json',
            length => length($query)
        ),
        'Post FindUser request'
    );
    ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
      or print STDERR "$@\n" . Dumper($res);
    ok( $json->{user} eq 'rtyler', ' Good user' )
      or explain( $json, 'user => rtyler' );
    ok( $json->{token} =~ /\w+/, ' Token found' )
      or explain( $json, 'Token renewed' );
    ok( $json->{captcha} =~ /^data:image\/png;base64/, ' Captcha found' )
      or explain( $json, 'Captcha renewed' );
    ok( $json->{result} == 1, ' result => 1' )
      or explain( $json, 'Result => 1' );
    my $token = $json->{token};
    ok( $ts = getCache()->get($token), ' Found token session' );
    $ts = eval { JSON::from_json($ts) };
    ok( $captcha = $ts->{captcha}, ' Found captcha value' );

    ## Authentication request
    $query =
      "user=dwho&password=dwho&spoofId=rtyler&token=$token&captcha=$captcha";
    ok(
        $res = $client->_post(
            '/', IO::String->new($query),
            accept => 'application/json',
            length => length($query)
        ),
        'Post Auth request with token'
    );
    my $id = expectCookie($res);
    ok(
        $res = $client->_get(
            '/',
            accept => 'text/html',
            cookie => "lemonldap=$id",
        ),
        'GET Portal'
    );
    expectOK($res);
    expectAuthenticatedAs( $res, 'rtyler' );
    $client->logout($id);
}
count($maintests);
clean_sessions();
done_testing( count() );

