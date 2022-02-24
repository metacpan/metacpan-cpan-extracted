use Test::More;
use strict;
use IO::String;
use JSON;

require 't/test-lib.pm';

my $res;
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                       => 'error',
            authentication                 => 'Demo',
            userDB                         => 'Same',
            loginHistoryEnabled            => 0,
            portalMainLogo                 => 'common/logos/logo_llng_old.png',
            requireToken                   => 0,
            checkUser                      => 1,
            securedCookie                  => 0,
            https                          => 0,
            checkUserDisplayPersistentInfo => 0,
            checkUserDisplayEmptyValues    => 0,
            contextSwitchingRule           => '$uid eq "dwho"',
            contextSwitchingIdRule         => '$uid ne "msmith"',
            impersonationRule              => '$uid ne "msmith"',
            impersonationIdRule            => '$uid ne "msmith"',
            contextSwitchingStopWithLogout => 0,
        }
    }
);

## Try to impersonate: rtyler -> dwho
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
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
count(2);
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
expectOK($res);
ok( $res->[2]->[0] =~ m%<span trspan="connectedAs">Connected as</span> dwho%,
    'Connected as dwho' )
  or print STDERR Dumper( $res->[2]->[0] );
expectAuthenticatedAs( $res, 'dwho' );
ok(
    $res->[2]->[0] =~
      m%<span trspan="contextSwitching_ON">contextSwitching_ON</span>%,
    'contextSwitching allowed'
) or print STDERR Dumper( $res->[2]->[0] );
count(3);

# ContextSwitching form: dwho -> rtyler
# ------------------------
ok(
    $res = $client->_get(
        '/switchcontext',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'ContextSwitching form: dwho -> rtyler',
);
( $host, $url, $query ) =
  expectForm( $res, undef, '/switchcontext', 'spoofId' );
ok( $res->[2]->[0] =~ m%<span trspan="contextSwitching_ON">%,
    'Found trspan="contextSwitching_ON"' )
  or explain( $res->[2]->[0], 'trspan="contextSwitching_ON"' );
$query =~ s/spoofId=/spoofId=rtyler/;
ok(
    $res = $client->_post(
        '/switchcontext',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
        accept => 'text/html',
    ),
    'POST switchcontext'
);
expectRedirection( $res, 'http://auth.example.com/' );

# Refresh cookie value
my $id2 = expectCookie($res);
ok( $id2 ne $id, 'New SSO session created' )
  or explain( $id2, 'New SSO session created' );
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id2",
        accept => 'text/html'
    ),
    'Get Menu',
);
expectAuthenticatedAs( $res, 'rtyler' );
ok( $res->[2]->[0] =~ m%<span trspan="contextSwitching_OFF">%,
    'Found trspan="contextSwitching_OFF"' )
  or explain( $res->[2]->[0], 'trspan="contextSwitching_OFF"' );
ok(
    $res = $client->_get(
        '/switchcontext',
        cookie => "lemonldap=$id2",
        accept => 'text/html'
    ),
    'Stop context switching rtyler',
);
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id2",
        accept => 'text/html'
    ),
    'Get Menu',
);
ok( $res->[2]->[0] =~ m%<span trmsg="1">%, 'Found PE_SESSIONEXPIRED' )
  or explain( $res->[2]->[0], 'Session expired' );
count(9);

# ContextSwitching form: dwho -> french
# ------------------------
ok(
    $res = $client->_get(
        '/switchcontext',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'ContextSwitching form: dwho -> french',
);
( $host, $url, $query ) =
  expectForm( $res, undef, '/switchcontext', 'spoofId' );
ok( $res->[2]->[0] =~ m%<span trspan="contextSwitching_ON">%,
    'Found trspan="contextSwitching_ON"' )
  or explain( $res->[2]->[0], 'trspan="contextSwitching_ON"' );
$query =~ s/spoofId=/spoofId=french/;
ok(
    $res = $client->_post(
        '/switchcontext',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
        accept => 'text/html',
    ),
    'POST switchcontext'
);
expectRedirection( $res, 'http://auth.example.com/' );

# Refresh cookie value
$id2 = expectCookie($res);
ok( $id2 ne $id, 'New SSO session created' )
  or explain( $id2, 'New SSO session created' );
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id2",
        accept => 'text/html'
    ),
    'Get Menu',
);
expectAuthenticatedAs( $res, 'french' );
ok( $res->[2]->[0] =~ m%<span trspan="contextSwitching_OFF">%,
    'Found trspan="contextSwitching_OFF"' )
  or explain( $res->[2]->[0], 'trspan="contextSwitching_OFF"' );
count(6);

# CheckUser request
ok(
    $res = $client->_get(
        '/checkuser', cookie => "lemonldap=$id2",
    ),
    'CheckUser form',
);
eval { $res = JSON::from_json( $res->[2]->[0] ) };
ok( not($@), 'Content is JSON' )
  or explain( $res->[2]->[0], 'JSON content' );
my @sessions_id =
  map { $_->{key} =~ /^switching_session_id$/ ? $_ : () }
  @{ $res->{ATTRIBUTES} };
ok( $sessions_id[0]->{value} eq $id, 'Good switching_id found' )
  or explain( $sessions_id[0]->{value}, 'switching_session_id' );
my @real_values =
  map { $_->{key} =~ /^real_/ ? $_ : () } @{ $res->{ATTRIBUTES} };
ok( scalar @real_values == 0, 'No real value found' )
  or explain( scalar(@real_values), 'Found real value' );
count(4);

ok(
    $res = $client->_get(
        '/switchcontext',
        cookie => "lemonldap=$id2",
        accept => 'text/html'
    ),
    'Stop context switching french',
);

# Refresh cookie value
$id = expectCookie($res);
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'Get Menu',
);
expectAuthenticatedAs( $res, 'dwho' );
ok( $res->[2]->[0] =~ m%<span trspan="contextSwitching_ON">%,
    'Found trspan="contextSwitching_ON"' )
  or explain( $res->[2]->[0], 'trspan="contextSwitching_ON"' );

# CheckUser request
ok(
    $res = $client->_get(
        '/checkuser', cookie => "lemonldap=$id",
    ),
    'CheckUser form',
);
eval { $res = JSON::from_json( $res->[2]->[0] ) };
ok( not($@), 'Content is JSON' )
  or explain( $res->[2]->[0], 'JSON content' );
@sessions_id =
  map { $_->{key} =~ /_session_id$/ ? $_ : () } @{ $res->{ATTRIBUTES} };
ok( $sessions_id[0]->{value} eq $id, 'Good switching_id found' )
  or explain( $sessions_id[0]->{value}, 'Switching_session_id' );
count(6);

# Log out request -> dwho
# ------------------------
ok(
    $res = $client->_get(
        '/',
        query  => 'logout=1',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'Get Menu',
);
expectOK($res);
ok( $res->[2]->[0] =~ m%<span trmsg="47">%, 'Dwho has been well disconnected' )
  or print STDERR Dumper( $res->[2]->[0] );
count(2);

clean_sessions();

done_testing( count() );
