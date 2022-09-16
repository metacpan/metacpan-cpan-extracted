use Test::More;
use strict;
use IO::String;
use JSON;

BEGIN {
    require 't/test-lib.pm';
}

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                       => 'error',
            authentication                 => 'Demo',
            userDB                         => 'Same',
            loginHistoryEnabled            => 0,
            brutForceProtection            => 0,
            portalMainLogo                 => 'common/logos/logo_llng_old.png',
            requireToken                   => 0,
            checkUser                      => 1,
            impersonationRule              => 1,
            checkUserDisplayPersistentInfo => 0,
            checkUserDisplayEmptyValues    => 0,
            checkUserHiddenAttributes      => '',
            impersonationMergeSSOgroups    => 'su; _test_; su_test; sutest',
        }
    }
);

## Try to authenticate
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
count(1);
my ( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'spoofId' );

$query =~ s/user=/user=rtyler/;
$query =~ s/password=/password=rtyler/;
$query =~ s/spoofId=/spoofId=dwho/;
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Auth query'
);
count(1);

my $id = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

# Get Menu
# ------------------------
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'Get Menu',
);
count(1);
expectOK($res);
ok( $res->[2]->[0] =~ m%<span trspan="connectedAs">Connected as</span> dwho%,
    'Connected as dwho' )
  or print STDERR Dumper( $res->[2]->[0] );
expectAuthenticatedAs( $res, 'dwho' );
count(1);

# CheckUser form
# ------------------------
ok(
    $res = $client->_get(
        '/checkuser',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'CheckUser form',
);
count(1);
( $host, $url, $query ) =
  expectForm( $res, undef, '/checkuser', 'user', 'url' );
ok( $res->[2]->[0] =~ m%<span trspan="checkUserMerged">%,
    'Found trspan="checkUserMerged"' )
  or explain( $res->[2]->[0], 'trspan="checkUserMerged"' );
count(1);

$query =~ s/url=/url=test1.example.com/;

ok(
    $res = $client->_post(
        '/checkuser',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
        accept => 'text/html',
    ),
    'POST checkuser'
);
count(1);

( $host, $url, $query ) =
  expectForm( $res, undef, '/checkuser', 'user', 'url' );
ok( $res->[2]->[0] =~ m%<span trspan="checkUserMerged">%,
    'Found trspan="checkUser"' )
  or explain( $res->[2]->[0], 'trspan="checkUserMerged"' );
ok(
    $res->[2]->[0] =~
m%<div class="alert alert-success"><div class="text-center"><b><span trspan="allowed"></span></b></div></div>%,
    'Found trspan="allowed"'
) or explain( $res->[2]->[0], 'trspan="allowed"' );
ok( $res->[2]->[0] =~ m%<span trspan="headers">%, 'Found trspan="headers"' )
  or explain( $res->[2]->[0], 'trspan="headers"' );
ok( $res->[2]->[0] =~ m%<span trspan="groups_sso">%,
    'Found trspan="groups_sso"' )
  or explain( $res->[2]->[0], 'trspan="groups_sso"' );
ok( $res->[2]->[0] =~ m%<span trspan="macros">%, 'Found trspan="macros"' )
  or explain( $res->[2]->[0], 'trspan="macros"' );
ok( $res->[2]->[0] =~ m%<span trspan="attributes">%,
    'Found trspan="attributes"' )
  or explain( $res->[2]->[0], 'trspan="attributes"' );
ok( $res->[2]->[0] =~ m%<td scope="row">_userDB</td>%, 'Found _userDB' )
  or explain( $res->[2]->[0], '_userDB' );
ok( $res->[2]->[0] =~ m%Auth-User: %, 'Found Auth-User' )
  or explain( $res->[2]->[0], 'Header Key: Auth-User' );
ok( $res->[2]->[0] =~ m%: dwho<br/>%, 'Found dwho' )
  or explain( $res->[2]->[0], 'Header Value: dwho' );
ok( $res->[2]->[0] =~ m%<div class="card-text text-left ml-2">su</div>%,
    'Found su' )
  or explain( $res->[2]->[0], 'SSO Groups: su' );
ok( $res->[2]->[0] =~ m%<div class="card-text text-left ml-2">su_test</div>%,
    'Found su_test' )
  or explain( $res->[2]->[0], 'SSO Groups: su_test' );
ok( $res->[2]->[0] !~ m%<div class="card-text text-left ml-2">_test_</div>%,
    'NOT found _test_' )
  or explain( $res->[2]->[0], 'SSO Groups: _test_' );
ok( $res->[2]->[0] !~ m%<div class="card-text text-left ml-2">test_su</td>%,
    'NOT found test_su' )
  or explain( $res->[2]->[0], 'SSO Groups: test_su' );
ok( $res->[2]->[0] =~ m%<td scope="row">uid</td>%, 'Found uid' )
  or explain( $res->[2]->[0], 'Attribute Value uid' );
ok( $res->[2]->[0] =~ m%<td scope="row">_whatToTrace</td>%,
    'Found _whatToTrace' )
  or explain( $res->[2]->[0], 'Macro Key _whatToTrace' );
count(15);

ok(
    $res = $client->_post(
        '/checkuser',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
    ),
    'POST checkuser'
);
count(1);

my $json;
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
my @real_hGroups =
  map { $_->{key} eq 'real_hGroups' ? $_ : () } @{ $json->{ATTRIBUTES} };
ok(
    keys %{ $real_hGroups[0]->{value} } == 5,
    'Right number of real_hGroups found'
) or explain( $real_hGroups[0]->{value}, 'Wrong real_hGroups' );
count(2);

my @hGroups = map { $_->{key} eq 'hGroups' ? $_ : () } @{ $json->{ATTRIBUTES} };
ok( keys %{ $hGroups[0]->{value} } == 4, 'Right number of hGroups found' )
  or explain( $hGroups[0]->{value}, 'Wrong hGroups' );
count(1);

$client->logout($id);
clean_sessions();

done_testing( count() );
