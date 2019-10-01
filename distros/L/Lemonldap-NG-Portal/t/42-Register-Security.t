use Test::More;
use strict;
use IO::String;

BEGIN {
    eval {
        require 't/test-lib.pm';
        require 't/smtp.pm';
    };
}

my $maintests = 5;
my ( $res, $user, $pwd );

SKIP: {
    eval 'require Email::Sender::Simple;use Text::Unidecode';
    if ($@) {
        skip 'Missing dependencies', $maintests;
    }

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                 => 'error',
                useSafeJail              => 1,
                portalDisplayRegister    => 1,
                authentication           => 'Demo',
                userDB                   => 'Same',
                registerDB               => 'Demo',
                captcha_register_enabled => 0,
                tokenUseGlobalStorage    => 1,
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
    ok( $query =~ /register_token=([^&]+)/, 'Found register_token' );
    my $token = $1;

    ok(
        $res = $client->_get(
            '/',
            length => 23,
            cookie => "lemonldap=$token",
        ),
        'Try to authenticate'
    );
    expectReject($res);
}
count($maintests);

clean_sessions();

done_testing( count() );

