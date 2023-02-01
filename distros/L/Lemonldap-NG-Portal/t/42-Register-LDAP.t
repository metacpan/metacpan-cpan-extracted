use Test::More;
use strict;
use IO::String;

BEGIN {
    eval {
        require 't/test-lib.pm';
        require 't/smtp.pm';
    };
}

my $maintests = 9;
my ( $res, $user, $pwd );

SKIP: {
    skip 'LLNGTESTLDAP is not set', $maintests unless ( $ENV{LLNGTESTLDAP} );
    require 't/test-ldap.pm';

    eval 'require Email::Sender::Simple';
    if ($@) {
        skip 'Missing dependencies', $maintests;
    }

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                 => 'error',
                useSafeJail              => 1,
                portalDisplayRegister    => 1,
                authentication           => 'LDAP',
                userDB                   => 'Same',
                registerDB               => 'LDAP',
                captcha_register_enabled => 0,
                ldapServer               => $main::slapd_url,
                ldapBase                 => 'ou=users,dc=example,dc=com',
                managerDn                => 'cn=admin,dc=example,dc=com',
                managerPassword          => 'admin',
            }
        }
    );

    # Test normal first access
    # ------------------------
    ok(
        $res = $client->_get( '/register', accept => 'text/html' ),
        'Unauth request',
    );
    my ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'firstname', 'lastname', 'mail' );

    ok(
        $res = $client->_post(
            '/register',
            IO::String->new(
                'firstname=fôo&lastname=bar&mail=foobar%40badwolf.org'),
            length => 53,
            accept => 'text/html'
        ),
        'Ask to create account'
    );
    expectOK($res);

    my $mail = mail();
    ok( $mail =~ m#a href="http://auth.example.com/register\?(.*?)"#,
        'Found register token' );
    $query = $1;
    ok( $query =~ /register_token=/, 'Found register_token' );
    ok( $mail  =~ /fôo/,             'UTF-8 works' ) or explain( $mail, 'fôo' );

    ok(
        $res =
          $client->_get( '/register', query => $query, accept => 'text/html' ),
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

    my $postString = 'user=' . $user . '&password=' . $pwd;
    ok(
        $res = $client->_post(
            '/', IO::String->new($postString),
            length => length($postString),
            accept => 'text/html'
        ),
        'Try to authenticate'
    );
    expectCookie($res);
}
count($maintests);
clean_sessions();

done_testing( count() );

