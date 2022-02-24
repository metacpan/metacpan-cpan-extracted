use Test::More;
use strict;
use IO::String;

BEGIN {
    eval {
        require 't/test-lib.pm';
        require 't/smtp.pm';
    };
}

my $maintests = 11;
my ( $res, $user, $pwd, $mail, $subject );

SKIP: {
    eval 'require Email::Sender::Simple; use Text::Unidecode';
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
                registerDB               => 'Custom',
                customRegister           => '::Register::Demo',
                registerConfirmSubject   => 'Demonstration',
                captcha_register_enabled => 0,
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
                'firstname=Fôo&lastname=Bà Bar&mail=foobar%40badwolf.org'),
            length => 53,
            accept => 'text/html'
        ),
        'Ask to create account'
    );
    expectOK($res);

    $mail    = mail();
    $subject = subject();
    ok( $subject eq 'Demonstration', 'Found subject' )
      or explain( $subject, 'Custom subject' );
    ok( $mail =~ m#a href="http://auth.example.com/register\?(.+?)"#,
        'Found register token' )
      or explain( $mail, 'Confirm body' );
    $query = $1;
    ok( $query =~ /register_token=/, 'Found register_token' );
    ok( $mail  =~ /Fôo/,             'UTF-8 works' ) or explain( $mail, 'Fôo' );

    ok(
        $res =
          $client->_get( '/register', query => $query, accept => 'text/html' ),
        'Push register_token'
    );
    expectOK($res);

    $mail    = mail();
    $subject = subject();
    ok( $subject eq '[LemonLDAP::NG] Your new account', 'Found subject' )
      or explain( $subject, 'Default subject' );
    ok(
        $mail =~
          m#Your login is.+?<b>(\w+)</b>.*?Your password is.+?<b>(.*?)</b>#s,
        'Found user and password'
    ) or explain( $mail, 'Done body' );
    $user = $1;
    $pwd  = $2;
    ok( $user eq 'fbabar', 'Get good login' );

    ok(
        $res = $client->_post(
            '/', IO::String->new("user=fbabar&password=fbabar"),
            length => 27,
            accept => 'text/html'
        ),
        'Try to authenticate'
    );
    expectCookie($res);
}
count($maintests);

clean_sessions();

done_testing( count() );
