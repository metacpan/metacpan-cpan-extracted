use Test::More;
use strict;
use IO::String;

BEGIN {
    eval {
        require 't/test-lib.pm';
        require 't/smtp.pm';
    };
}

my $maintests = 12;
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
                registerDB               => 'Demo',
                captcha_register_enabled => 0,
                requireToken             =>
                  '!$env->{ipAddr} || $env->{ipAddr} ne "127.1.1.1"',
            }
        }
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
    my ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'firstname', 'lastname', 'mail' );
    ok(
        $query =~
s/^.*(token=[^&]+).*$/$1&firstname=foo&lastname=bar&mail=foobar%40badwolf.org/,
        'Token found'
    );

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
        'Found register token' )
      or print STDERR Dumper($main::mail);
    $query = $1;
    ok( $query =~ /register_token=/, 'Found register_token' );

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

    # Try to authenticate
    #  1. get token
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Unauth request' );

    ( $host, $url, $query ) = expectForm( $res, '#', undef, 'token' );
    $query =~ s/.*\b(token=[^&]+).*/$1&user=fbar&password=fbar/;

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

