use Test::More;
use strict;
use IO::String;

BEGIN {
    eval {
        require 't/test-lib.pm';
        require 't/smtp.pm';
    };
}

my ( $res, $user, $pwd );
my $maintests = 15;

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
                captcha_mail_enabled       => 0,
                portalDisplayResetPassword => 1,
                customPlugins              => 't::PasswordHookPlugin',
            }
        }
    );

    # Test form
    # ------------------------
    ok( $res = $client->_get( '/resetpwd', accept => 'text/html' ),
        'Reset form', );
    my ( $host, $url, $query ) = expectForm( $res, '#', undef, 'mail' );

    $query = 'mail=dwho%40badwolf.org';

    # Post email
    ok(
        $res = $client->_post(
            '/resetpwd', IO::String->new($query),
            length => length($query),
            accept => 'text/html',
            cookie => 'llnglanguage=en',
        ),
        'Post mail'
    );

    like( mail(), qr#<span>Hello</span>#, "Found english greeting" );

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

    my $badquery = $query . '&newpassword=12345&confirmpassword=12345';

    # Post failing password
    ok(
        $res = $client->_post(
            '/resetpwd', IO::String->new($badquery),
            length => length($badquery),
            accept => 'text/html'
        ),
        'Post new password'
    );
    expectPortalError( $res, 28 );

    # Post email again
    $query = 'mail=dwho%40badwolf.org';
    ok(
        $res = $client->_post(
            '/resetpwd', IO::String->new($query),
            length => length($query),
            accept => 'text/html',
            cookie => 'llnglanguage=en',
        ),
        'Post mail'
    );

    like( mail(), qr#<span>Hello</span>#, "Found english greeting" );

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

    my $goodquery = $query . '&newpassword=12346&confirmpassword=12346';

    # Post accepted password
    ok(
        $res = $client->_post(
            '/resetpwd', IO::String->new($goodquery),
            length => length($goodquery),
            accept => 'text/html'
        ),
        'Post new password'
    );
    my $pdata = expectPdata($res);
    is( $pdata->{afterHook}, "dwho--12346",
        "passwordAfterChange hook worked as expected" );

    ok( mail() =~ /Your password was changed/, 'Password was changed' );
}
count($maintests);

clean_sessions();

done_testing( count() );
