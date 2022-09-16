use lib 'inc';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use Plack::Request;
use JSON qw/from_json/;

require 't/test-lib.pm';

our $receivedCode;

LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        if ( $req->path_info eq '/init' ) {
            my $json = from_json( $req->content );
            is( $json->{user}, "dwho", ' Init req gives dwho' );
            is( $json->{uid},  "dwho", ' Found uid attribute' );
            my $code = $json->{code};
            ok( $code, "Received code from LLNG" );
            $receivedCode = $code;
        }
        elsif ( $req->path_info eq '/vrfy' ) {
            die "Not supposed to happen";
        }
        else {
            fail( ' Bad REST call ' . $req->path_info );
        }
        return [
            200,
            [ 'Content-Type' => 'application/json', 'Content-Length' => 12 ],
            ['{"result":1}']
        ];
    }
);

sub validateCode {
    my ( $res, $client, $code ) = @_;

    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/rest2fcheck?skin=bootstrap', 'token', 'code' );
    $query =~ s/code=/code=$receivedCode/;

    ok(
        $res = $client->_post(
            '/rest2fcheck',
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

    $receivedCode = "";
    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/rest2fcheck?skin=bootstrap', 'token', 'code' );

    like(
        $res->[2]->[0],
        qr,formaction=\"/rest2fresend\?skin=bootstrap\",,
        "Found resend button"
    );

    ok(
        $res = $client->_post(
            '/rest2fresend',
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
    ok( !$receivedCode, "No code sent" );
}

sub expectSentCode {
    my ($res) = @_;
    ok(
        $res->[2]->[0] =~ qr%<img src="/static/common/logos/logo_llng_old.png"%,
        'Found custom Main Logo'
    ) or print STDERR Dumper( $res->[2]->[0] );
    count(1);

    like(
        $res->[2]->[0],
        qr,trspan=\"enterRest2fCode\",,
        "Prompt indicates success"
    );

    ok( $receivedCode, "REST service received code" );
    return $receivedCode;
}

sub init_login {

    my ($client) = @_;
    ok(
        my $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho&checkLogins=1'),
            length => 37,
            accept => 'text/html',
        ),
        'Auth query'
    );
    return $res;
}

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel             => 'error',
            rest2fActivation     => 1,
            rest2fCodeActivation => '\d{6}',
            rest2fResendInterval => 30,
            rest2fInitUrl        => 'http://auth.example.com/init',
            rest2fInitArgs       => { uid => 'uid' },
            rest2fVerifyUrl      => 'http://auth.example.com/vrfy',
            loginHistoryEnabled  => 1,
            authentication       => 'Demo',
            userDB               => 'Same',
            portalMainLogo       => 'common/logos/logo_llng_old.png',
        }
    }
);

subtest 'Login on first try' => sub {

    # Login on first try
    my $res  = init_login($client);
    my $code = expectSentCode($res);
    $res = validateCode( $res, $client, $code );

    ok( $res->[2]->[0] =~ /trspan="lastLogins"/, 'History found' )
      or print STDERR Dumper( $res->[2]->[0] );
    my @c = ( $res->[2]->[0] =~ /<td>127.0.0.1/gs );
    ok( @c == 1, 'One entry found' );

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

