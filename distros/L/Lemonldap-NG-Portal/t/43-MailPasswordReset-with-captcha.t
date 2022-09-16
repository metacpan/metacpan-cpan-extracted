use Test::More;
use strict;
use IO::String;

BEGIN {
    eval {
        require 't/test-lib.pm';
        require 't/smtp.pm';
    };
}

my ( $res, $host, $url, $query );
my $maintests = 18;
my $mailSend  = 0;
my $mail2     = 0;

SKIP: {
    eval
      'require Email::Sender::Simple;use GD::SecurityImage;use Image::Magick;';
    if ($@) {
        skip 'Missing dependencies', $maintests;
    }

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                   => 'error',
                useSafeJail                => 1,
                portalDisplayRegister      => 1,
                authentication             => 'Demo',
                userDB                     => 'Same',
                passwordDB                 => 'Demo',
                captcha_mail_enabled       => 1,
                requireToken               => 1,
                portalDisplayResetPassword => 1,
                portalMainLogo             => 'common/logos/logo_llng_old.png',
                passwordPolicyActivation   => 1,
                passwordPolicyMinUpper     => 1,
                passwordPolicyMinLower     => 1,
                passwordPolicyMinDigit     => 2,
                passwordPolicyMinSpeChar   => 1,
                randomPasswordRegexp       => '',
                passwordPolicySpecialChar  => '*#@'
            }
        }
    );

    # Test form
    # ------------------------
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
    ok(
        $res->[2]->[0] =~
m%<a class="btn btn-secondary" href="http://auth.example.com/resetpwd\?skin=bootstrap">%,
        'Found ResetPassword link & submit button'
    ) or print STDERR Dumper( $res->[2]->[0] );
    ok( $res = $client->_get( '/resetpwd', accept => 'text/html' ),
        'Reset form', );
    ( $host, $url, $query ) = expectForm( $res, '#', undef, 'mail', 'token' );

    $query =~ s/mail=&//;
    $query .= '&mail=dwho%40badwolf.org';

    # Check captcha
    my ($token) = ( $query =~ /token=([^&]+)/ );
    ok( $res->[2]->[0] =~ m#<img id="captcha" src="data:image/png;base64#,
        ' Captcha image inserted' );

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

    # Post email
    ok(
        $res = $client->_post(
            '/resetpwd', IO::String->new($query),
            length => length($query),
            accept => 'text/html'
        ),
        'Post mail'
    );
    ok( mail() =~ m%Content-Type: image/png; name="logo_llng_old.png"%,
        'Found custom Main logo in mail' )
      or print STDERR Dumper( mail() );

    ok( mail() =~ m#a href="http://auth.example.com/resetpwd\?(.*?)"#,
        'Found link in mail' );
    $query = $1;

    ok(
        $res = $client->_get(
            '/resetpwd',
            query  => $query,
            accept => 'text/html'
        ),
        'Post mail token received by mail'
    );
    ( $host, $url, $query ) = expectForm( $res, '#', undef, 'token' );
    ok( $res->[2]->[0] =~ /newpassword/s, ' Ask for a new password' );

    $query .= '&reset=1';

    # Post new password
    ok(
        $res = $client->_post(
            '/resetpwd', IO::String->new($query),
            length => length($query),
            accept => 'text/html'
        ),
        'Post new password'
    );
    ok( mail() =~ /<span>Your new password is<\/span>/, 'New password sent' );
    ok( mail() =~ /<b>(.+?)<\/b>/s, 'New generated password found' );
    ok(
        $1 =~ /[A-Z]{1}[a-z]{1}\d{2}[*#@]{1}/,
        'New generated password matches'
    );

    #print STDERR Dumper($query);
}
count($maintests);

clean_sessions();

done_testing( count() );
