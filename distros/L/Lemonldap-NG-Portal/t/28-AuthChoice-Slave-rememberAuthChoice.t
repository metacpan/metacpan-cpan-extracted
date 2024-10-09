use warnings;
use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel       => 'error',
            authentication => 'Choice',
            userDB         => 'Same',
            passwordDB     => 'Choice',

            authChoiceParam   => 'lmAuth',
            authChoiceModules => {
                slavechoice => 'Slave;Demo;Demo',
            },

            slaveUserHeader  => 'userid',
            slaveDisplayLogo => 1,

            rememberAuthChoiceRule => 1,
            rememberCookieName     => "llngrememberauthchoice",
            rememberCookieTimeout  => 31536000,
            rememberDefaultChecked => 0,
            rememberTimer          => 10,
        }
    }
);

subtest "Remember selection with non-null timeout" => sub {

    # Check web form
    ok( $res = $client->_get( '/', accept => 'text/html' ),
        'Get authentication portal' );
    my @form = ( $res->[2]->[0] =~ m#<form.*?</form>#sg );
    ok( @form == 1, 'Display 1 choice' ) or explain( scalar(@form), 1 );
    expectForm( [ $res->[0], $res->[1], [ $form[0] ] ], undef, undef,
        'lmAuth' );
    ok( $form[0] =~ /input type="hidden" id="rememberauthchoice"/ );

    # authentication with rememberauthchoice enabled
    ok(
        $res = $client->_get(
            '/',
            'accept' => 'text/html',
            'query'  => 'lmAuth=slavechoice&rememberauthchoice=true',
            'custom' => { 'HTTP_USERID' => 'dwho' }
        ),
        'Auth query with rememberauthchoice enabled'
    );
    my $id       = expectCookie($res);
    my $remember = expectCookie( $res, "llngrememberauthchoice" );
    ok( $remember eq "slavechoice", 'Get cookie with authentication' );

    $client->logout($id);

    # authentication with rememberauthchoice disabled
    ok(
        $res = $client->_get(
            '/',
            'accept' => 'text/html',
            'query'  => 'lmAuth=slavechoice&rememberauthchoice=false',
            'custom' => { 'HTTP_USERID' => 'dwho' }
        ),
        'Auth query with rememberauthchoice disabled'
    );
    $id       = expectCookie($res);
    $remember = expectCookie( $res, "llngrememberauthchoice" );
    ok( $remember eq "0", 'Get cookie removal' );

    $client->logout($id);
};

# Test auto-selection with 0 timer
subtest "Auto-selection with timer=0" => sub {
    $client->ini( { %{ $client->ini }, rememberTimer => 0 } );

    # Check web form with no cookie present
    ok( $res = $client->_get( '/', accept => 'text/html' ),
        'Get authentication portal' );
    expectPortalError( $res, 9 );

    # Autoselection if cookie is present
    ok(
        $res = $client->_get(
            '/',
            accept => 'text/html',
            cookie => "llngrememberauthchoice=slavechoice"
        ),
        'Get authentication portal'
    );
    expectPortalError( $res, 4 );

    # Authenticate
    ok(
        $res = $client->_get(
            '/',
            accept   => 'text/html',
            cookie   => "llngrememberauthchoice=slavechoice",
            'custom' => { 'HTTP_USERID' => 'dwho' }
        ),
        'Get authentication portal'
    );

    my $id       = expectCookie($res);
    my $remember = expectCookie( $res, "llngrememberauthchoice" );
    is( $remember, "slavechoice", 'Cookie is maintained' );
};

# Test to forget auth choice at logout
subtest "Forget auth choice at logout" => sub {
    $client->ini(
        { %{ $client->ini }, rememberAuthChoiceForgetAtLogout => 1 } );

    # Authenticate
    ok(
        $res = $client->_get(
            '/',
            accept   => 'text/html',
            'query'  => 'lmAuth=slavechoice&rememberauthchoice=true',
            'custom' => { 'HTTP_USERID' => 'dwho' }
        ),
        'Get authentication portal'
    );

    my $id       = expectCookie($res);
    my $remember = expectCookie( $res, "llngrememberauthchoice" );
    is( $remember, "slavechoice", 'AuthChoice cookie is set' );

    # Logout
    ok(
        $res = $client->_get(
            '/',
            accept => 'text/html',
            cookie => "lemonldap=$id",
            query  => "logout=1"
        ),
        'Logout'
    );

    $remember = expectCookie( $res, "llngrememberauthchoice" );
    is( $remember, "0", 'AuthCoice cookie is removed' );
};

clean_sessions();
done_testing();
