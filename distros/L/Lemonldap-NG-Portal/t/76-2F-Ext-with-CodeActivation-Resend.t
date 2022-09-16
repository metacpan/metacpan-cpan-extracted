use Test::More;
use strict;
use IO::String;
use Data::Dumper;

require 't/test-lib.pm';

# used by sendCode to store result. Use a random name so multiple tests using
# sendCode can run in paralell.
# (Change this value when copying this test!)
$ENV{llngtmpfile} = $main::tmpDir . "/Vonu2oom.out";

use_ok('Lemonldap::NG::Common::FormEncode');
count(1);

sub removeFile {
    my $filename = $ENV{llngtmpfile};
    unlink $filename;
}

sub getCodeFromFile {
    return do {
        local $/;
        my $filename = $ENV{llngtmpfile};
        open my $fh, $filename;
        <$fh>;
    };
}

sub validateCode {
    my ( $res, $client, $code ) = @_;

    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/ext2fcheck?skin=bootstrap', 'token', 'code' );

    $query =~ s/code=/code=${code}/;
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

sub resendCode {
    my ( $res, $client ) = @_;

    removeFile;
    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/ext2fcheck?skin=bootstrap', 'token', 'code' );

    like(
        $res->[2]->[0],
        qr,formaction=\"/ext2fresend\?skin=bootstrap\",,
        "Found resend button"
    );

    ok(
        $res = $client->_post(
            '/ext2fresend',
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
    ok( !getCodeFromFile, "No mail sent" );
}

sub expectSentCode {
    my ($res) = @_;

    ok(
        $res->[2]->[0] =~
qr%<input name="code" value="" type="text" class="form-control" id="extcode" trplaceholder="code" autocomplete="one-time-code" />%,
        'Found EXTCODE input'
    ) or print STDERR Dumper( $res->[2]->[0] );
    count(1);

    like( $res->[2]->[0],
        qr,trspan=\"enterExt2fCode\",, "Prompt indicates success" );

    my $code = getCodeFromFile;
    like( $code, qr/\d{6}/, "Code has the correct format" );

    return $code;
}

sub init_login {

    my ($client) = @_;

    removeFile;

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
            logLevel            => 'error',
            ext2fActivation     => 1,
            ext2fCodeActivation => '\d{6}',
            ext2FSendCommand    => 't/sendCode.pl -uid $uid -code $code',
            ext2fResendInterval => 30,
            authentication      => 'Demo',
            userDB              => 'Same',
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

