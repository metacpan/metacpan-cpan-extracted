use Test::More;
use IO::String;
use strict;
use JSON qw(to_json from_json);

require 't/test-lib.pm';

my $res;
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                        => 'error',
            authentication                  => 'Demo',
            userDB                          => 'Same',
            loginHistoryEnabled             => 1,
            checkUser                       => 1,
            checkUserHiddenAttributes       => 'hGroups _session_id',
            checkUserDisplayPersistentInfo  => '$uid eq "dwho"',
            checkUserDisplayEmptyValues     => '$uid eq "dwho"',
            checkUserDisplayEmptyHeaders    => '$uid eq "dwho"',
            checkUserDisplayComputedSession => '$uid eq "dwho"',
            macros                          => {
                emptyMacro   => '',
                _whatToTrace => '$_user',
                authMode     => '$authenticationLevel == 1 ? "DEMO" : "NULL"'
            },
        }
    }
);

## Try to authenticate with 'dwho'
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html',
    ),
    'Auth query with "dwho"'
);
count(1);
my $id_dwho = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );
$client->logout($id_dwho);

## Try to authenticate with 'dwho'
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html',
    ),
    'Auth query with "dwho"'
);
count(1);
$id_dwho = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

## Try to authenticate with 'msmith'
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=msmith&password=msmith'),
        length => 27,
        accept => 'text/html',
    ),
    'Auth query with "msmith"'
);
count(1);
my $id_msmith = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

## CheckUser forms
## ------------------------

# Try checkUser with 'dwho'
ok(
    $res = $client->_get(
        '/checkuser',
        cookie => "lemonldap=$id_dwho",
        accept => 'text/html'
    ),
    'CheckUser form',
);
count(1);
my ( $host, $url, $query ) =
  expectForm( $res, undef, '/checkuser', 'user', 'url' );
ok( $res->[2]->[0] =~ m%<span trspan="checkUser">%, 'Found trspan="checkUser"' )
  or explain( $res->[2]->[0], 'trspan="checkUser"' );
count(1);

$query =~ s/url=/url=http%3A%2F%2Ftest1.example.com/;
ok(
    $res = $client->_post(
        '/checkuser',
        IO::String->new($query),
        cookie => "lemonldap=$id_dwho",
        length => length($query),
    ),
    'POST checkuser'
);
ok( $res = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $res->{MSG} eq 'checkUser', 'checkUser found' )
  or print STDERR Dumper($res);
my @persistentAttr =
  map { $_->{key} eq '_loginHistory' ? $_ : () } @{ $res->{ATTRIBUTES} };
ok( scalar @persistentAttr == 1, 'Persistent attribute found' )
  or print STDERR Dumper($res);
count(4);

$query =~ s/user=dwho/user=rtyler/;
ok(
    $res = $client->_post(
        '/checkuser',
        IO::String->new($query),
        cookie => "lemonldap=$id_dwho",
        length => length($query),
    ),
    'POST checkuser'
);
ok( $res = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $res->{MSG} eq 'checkUserComputedSession', 'Computed session' )
  or print STDERR Dumper($res);
ok( scalar @{ $res->{HEADERS} } == 4, 'Four headers found' )
  or print STDERR Dumper($res);
my @emptyValue =
  map { $_->{key} eq 'emptyHeader' ? $_ : () } @{ $res->{HEADERS} };
ok( scalar @emptyValue == 1, 'Empty header found' )
  or print STDERR Dumper($res);
@emptyValue = map { $_->{key} eq 'emptyMacro' ? $_ : () } @{ $res->{MACROS} };
ok( scalar @emptyValue == 1, 'Empty macro found' )
  or print STDERR Dumper($res);
count(6);

# Try checkUser with 'msmith'
ok(
    $res = $client->_get(
        '/checkuser',
        cookie => "lemonldap=$id_msmith",
        accept => 'text/html'
    ),
    'CheckUser form',
);
count(1);
( $host, $url, $query ) =
  expectForm( $res, undef, '/checkuser', 'user', 'url' );
ok( $res->[2]->[0] =~ m%<span trspan="checkUser">%, 'Found trspan="checkUser"' )
  or explain( $res->[2]->[0], 'trspan="checkUser"' );
count(1);

$query =~ s/user=msmith/user=rtyler/;
$query =~ s/url=/url=http%3A%2F%2Ftest1.example.com/;
ok(
    $res = $client->_post(
        '/checkuser',
        IO::String->new($query),
        cookie => "lemonldap=$id_msmith",
        length => length($query),
    ),
    'POST checkuser'
);
count(1);

ok( $res = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $res->{MSG} eq 'checkUserNoSessionFound', 'No session found' )
  or print STDERR Dumper($res);
count(2);

# Try checkUser with 'msmith'
$query =~ s/user=rtyler/user=dwho/;
ok(
    $res = $client->_post(
        '/checkuser',
        IO::String->new($query),
        cookie => "lemonldap=$id_msmith",
        length => length($query),
    ),
    'POST checkuser'
);
count(1);

ok( $res = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $res->{MSG} eq 'checkUser', 'checkUser found' )
  or print STDERR Dumper($res);
ok( scalar @{ $res->{HEADERS} } == 3, 'Three headers found' )
  or print STDERR Dumper($res);
@emptyValue = map { $_->{key} eq 'emptyHeader' ? $_ : () } @{ $res->{HEADERS} };
ok( scalar @emptyValue == 0, 'No empty header found' )
  or print STDERR Dumper($res);
@emptyValue = map { $_->{key} eq 'emptyMacro' ? $_ : () } @{ $res->{MACROS} };
ok( scalar @emptyValue == 0, 'No empty macro found' )
  or print STDERR Dumper($res);
@persistentAttr =
  map { $_->{key} eq '_loginHistory' ? $_ : () } @{ $res->{ATTRIBUTES} };
ok( scalar @persistentAttr == 0, 'No persistent attribute found' )
  or print STDERR Dumper($res);
count(6);

# Refresh rights (#2179)
# ------------------------
ok(
    $res = $client->_get(
        '/refresh',
        cookie => "lemonldap=$id_msmith",
        accept => 'text/html'
    ),
    'Refresh query',
);
expectRedirection( $res, 'http://auth.example.com/' );

Time::Fake->offset("+20s");    # Go through handler internal cache

ok(
    $res = $client->_get(
        '/checkuser', cookie => "lemonldap=$id_msmith",
    ),
    'GET checkuser'
);

my $data = eval { JSON::from_json( $res->[2]->[0] ) };
ok( not($@), ' Content is JSON' )
  or explain( [ $@, $res->[2] ], 'JSON content' );
my @authLevel =
  map { $_->{key} eq 'authenticationLevel' ? $_ : () } @{ $data->{ATTRIBUTES} };
ok( $authLevel[0]->{value} == 1, 'Good authenticationLevel found' )
  or explain( $authLevel[0]->{value}, 'authenticationLevel' );
my @authMode =
  map { $_->{key} eq 'authMode' ? $_ : () } @{ $data->{MACROS} };
ok( $authMode[0]->{value} eq 'DEMO', 'Good authMode found' )
  or explain( $authMode[0]->{value}, 'authMode' );
count(5);

$client->logout($id_dwho);
$client->logout($id_msmith);
clean_sessions();

done_testing( count() );

