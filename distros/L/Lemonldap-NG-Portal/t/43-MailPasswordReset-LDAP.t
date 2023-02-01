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
my $maintests = 8;
my $mailSend  = 0;

my $mail2 = 0;

SKIP: {
    eval
      'require Email::Sender::Simple;use GD::SecurityImage;use Image::Magick;';
    if ($@) {
        skip 'Missing dependencies', $maintests;
    }

    skip 'LLNGTESTLDAP is not set', $maintests unless ( $ENV{LLNGTESTLDAP} );
    require 't/test-ldap.pm';

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                   => 'error',
                useSafeJail                => 1,
                portalDisplayRegister      => 1,
                authentication             => 'LDAP',
                userDB                     => 'Same',
                passwordDB                 => 'LDAP',
                ldapServer                 => $main::slapd_url,
                ldapBase                   => 'ou=users,dc=example,dc=com',
                managerDn                  => 'cn=admin,dc=example,dc=com',
                managerPassword            => 'admin',
                captcha_mail_enabled       => 0,
                portalDisplayResetPassword => 1,
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
            accept => 'text/html'
        ),
        'Post mail'
    );

    ok( mail() =~ m#a href="http://auth.example.com/resetpwd\?(.*?)"#,
        'Found link in mail' );
    $query = $1;

    ok(
        $res =
          $client->_get( '/resetpwd', query => $query, accept => 'text/html' ),
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

    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=zz'),
            length => 21
        ),
        'Auth query'
    );
    expectOK($res);
    my $id = expectCookie($res);

    $client->logout($id);

    #print STDERR Dumper($query);
}
count($maintests);
clean_sessions();
done_testing( count() );
