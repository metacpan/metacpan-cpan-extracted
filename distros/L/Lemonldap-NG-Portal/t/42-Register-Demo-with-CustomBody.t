use Test::More;
use strict;
use IO::String;

BEGIN {
    eval {
        require 't/test-lib.pm';
        require 't/smtp.pm';
    };
}

my $maintests = 16;
my ( $res, $user, $pwd, $mail, $subject, $email, $ipAddr );

SKIP: {
    eval 'require Email::Sender::Simple; use Text::Unidecode';
    if ($@) {
        skip 'Missing dependencies', $maintests;
    }

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel               => 'error',
                useSafeJail            => 1,
                portalDisplayRegister  => 1,
                authentication         => 'Demo',
                userDB                 => 'Same',
                registerDB             => 'Demo',
                registerTimeout        => '600',
                registerConfirmSubject => 'Registration demonstration',
                registerConfirmBody    =>
'Hello $firstname $lastname, follows this link to register your account $url
Expired time: $expMailDate $expMailTime',
                registerDoneSubject => 'Registration successful',
                registerDoneBody    =>
'Congratulations! Your account has been succesfully created with $mail from [$ipAddr]...
Login=$login & Password=$password - Thanks to LemonLDAP::NG team.
Go to Portal $url',
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

    $subject = subject();
    $mail    = mail();
    ok(
        $subject eq 'Registration demonstration',
        'Found custom registration subject'
    ) or explain( $subject, 'Custom registration subject' );
    ok(
        $mail =~
m#Hello Fôo Bà Bar, follows this link to register your account http://auth\.example\.com/register#s,
        'Found custom body'
    ) or explain( $mail, 'Custom body (link)' );
    ok( $mail =~ /[?&](register_token=\w+)/s, 'Found register_token' );
    $query = $1;
    ok( $mail =~ /Fôo/, 'UTF-8 works' ) or explain( $mail, 'Fôo' );
    ok( $mail =~ m#Expired time: \d{2}/\d{2}/\d{4} \d{2}:\d{2}#s, 'Found time' )
      or explain( $mail, 'Custom body (expired time)' );

    ok(
        $res =
          $client->_get( '/register', query => $query, accept => 'text/html' ),
        'Push register_token'
    );
    expectOK($res);

    $subject = subject();
    $mail    = mail();
    ok( $subject eq 'Registration successful', 'Found custom done subject' )
      or explain( $subject, 'Custom done subject' );
    ok(
        $mail =~
m#Congratulations! Your account has been succesfully created with (.+?) from \[(.+?)\]...#s,
        'Found email and ipAddr'
    ) or explain( $mail, 'Custom done body' );
    $email  = $1;
    $ipAddr = $2;
    ok( $email eq 'foobar@badwolf', 'Get good email' )
      or explain( $email, 'email' );
    ok( $ipAddr eq '127.0.0.1', 'Get good ipAddr' )
      or explain( $ipAddr, 'ipAddr' );
    ok(
        $mail =~
          m#Login=(\w+?) & Password=(.+?)- Thanks to LemonLDAP::NG team\.#s,
        'Found user and password'
    ) or explain( $mail, 'Custom done body ($login & $password)' );
    $user = $1;
    $pwd  = $2;
    ok( $user eq 'fbabar', 'Get good login' );
    ok( $mail =~ m#Go to Portal http://auth.example.com/\?skin=bootstrap#s,
        'Custom done body (Portal $url)' )
      or explain( $mail, 'Custom done body' );

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
