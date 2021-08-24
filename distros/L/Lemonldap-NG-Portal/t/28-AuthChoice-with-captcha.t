use Test::More;
use IO::String;
use strict;

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
                authentication        => 'Choice',
                userDB                => 'Same',
                passwordDB            => 'Choice',
                captcha_login_enabled => 1,
                authChoiceParam       => 'test',
                authChoiceModules     => {
                    '1_demo' => 'Demo;Demo;Null',
                    '2_ssl'  => 'SSL;Demo;Null',
                },
            }
        }
    );

    # Try to authenticate with an unknown user
    # -------------------
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get menu' );
    my ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'user', 'password', 'token' );

    $query =~ s/.*\btoken=([^&]+).*/token=$1/;
    my $token;
    ok( $token = $1, ' Token value is defined' );
    ok( $res->[2]->[0] =~ m#<img id="captcha" src="data:image/png;base64#,
        ' Captcha image inserted' );
    ok(
        $res->[2]->[0] =~
m#<img class="renewcaptchaclick" src="/static/common/icons/arrow_refresh.png"#,
        ' Renew Captcha button found'
    ) or explain( $res->[2]->[0], 'Renew captcha button not found' );
    ok( $res->[2]->[0] =~ /captcha\.(?:min\.)?js/, 'Get captcha javascript' );

    my @form = ( $res->[2]->[0] =~ m#<form.*?</form>#sg );
    ok( @form == 2, 'Display 2 choices' );
    foreach (@form) {
        expectForm( [ $res->[0], $res->[1], [$_] ], undef, undef, 'test' );
    }

    # Try to get captcha value
    my ( $ts, $captcha );
    ok( $ts = getCache()->get($token), ' Found token session' );
    $ts = eval { JSON::from_json($ts) };
    ok( $captcha = $ts->{captcha}, ' Found captcha value' );
    $query .= "&user=dalek&password=dwho&captcha=$captcha&test=1_demo";

    ok(
        $res = $client->_post(
            '/', IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Auth query with an unknown user'
    );
    ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'user', 'password', 'token' );

    ok(
        $res->[2]->[0] =~ /<span trmsg="5">/,
        'dalek rejected with PE_BADCREDENTIALS'
    ) or print STDERR Dumper( $res->[2]->[0] );

    # Try to authenticate
    # -------------------
    $query =~ s/.*\btoken=([^&]+).*/token=$1/;
    ok( $token = $1, ' Token value is defined' );
    ok( $res->[2]->[0] =~ m#<img id="captcha" src="data:image/png;base64#,
        ' Captcha image inserted' );

    @form = ( $res->[2]->[0] =~ m#<form.*?</form>#sg );
    ok( @form == 2, 'Display 2 choices' );
    foreach (@form) {
        expectForm( [ $res->[0], $res->[1], [$_] ], undef, undef, 'test' );
    }

    # Try to get captcha value
    ok( $ts = getCache()->get($token), ' Found token session' );
    $ts = eval { JSON::from_json($ts) };
    ok( $captcha = $ts->{captcha}, ' Found captcha value' );
    $query .= "&user=dwho&password=dwho&captcha=$captcha&test=1_demo";

    ok(
        $res = $client->_post(
            '/', IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Auth query'
    );
    my $id = expectCookie($res);
    $client->logout($id);
}
count($maintests);
clean_sessions();
done_testing( count() );
