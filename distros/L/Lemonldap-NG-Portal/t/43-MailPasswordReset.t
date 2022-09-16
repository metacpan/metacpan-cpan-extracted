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
my $maintests = 18;

SKIP: {
    eval
      'require Email::Sender::Simple;use GD::SecurityImage;use Image::Magick;';
    if ($@) {
        skip 'Missing dependencies', $maintests;
    }

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                    => 'error',
                useSafeJail                 => 1,
                portalDisplayRegister       => 1,
                authentication              => 'Demo',
                userDB                      => 'Same',
                passwordDB                  => 'Demo',
                captcha_mail_enabled        => 0,
                portalDisplayResetPassword  => 1,
                portalMainLogo              => 'common/logos/logo_llng_old.png',
                portalDisplayPasswordPolicy => 1,
                passwordPolicyActivation    => 1,
                passwordPolicyMinUpper      => 1,
                passwordPolicyMinLower      => 1,
                passwordPolicyMinDigit      => 2,
                passwordPolicyMinSpeChar    => 1,
                passwordPolicySpecialChar   => '&%#'
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
            cookie => 'llnglanguage=fr',
        ),
        'Post mail'
    );
    like( mail(), qr#<span>Bonjour</span>#, "Found french greeting" );

    # Test another language (#1897)
    ok(
        $res = $client->_post(
            '/resetpwd', IO::String->new($query),
            length => length($query),
            accept => 'text/html',
            cookie => 'llnglanguage=en',
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
    ok( $res->[2]->[0] =~ /<span trspan="passwordPolicy">/,
        ' Found password policy' );
    ok(
        $res->[2]->[0] =~
/<span trspan="passwordPolicyMinLower">Minimal lower characters:<\/span> 1/,
        ' Found password policy min lower == 1'
    );
    ok(
        $res->[2]->[0] =~
/<span trspan="passwordPolicyMinUpper">Minimal upper characters:<\/span> 1/,
        ' Found password policy min upper == 1'
    );
    ok(
        $res->[2]->[0] =~
/<span trspan="passwordPolicyMinDigit">Minimal digit characters:<\/span> 2/,
        ' Found password policy min digit == 2'
    );
    ok(
        $res->[2]->[0] =~
/<span trspan="passwordPolicyMinSpeChar">Minimal special characters:<\/span> 1/,
        ' Found password policy min speChar == 1'
    );
    ok(
        $res->[2]->[0] =~
/<span trspan="passwordPolicySpecialChar">Allowed special characters:<\/span> &%#/,
        ' Found password special char list'
    );
    $query .= '&newpassword=zZ11#&confirmpassword=zZ11#';

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
}
count($maintests);

clean_sessions();

done_testing( count() );
