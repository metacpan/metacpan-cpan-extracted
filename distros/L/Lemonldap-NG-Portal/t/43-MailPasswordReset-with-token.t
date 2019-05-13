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
my $maintests = 11;
my $mailSend  = 0;

my $mail2 = 0;

SKIP: {
    eval
      'require Email::Sender::Simple;use GD::SecurityImage;use Image::Magick;';
    if ($@) {
        skip 'Missing dependencies', $maintests;
    }

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel              => 'error',
                useSafeJail           => 1,
                portalDisplayRegister => 1,
                authentication        => 'Demo',
                userDB                => 'Same',
                passwordDB            => 'Demo',
                captcha_mail_enabled  => 0,
                requireToken          => '$env->{ipAddr} !~ /127\.0\.[1-3]\.1/',
                portalDisplayResetPassword => 1,
                portalMainLogo             => 'common/logos/logo_llng_old.png',
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
    my ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'mail', 'token' );

    $query =~ s/mail=&//;
    $query .= '&mail=dwho%40badwolf.org';

    # Post email
    ok(
        $res = $client->_post(
            '/resetpwd', IO::String->new($query),
            length => length($query),
            accept => 'text/html'
        ),
        'Post mail'
    );
    ok(
        $res->[2]->[0] =~ m%<img src="/static/common/logos/logo_llng_old.png"%,
        'Found custom Main Logo'
    ) or print STDERR Dumper( $res->[2]->[0] );
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

    $query .= '&newpassword=zz&confirmpassword=zz';

    # Post new password
    ok(
        $res = $client->_post(
            '/resetpwd', IO::String->new($query),
            length => length($query),
            accept => 'text/html'
        ),
        'Post new password'
    );

    ok( mail() =~ /Your password was changed/, 'Password was changed' );

    #print STDERR Dumper($query);
}
count($maintests);

clean_sessions();

done_testing( count() );
