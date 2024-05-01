use warnings;
use Test::More;
use strict;
use IO::String;
use Data::Dumper;
use Lemonldap::NG::Common::TOTP;

require 't/test-lib.pm';
require 't/smtp.pm';

use_ok('Lemonldap::NG::Common::FormEncode');

# in seconds
our $time_offset_auto_increase = 0;
our $time_offset = 0;

sub resetTimeOffset {
    our $time_offset = 0;
    Time::Fake->reset;
}

sub timeOffsetIncrease {
    my ($delay) = @_;
    if ( $delay != 0 )
    {
        $time_offset += $delay;
        Time::Fake->offset("+${time_offset}s");
    }
}

sub sendExt {
    my ( $res, $client, $correct_code ) = @_;

    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/ext2fcheck?skin=bootstrap', 'token', 'code' );

    if ($correct_code) {
        $query =~ s/code=/code=123456/;
    }
    else {
        $query =~ s/code=/code=111111/;
    }

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

sub expectExtPrompt {
    my ( $res, $isRetry ) = @_;
    if ($isRetry) {
        like( $res->[2]->[0], qr,trmsg=\"110\",, "Retry prompt" );
    }
    else {
        like( $res->[2]->[0], qr,trspan=\"enterExt2fCode\",, "Initial prompt" );
    }
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

sub init_login {

    my ( $client, $uid ) = @_;
    my $res;
    ok(
        $res = $client->_get(
            '/', accept => 'text/html',
        ),
        "Auth query"
    );

    my ( $host, $url, $query ) = expectForm($res);

    $query =~ s/user=/user=$uid/;
    $query =~ s/password=/password=$uid/;

    ok(
        $res = $client->_post(
            '/', $query, accept => 'text/html',
        ),
        'Auth POST query'
    );

    return $res;
}

my $client = LLNG::Manager::Test->new( {
        ini => {
            ext2fActivation     => '1',
            mail2fActivation    => '$uid eq "rtyler"',
            loginHistoryEnabled => 1,
            ext2fAuthnLevel     => 5,
            ext2fCodeActivation => '123456',
            sfRetries           => 2,
            ext2FSendCommand    => '/bin/true',
            authentication      => 'Demo',
            userDB              => 'Same',
            customPlugins       => "t::sfHookPlugin",
        }
    }
);

# Try to authenticate
# -------------------

my ( $res, $code, $id );
subtest 'Only one factor offered, fail after 3 tries' => sub {

    clean_sessions();
    $res  = init_login( $client, 'dwho' );
    $code = expectExtPrompt($res);
    $res  = sendExt( $res, $client, 0 );
    $code = expectExtPrompt( $res, 1 );
    $res  = sendExt( $res, $client, 0 );
    $code = expectExtPrompt( $res, 1 );
    $res  = sendExt( $res, $client, 0 );
    expectPortalError( $res, 96 );

    my $hist = [ $client->getHistory('dwho') ];
    is( scalar @$hist, 1, "One entry in history" );
    cmp_ok( $hist->[0]->{error}, ">", 0, "Failure was recorded" );
};

subtest 'Only one factor offered, succeed after 2 tries' => sub {

    clean_sessions();
    $res  = init_login( $client, 'dwho' );
    $code = expectExtPrompt($res);
    $res  = sendExt( $res, $client, 0 );
    $code = expectExtPrompt( $res, 1 );
    $res  = sendExt( $res, $client, 0 );
    $code = expectExtPrompt( $res, 1 );
    $res  = sendExt( $res, $client, 1 );
    $id   = expectCookie($res);

    my $hist = [ $client->getHistory('dwho') ];
    is( scalar @$hist, 1, "One entry in history" );
    cmp_ok( $hist->[0]->{error}, "<=", 0, "Success was recorded" );
};

subtest 'Two factors offered, fail after 3 tries' => sub {

    clean_sessions();
    resetTimeOffset();

    # Login on first try
    $res  = init_login( $client, 'rtyler' );
    $res  = expect_2fa_choice( $client, $res, 'ext' );
    $code = expectExtPrompt($res);
    $res  = sendExt( $res, $client, 0 );
    $code = expectExtPrompt( $res, 1 );
    $res  = sendExt( $res, $client, 0 );
    $code = expectExtPrompt( $res, 1 );

    my $beforetime=time;
    timeOffsetIncrease(60);
    # $lastfailuretime=time does not work here, compute it.
    my $lastfailuretime=$beforetime+60;

    $res  = sendExt( $res, $client, 0 );

    expectPortalError( $res, 96 );

    my $hist = [ $client->getHistory('rtyler') ];
    is( scalar @$hist, 1, "One entry in history" );
    my $last_history_log = $hist->[0];
    cmp_ok( $last_history_log->{error}, ">", 0, "Failure was recorded" );
    cmp_ok( $last_history_log->{_utime}, ">=", $lastfailuretime, "history failed time match >" );

};

subtest 'Two factors offered, succeed after 2 tries' => sub {

    clean_sessions();
    resetTimeOffset();

    $res  = init_login( $client, 'rtyler' );
    $res  = expect_2fa_choice( $client, $res, 'ext' );
    $code = expectExtPrompt($res);
    $res  = sendExt( $res, $client, 0 );
    $code = expectExtPrompt( $res, 1 );
    $res  = sendExt( $res, $client, 0 );
    $code = expectExtPrompt( $res, 1 );

    my $beforetime=time;
    timeOffsetIncrease(60);
    # $lastsuccesstime=time does not work here, compute it.
    my $lastsuccesstime=$beforetime+60;
    cmp_ok( ($beforetime + 60), '<=' , ($lastsuccesstime), "internal fake time ok");

    $res  = sendExt( $res, $client, 1 );
    $id   = expectCookie($res);

    my $hist = [ $client->getHistory('rtyler') ];
    is( scalar @$hist, 1, "One entry in history" );
    my $last_history_log = $hist->[0];
    cmp_ok( $last_history_log->{error}, "<=", 0, "Success was recorded" );
    cmp_ok( $last_history_log->{_utime}, ">=", $lastsuccesstime , "history success time match >" );

};

subtest 'Test sfBeforeVerify hook' => sub {

    clean_sessions();
    $res  = init_login( $client, 'msmith' );
    $code = expectExtPrompt($res);
    $res  = sendExt( $res, $client, 0 );
    expectPortalError( $res, 999, "User msmith denied by hook" );
};

clean_sessions();

done_testing();

