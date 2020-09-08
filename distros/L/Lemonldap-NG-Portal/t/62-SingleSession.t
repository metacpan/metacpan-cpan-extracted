use Test::More;
use strict;
use IO::String;
use MIME::Base64;

BEGIN {
    require 't/test-lib.pm';
}

my $level = 'error';
my $res;
my $client1 = LLNG::Manager::Test->new( {
        ini => {
            logLevel       => $level,
            authentication => 'Demo',
            userDB         => 'Same',
            singleSession  => 1,
        }
    }
);
my $client2 = LLNG::Manager::Test->new( {
        ini => {
            logLevel       => $level,
            authentication => 'Demo',
            userDB         => 'Same',
            singleIP       => 1,
        }
    }
);
my $client3 = LLNG::Manager::Test->new( {
        ini => {
            logLevel       => $level,
            authentication => 'Demo',
            userDB         => 'Same',
            singleUserByIP => 1,
        }
    }
);
my $client4 = LLNG::Manager::Test->new( {
        ini => {
            logLevel       => $level,
            authentication => 'Demo',
            userDB         => 'Same',
            notifyOther    => 1,
            notifyDeleted  => 1,
            singleIP       => 1,
        }
    }
);

my $client5 = LLNG::Manager::Test->new( {
        ini => {
            logLevel       => $level,
            authentication => 'Demo',
            userDB         => 'Same',
        }
    }
);

sub loginUser {
    my ( $client, $user, $ip, %args ) = @_;
    my $query = "user=$user&password=$user";
    ok(
        my $res = $client->_post(
            '/',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
            ip     => $ip,
            %args
        ),
        'Auth query'
    );
    count(1);
    return $res;
}

sub testReq {
    my ( $client, $id, $msg ) = @_;
    my $res;
    ok( $res = $client->_get( '/', cookie => "lemonldap=$id" ), $msg );
    count(1);
    return $res;
}

# Issue #2081
sub testGetParam {
    my ( $res, $expected ) = @_;
    if ($expected) {
        ok(
            $res->[2]->[0] =~
              m%<input type="hidden" name="skin" value="bootstrap" />%,
            '"skin=bootstrap" input found'
        ) or explain( $res->[2]->[0], '"skin=bootstrap" not found' );
    }
    else {
        ok(
            $res->[2]->[0] =
              !m%<input type="hidden" name="skin" value="bootstrap" />%,
            '"skin=bootstrap" input not found'
        ) or explain( $res->[2]->[0], '"skin=bootstrap" found' );
    }
    count(1);
}

####################
# Test singleSession
switch ($client1);

# Test login
$res = loginUser( $client1, "dwho", "127.0.0.1" );
my $id1 = expectCookie($res);
testGetParam( $res, 0 );

$res = loginUser( $client1, "dwho", "127.0.0.1" );
my $id2 = expectCookie($res);
testGetParam( $res, 1 );

# Check that skin=bootstrap isn't appended when going to external URL (#2081)
$res = loginUser( $client1, "dwho", "127.0.0.1",
    query => 'url=' . encode_base64( "http://test1.example.com/", '' ) );
my $id3 = expectCookie($res);
testGetParam( $res, 0 );

expectOK( testReq( $client1, $id3, 'Attempt login with latest session' ) );
expectReject( testReq( $client1, $id2, 'Attempt login with removed session' ) );
expectReject( testReq( $client1, $id1, 'Attempt login with removed session' ) );

clean_sessions();

####################
# Test singleIP
switch ($client2);

$res = loginUser( $client2, "dwho", "127.0.0.1" );
$id1 = expectCookie($res);

$res = loginUser( $client2, "dwho", "127.0.0.1" );
$id2 = expectCookie($res);

$res = loginUser( $client2, "dwho", "127.0.0.2" );
$id3 = expectCookie($res);

$res = loginUser( $client2, "dwho", "127.0.0.2" );
my $id4 = expectCookie($res);

expectOK( testReq( $client2, $id3, 'First session on latest IP' ) );
expectOK( testReq( $client2, $id4, 'Latest session on latest IP' ) );
expectReject( testReq( $client2, $id1, 'session on old IP' ) );
expectReject( testReq( $client2, $id2, 'session on old IP' ) );

clean_sessions();

####################
# Test singleUserByIP
switch ($client3);

$res = loginUser( $client3, "rtyler", "127.0.0.1" );
$id1 = expectCookie($res);

$res = loginUser( $client3, "rtyler", "127.0.0.2" );
$id2 = expectCookie($res);

$res = loginUser( $client3, "dwho", "127.0.0.2" );
$id3 = expectCookie($res);

$res = loginUser( $client3, "dwho", "127.0.0.2" );
$id4 = expectCookie($res);

expectOK( testReq( $client3, $id1, 'Other user, but other IP' ) );
expectReject( testReq( $client3, $id2, 'Other user, same IP' ) );
expectOK( testReq( $client3, $id3, 'Same user, same IP' ) );
expectOK( testReq( $client3, $id4, 'Same user, same IP' ) );

clean_sessions();

####################
# Test DisplayDeleted & DisplayOther
switch ($client5);

$res = loginUser( $client5, "dwho", "127.0.0.1" );
$id1 = expectCookie($res);

$res = loginUser( $client5, "dwho", "127.0.0.1" );
$id2 = expectCookie($res);

$res = loginUser( $client5, "dwho", "127.0.0.2" );
$id3 = expectCookie($res);

switch ($client4);

$res = loginUser( $client4, "dwho", "127.0.0.2",
    query => 'url=' . encode_base64( "http://test1.example.com/", '' ) );
$id4 = expectCookie($res);

ok( $res->[2]->[0] =~ m%<h3 trspan="sessionsDeleted"></h3>%,
    'sessionsDeleted found' )
  or explain( $res->[2]->[0], 'sessionsDeleted found' );
ok( $res->[2]->[0] =~ m%<h3 trspan="otherSessions"></h3>%,
    'otherSessions found' )
  or explain( $res->[2]->[0], 'otherSessions found' );
ok(
    $res->[2]->[0] =~
m%<a href="http://auth.example.com/removeOther\?token=\w+?" onclick="_go=0" trspan="removeOtherSessions"></a>%,
    'Link found'
) or explain( $res->[2]->[0], 'Link found' );
ok( $res->[2]->[0] =~ m%action="http://test1.example.com/"%, 'action found' )
  or explain( $res->[2]->[0], 'action found' );
count(4);

clean_sessions();

done_testing( count() );
