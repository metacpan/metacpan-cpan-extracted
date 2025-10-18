use warnings;
use Test::More;
use strict;
use IO::String;
use Data::Dumper;
use Lemonldap::NG::Common::TOTP;

require 't/test-lib.pm';
require 't/smtp.pm';

use_ok('Lemonldap::NG::Common::FormEncode');

sub totp {
    my ($key) = @_;
    return Lemonldap::NG::Common::TOTP::_code( undef,
        Convert::Base32::decode_base32($key),
        0, 30, 6 );

}

sub validateExt {
    my ( $res, $client ) = @_;

    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/ext2fcheck?skin=bootstrap', 'token', 'code' );

    $query =~ s/code=/code=123456/;

    ok(
        $res = $client->_post(
            '/ext2fcheck',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post code'
    );
    return $res;

}

sub validateCode {
    my ( $res, $client, $code ) = @_;

    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/mail2fcheck?skin=bootstrap', 'token', 'code' );

    $query =~ s/code=/code=${code}/;

    ok(
        $res = $client->_post(
            '/mail2fcheck',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post code'
    );
    return $res;

}

sub expectExtPrompt {
    my ($res) = @_;
    like( $res->[2]->[0],
        qr,trspan=\"enterExt2fCode\",, "Prompt indicates success" );
}

sub expectSentCode {
    my ($res) = @_;
    like(
        $res->[2]->[0],
        qr,trspan=\"enterMail2fCode\",,
        "Prompt indicates success"
    );

    like( mail(), qr%<b>(\d{4})</b>%, 'Found 2F code in mail' );

    mail() =~ qr%<b>(\d{4})</b>%;
    return $1;
}

sub browserChallenge {
    my ( $res, $client, $stay, $secret ) = @_;

    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/checkbrowser', 'fg', 'token' );

    # Push fingerprint
    my $code = totp($secret);
    $query =~ s/fg=/fg=TOTP_$code/;
    my $res2;
    ok(
        $res2 = $client->_post(
            '/checkbrowser',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
            cookie => "llngconnection=$stay",
        ),
        'Post fingerprint'
    );
    return $res2;
}

sub rememberBrowser {
    my ( $res, $client ) = @_;

    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/registerbrowser', 'fg', 'token' );

    my ($totpsecret) = $query =~ /totpsecret=([^&]*)/;
    ok( $totpsecret, "Found TOTP secret" );
    my $code = totp($totpsecret);

    # Push fingerprint
    $query =~ s/fg=/fg=TOTP_$code/;
    my $res2;
    ok(
        $res2 = $client->_post(
            '/registerbrowser',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post fingerprint'
    );
    return ( $res2, $totpsecret );
}

sub init_login {

    my ( $client, $uid, $connection, $expect_sc, $select_sc ) = @_;
    my $res;
    ok(
        $res = $client->_get(
            '/',
            accept => 'text/html',
            ( $connection ? ( cookie => "llngconnection=$connection" ) : () ),
        ),
        "Auth query"
    );

    my ( $host, $url, $query ) = expectForm($res);

    if ($expect_sc) {
        like( $query, qr/stayconnected=/, "Found stayconnected checkbox" );
        $query =~ s/stayconnected=[^&]*/stayconnected=1/ if $select_sc;
    }
    else {
        unlike( $query, qr/stayconnected=/, "Found stayconnected checkbox" );
        $query .= "&stayconnected=1" if $select_sc;
    }

    $query =~ s/user=/user=$uid/;
    $query =~ s/password=/password=$uid/;

    ok(
        $res = $client->_post(
            '/',
            $query,
            accept => 'text/html',
            ( $connection ? ( cookie => "llngconnection=$connection" ) : () ),
        ),
        'Auth POST query'
    );

    return $res;
}

sub expect_2fa_choice {
    my ( $client, $res, $sfchoice ) = @_;
    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/2fchoice', 'token' );
    my $res2;
    $query .= "&sf=$sfchoice";

    ok(
        $res2 = $client->_post(
            '/2fchoice',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post 2F choice'
    );
    return $res2;

}

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel           => 'error',
            trustedBrowserRule =>
              '$_2f eq "mail" and ($uid eq "dwho" or $uid eq "rtyler")',
            mail2fActivation     => '!$_trustedBrowser',
            mail2fCodeRegex      => '\d{4}',
            mail2fResendInterval => 30,
            mail2fAuthnLevel     => 3,
            ext2fActivation      => '!$_trustedBrowser',
            ext2fAuthnLevel      => 5,
            ext2fCodeActivation  => '123456',
            ext2FSendCommand     => '/bin/true',
            authentication       => 'Demo',
            userDB               => 'Same',
            stayConnectedTimeout => ( 24 * 3600 * 30 ),
        }
    }
);

# Try to authenticate
# -------------------

subtest 'Store browser, then reuse it' => sub {

    # Login on first try
    my $res = init_login( $client, 'dwho', undef, 1, 1 );
    $res = expect_2fa_choice( $client, $res, "mail" );
    my $code = expectSentCode($res);
    $res = validateCode( $res, $client, $code );
    ( $res, my $secret ) = rememberBrowser( $res, $client );
    my $id   = expectCookie($res);
    my $stay = expectCookie( $res, 'llngconnection' );
    is( getSession($id)->data->{authenticationLevel},
        3, "Authentication level was set" );

    Time::Fake->offset("+15d");
    $res = init_login( $client, 'dwho', $stay, 0, 0 );
    $res = browserChallenge( $res, $client, $stay, $secret );
    $id  = expectCookie($res);
    is( getSession($id)->data->{authenticationLevel},
        3, "Authentication level was restored" );
    $client->logout($id);
    Time::Fake->reset;
};

subtest 'Store browser, then reuse it after cookie expiration' => sub {

    # Login on first try
    my $res = init_login( $client, 'dwho', undef, 1, 1 );
    $res = expect_2fa_choice( $client, $res, "mail" );
    my $code = expectSentCode($res);
    $res = validateCode( $res, $client, $code );
    ( $res, my $secret ) = rememberBrowser( $res, $client );
    my $id   = expectCookie($res);
    my $stay = expectCookie( $res, 'llngconnection' );

    Time::Fake->offset("+55d");
    $res = init_login( $client, 'dwho', $stay, 1, 0 );
    ok( !expectCookie( $res, "llngconnection" ), "Old cookie is removed" );

    $res  = expect_2fa_choice( $client, $res, "mail" );
    $code = expectSentCode($res);
    $res  = validateCode( $res, $client, $code );
    $id   = expectCookie($res);
    $client->logout($id);
    Time::Fake->reset;
};

subtest 'Store browser, then try to reuse it with wrong cookie' => sub {

    # Login on first try
    my $res = init_login( $client, 'dwho', undef, 1, 1 );
    $res = expect_2fa_choice( $client, $res, "mail" );
    my $code = expectSentCode($res);
    $res = validateCode( $res, $client, $code );
    ( $res, my $secret ) = rememberBrowser( $res, $client );
    my $id   = expectCookie($res);
    my $stay = expectCookie( $res, 'llngconnection' );

    $res = init_login( $client, 'dwho', "1234", 1, 0 );
    ok( !expectCookie( $res, "llngconnection" ), "Wrong cookie is removed" );
    $res  = expect_2fa_choice( $client, $res, "mail" );
    $code = expectSentCode($res);
    $res  = validateCode( $res, $client, $code );
    $id   = expectCookie($res);
    $client->logout($id);
};

subtest 'Store browser, then try to reuse it with wrong TOTP secret' => sub {

    # Login on first try
    my $res = init_login( $client, 'dwho', undef, 1, 1 );
    $res = expect_2fa_choice( $client, $res, "mail" );
    my $code = expectSentCode($res);
    $res = validateCode( $res, $client, $code );
    ( $res, my $secret ) = rememberBrowser( $res, $client );
    my $id   = expectCookie($res);
    my $stay = expectCookie( $res, 'llngconnection' );

    $res = init_login( $client, 'dwho', $stay, 0, 0 );
    $res = browserChallenge( $res, $client, $stay,
        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" );
    expectPortalError( $res, 24 );
    ok(
        !expectCookie( $res, "llngconnection" ),
        "Cookie with mismatched TOTP is removed"
    );
};

subtest 'Store browser, then try to reuse as different user' => sub {

    # Login on first try
    my $res = init_login( $client, 'dwho', undef, 1, 1 );
    $res = expect_2fa_choice( $client, $res, "mail" );
    my $code = expectSentCode($res);
    $res = validateCode( $res, $client, $code );
    ( $res, my $secret ) = rememberBrowser( $res, $client );
    my $id   = expectCookie($res);
    my $stay = expectCookie( $res, 'llngconnection' );

    $res  = init_login( $client, 'rtyler', $stay, 0, 1 );
    $res  = expect_2fa_choice( $client, $res, "mail" );
    $code = expectSentCode($res);
    $res  = validateCode( $res, $client, $code );
    ( $res, $secret ) = rememberBrowser( $res, $client );
    $id = expectCookie($res);
    $client->logout($id);
};

subtest 'User can refuse to stay connected' => sub {

    # Login on first try
    my $res = init_login( $client, 'rtyler', undef, 1, 0 );
    $res = expect_2fa_choice( $client, $res, "mail" );
    my $code = expectSentCode($res);
    $res = validateCode( $res, $client, $code );
    my $id = expectCookie($res);
    $client->logout($id);
};

subtest 'User cannot bypass the trusted browser rule (wrong 2f type)' => sub {

    # Login on first try
    my $res = init_login( $client, 'dwho', undef, 1, 1 );
    $res = expect_2fa_choice( $client, $res, "ext" );
    expectExtPrompt($res);
    $res = validateExt( $res, $client );
    my $cookies = getCookies($res);
    ok( !$cookies->{llngconnection},
        "Persistent connection cookie isn't sent" );
    my $id = expectCookie($res);

    #$client->logout($id);
};

subtest 'User cannot bypass the trusted browser rule (wrong user)' => sub {

    # Login on first try
    my $res = init_login( $client, 'msmith', undef, 1, 1 );
    $res = expect_2fa_choice( $client, $res, "mail" );
    my $code = expectSentCode($res);
    $res = validateCode( $res, $client, $code );
    my $cookies = getCookies($res);
    ok( !$cookies->{llngconnection},
        "Persistent connection cookie isn't sent" );
    my $id = expectCookie($res);

    #$client->logout($id);
};

clean_sessions();

done_testing();

