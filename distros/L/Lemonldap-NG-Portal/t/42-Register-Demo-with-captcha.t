use Test::More;
use strict;
use IO::String;

BEGIN {
    eval {
        require 't/test-lib.pm';
        require 't/smtp.pm';
    };
}

my $maintests = 28;
my ( $res, $user, $pwd, $host, $url, $query );
my $mailSend = 0;

SKIP: {
    eval
'require Email::Sender::Simple;use GD::SecurityImage;use Image::Magick;use Text::Unidecode';
    if ($@) {
        skip 'Missing dependencies', $maintests;
    }

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                 => 'error',
                useSafeJail              => 1,
                portalDisplayRegister    => 1,
                registerDB               => 'Demo',
                captcha_register_enabled => 1,
                portalMainLogo           => 'common/logos/logo_llng_old.png',
            }
        }
    );

    # Try to register with an alredy existing mail address
    # ------------------------
    ok(
        $res = $client->_get( '/register', accept => 'text/html' ),
        'Unauth request',
    );
    ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'firstname', 'lastname', 'mail' );
    ok(
        $query =~
s/^.*token=([^&]+).*$/token=$1&firstname=who&lastname=doctor&mail=dwho%40badwolf.org/,
        'Token found'
    );
    my $token;
    ok( $token = $1, ' Token value is defined' );
    ok( $res->[2]->[0] =~ m#<img id="captcha" src="data:image/png;base64#,
        ' Captcha image inserted' )
      or print STDERR Dumper( $res->[2]->[0] );

    # Try to get captcha value
    my ( $ts, $captcha );
    ok( $ts = getCache()->get($token), ' Found token session' );
    $ts = eval { JSON::from_json($ts) };
    ok( $captcha = $ts->{captcha}, ' Found captcha value' );
    ok(
        $res->[2]->[0] =~ m%<img src="/static/common/logos/logo_llng_old.png"%,
        'Found custom Main Logo'
    ) or print STDERR Dumper( $res->[2]->[0] );
    ok(
        $res->[2]->[0] =~
m#<img class="renewcaptchaclick" src="/static/common/icons/arrow_refresh.png"#,
        ' Renew Captcha button found'
    ) or explain( $res->[2]->[0], 'Renew captcha button not found' );
    ok( $res->[2]->[0] =~ /captcha\.(?:min\.)?js/, 'Get captcha javascript' );

    $query .= "&captcha=$captcha";

    ok(
        $res = $client->_post(
            '/register',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html'
        ),
        'Ask to create account'
    );

    ok( $res->[2]->[0] =~ q%<span trmsg="80"></span>%,
        'Rejected -> Mail already exists' );
    ok(
        $res->[2]->[0] !~
          m%<form action="#" method="post" class="login" role="form">%,
        'No form found'
    );

    # Test normal first access
    # ------------------------
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
    ok(
        $res->[2]->[0] =~
m%<a class="btn btn-secondary" href="http://auth.example.com/register\?skin=bootstrap">%,
        'Found Register link & submit button'
    ) or print STDERR Dumper( $res->[2]->[0] );
    ok(
        $res = $client->_get( '/register', accept => 'text/html' ),
        'Unauth request',
    );
    ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'firstname', 'lastname', 'mail' );
    ok(
        $query =~
s/^.*token=([^&]+).*$/token=$1&firstname=foo&lastname=bar&mail=foobar%40badwolf.org/,
        'Token found'
    );
    ok( $token = $1, ' Token value is defined' );
    ok( $res->[2]->[0] =~ m#<img id="captcha" src="data:image/png;base64#,
        ' Captcha image inserted' )
      or print STDERR Dumper( $res->[2]->[0] );

    # Try to get captcha value
    ok( $ts = getCache()->get($token), ' Found token session' );
    $ts = eval { JSON::from_json($ts) };
    ok( $captcha = $ts->{captcha}, ' Found captcha value' );
    ok(
        $res->[2]->[0] =~ m%<img src="/static/common/logos/logo_llng_old.png"%,
        'Found custom Main Logo'
    ) or print STDERR Dumper( $res->[2]->[0] );
    $query .= "&captcha=$captcha";

    ok(
        $res = $client->_post(
            '/register',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html'
        ),
        'Ask to create account'
    );
    expectOK($res);

    ok( mail() =~ m#a href="http://auth.example.com/register\?(.*?)"#,
        'Found register token' );
    $query = $1;
    ok( $query =~ /register_token=/, 'Found register_token' );

    ok(
        $res = $client->_get(
            '/register',
            query  => $query,
            accept => 'text/html'
        ),
        'Push register_token'
    );
    expectOK($res);

    ok(
        mail() =~
          m#Your login is.+?<b>(\w+)</b>.*?Your password is.+?<b>(.*?)</b>#s,
        'Found user and password'
    );
    $user = $1;
    $pwd  = $2;
    ok( $user eq 'fbar', 'Get good login' );

    # Try to authenticate
    $query = '&user=fbar&password=fbar';

    ok(
        $res = $client->_post(
            '/', IO::String->new($query),
            length => length($query),
            accept => 'text/html'
        ),
        'Try to authenticate'
    );
    expectCookie($res);
}
count($maintests);

clean_sessions();

done_testing( count() );
