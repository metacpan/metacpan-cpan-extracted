use Test::More;
use strict;
use IO::String;
use Data::Dumper;

require 't/test-lib.pm';
require 't/smtp.pm';

use_ok('Lemonldap::NG::Common::FormEncode');

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

sub resendCode {
    my ( $res, $client ) = @_;

    clear_mail();
    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/mail2fcheck?skin=bootstrap', 'token', 'code' );

    like(
        $res->[2]->[0],
        qr,formaction=\"/mail2fresend\?skin=bootstrap\",,
        "Found resend button"
    );

    ok(
        $res = $client->_post(
            '/mail2fresend',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post code'
    );

    return ($res);
}

sub expectTooSoon {
    my ($res) = @_;
    like( $res->[2]->[0],
        qr,trspan=\"resendTooSoon\",, "Received invitation to try later" );
    ok( !mail(), "No mail sent" );
}

sub expectSentCode {
    my ($res) = @_;
    like(
        $res->[2]->[0],
        qr,trspan=\"enterMail2fCode\",,
        "Prompt indicates success"
    );

    like( mail(), qr%Doctor Who%,     'Found session attribute in mail' );
    like( mail(), qr%<b>(\d{4})</b>%, 'Found 2F code in mail' );

    mail() =~ qr%<b>(\d{4})</b>%;
    return $1;
}

sub init_login {

    my ($client) = @_;
    ok(
        my $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23,
            accept => 'text/html',
        ),
        'Auth query'
    );
    return $res;
}

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel             => 'error',
            mail2fActivation     => 1,
            mail2fCodeRegex      => '\d{4}',
            mail2fResendInterval => 30,
            authentication       => 'Demo',
            userDB               => 'Same',
        }
    }
);

# Try to authenticate
# -------------------

subtest 'Login on first try' => sub {

    # Login on first try
    my $res  = init_login($client);
    my $code = expectSentCode($res);
    $res = validateCode( $res, $client, $code );
    my $id = expectCookie($res);
    $client->logout($id);
};

subtest 'Login after several resend' => sub {
    my $res  = init_login($client);
    my $code = expectSentCode($res);

    $res = resendCode( $res, $client );
    expectTooSoon($res);

    Time::Fake->offset("+1m");

    $res = resendCode( $res, $client );
    my $new_code = expectSentCode($res);
    is( $new_code, $code, "Code hasn't changed" );

    $res = validateCode( $res, $client, $code );
    my $id = expectCookie($res);
    $client->logout($id);
};

clean_sessions();

done_testing();

