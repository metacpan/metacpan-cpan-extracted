use Test::More;
use strict;
use IO::String;

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
            checkUser                      => 0,
            securedCookie                  => 0,
            https                          => 0,
            checkUserDisplayPersistentInfo => 0,
            checkUserDisplayEmptyValues    => 0,
            contextSwitchingRule           => '$uid eq "dwho"',
            contextSwitchingIdRule         => '$uid ne "msmith"',
            contextSwitchingStopWithLogout => 0,
        }
    }
);

##
## Try to authenticate with a user not authorized to switch context
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=rtyler&password=rtyler'),
        length => 27,
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
ok(
    $res->[2]->[0] =~ m%<span trspan="connectedAs">Connected as</span> rtyler%,
    'Connected as rtyler'
) or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ qr%<span id="languages"></span>%, 'Found language flags' )
  or print STDERR Dumper( $res->[2]->[0] );
expectAuthenticatedAs( $res, 'rtyler' );
ok( $res->[2]->[0] !~ m%contextSwitching_ON%, 'Connected as dwho' )
  or print STDERR Dumper( $res->[2]->[0] );
ok(
    $res->[2]->[0] =~
      qr%href="http://test1\.example\.com/" title="Application Test 1"%,
    'Found test1 & title'
) or print STDERR Dumper( $res->[2]->[0] );
ok(
    $res->[2]->[0] =~
      qr%href="http://test2\.example\.com/" title="A nice application!"%,
    'Found test2 & title'
) or print STDERR Dumper( $res->[2]->[0] );

my @appdesc = ( $res->[2]->[0] =~ qr%class="appdesc% );
ok( @appdesc == 1, 'Found only one description' )
  or print STDERR Dumper( $res->[2]->[0] );
count(6);

$client->logout($id);

##
## Try to authenticate with a user authorized to switch context
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html',
    ),
    'Auth query'
);
count(1);
$id = expectCookie($res);
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
ok(
    $res->[2]->[0] =~
      m%<span trspan="contextSwitching_ON">contextSwitching_ON</span>%,
    'contextSwitching allowed'
) or print STDERR Dumper( $res->[2]->[0] );
count(2);

# ContextSwitching form -> PE_MALFORMEDUSER
# ------------------------
ok(
    $res = $client->_get(
        '/switchcontext',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'ContextSwitching form',
);
count(1);

my ( $host, $url, $query ) =
  expectForm( $res, undef, '/switchcontext', 'spoofId' );
ok( $res->[2]->[0] =~ m%<span trspan="contextSwitching_ON">%,
    'Found trspan="contextSwitching_ON"' )
  or explain( $res->[2]->[0], 'trspan="contextSwitching_ON"' );
count(1);
$query =~ s/spoofId=/spoofId=msmith/;
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
ok( $res->[2]->[0] =~ m%<span trmsg="40">%, 'PE_MALFORMEDUSER' )
  or explain( $res->[2]->[0], 'PE_MALFORMEDUSER' );
count(2);

# ContextSwitching form -> PE_MALFORMEDUSER
# ------------------------
ok(
    $res = $client->_get(
        '/switchcontext',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'ContextSwitching form',
);
count(1);

( $host, $url, $query ) =
  expectForm( $res, undef, '/switchcontext', 'spoofId' );
ok( $res->[2]->[0] =~ m%<span trspan="contextSwitching_ON">%,
    'Found trspan="contextSwitching_ON"' )
  or explain( $res->[2]->[0], 'trspan="contextSwitching_ON"' );
count(1);
$query =~ s/spoofId=/spoofId=</;
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
ok( $res->[2]->[0] =~ m%<span trmsg="40">%, 'PE_MALFORMEDUSER' )
  or explain( $res->[2]->[0], 'PE_MALFORMEDUSER' );
count(2);

# ContextSwitching form -> PE_MALFORMEDUSER
# ------------------------
ok(
    $res = $client->_get(
        '/switchcontext',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'ContextSwitching form',
);
count(1);

( $host, $url, $query ) =
  expectForm( $res, undef, '/switchcontext', 'spoofId' );
ok( $res->[2]->[0] =~ m%<span trspan="contextSwitching_ON">%,
    'Found trspan="contextSwitching_ON"' )
  or explain( $res->[2]->[0], 'trspan="contextSwitching_ON"' );
count(1);
$query =~ s/spoofId=/spoofId=darkVador/;
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
ok( $res->[2]->[0] =~ m%<span trmsg="40">%, 'PE_MALFORMEDUSER' )
  or explain( $res->[2]->[0], 'PE_MALFORMEDUSER' );
count(2);

# ContextSwitching form -> No impersonation required
# ------------------------
ok(
    $res = $client->_get(
        '/switchcontext',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'ContextSwitching form',
);
count(1);

( $host, $url, $query ) =
  expectForm( $res, undef, '/switchcontext', 'spoofId' );
ok( $res->[2]->[0] =~ m%<span trspan="contextSwitching_ON">%,
    'Found trspan="contextSwitching_ON"' )
  or explain( $res->[2]->[0], 'trspan="contextSwitching_ON"' );
$query =~ s/spoofId=/spoofId=dwho/;
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
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'Get Menu',
);
ok( $res->[2]->[0] =~ m%<span trspan="contextSwitching_ON">%,
    'Found trspan="contextSwitching_ON"' )
  or explain( $res->[2]->[0], 'trspan="contextSwitching_ON"' );
count(4);
expectAuthenticatedAs( $res, 'dwho' );

# ContextSwitching form -> PE_OK
# ------------------------
ok(
    $res = $client->_get(
        '/switchcontext',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'ContextSwitching form',
);
count(1);

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

# Get cookie value
my $id1 = expectCookie($res);
ok( $id1 ne $id, 'New SSO session created' )
  or explain( $id1, 'New SSO session created' );
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id1",
        accept => 'text/html'
    ),
    'Get Menu',
);
count(3);
expectAuthenticatedAs( $res, 'rtyler' );
ok( $res->[2]->[0] =~ m%<span trspan="contextSwitching_OFF">%,
    'Found trspan="contextSwitching_OFF"' )
  or explain( $res->[2]->[0], 'trspan="contextSwitching_OFF"' );
ok(
    $res = $client->_get(
        '/switchcontext',
        cookie => "lemonldap=$id1",
        accept => 'text/html'
    ),
    'Stop context switching',
);
count(2);

# Get cookie value
my $id0 = expectCookie($res);
ok( $id0 eq $id, 'New SSO session created' )
  or explain( $id0, 'New SSO session created' );
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
count(4);

# ContextSwitching form -> PE_OK
# ------------------------
ok(
    $res = $client->_get(
        '/switchcontext',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'ContextSwitching form',
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
count(3);

# Refresh cookie value
my $id2 = expectCookie($res);
ok( $id2 ne $id, 'New SSO session created' )
  or explain( $id2, 'New SSO session created' );

$client->logout($id);

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
    'Stop context switching',
);
count(4);

ok( $res->[2]->[0] =~ m%<span trmsg="1">%, 'Found PE_SESSIONEXPIRED' )
  or explain( $res->[2]->[0], 'Session expired' );
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id2",
        accept => 'text/html'
    ),
    'Get Menu',
);
expectAuthenticatedAs( $res, 'rtyler' );
count(2);

# Log out request
# ------------------------
ok(
    $res = $client->_get(
        '/',
        query  => 'logout=1',
        cookie => "lemonldap=$id2",
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
