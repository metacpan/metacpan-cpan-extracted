use Test::More;
use strict;
use IO::String;

BEGIN {
    require 't/test-lib.pm';
}

my $res;
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel            => 'error',
            authentication      => 'Demo',
            userDB              => 'Same',
            loginHistoryEnabled => 0,
            brutForceProtection => 0,
            portalMainLogo      => 'common/logos/logo_llng_old.png',
            requireToken        => 0,
            securedCookie       => 1,
            https               => 0,
            whatToTrace         => 'mail'
        }
    }
);

## Try to authenticate
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
count(1);
my ( $host, $url, $query ) = expectForm( $res, '#', undef, 'user', 'password' );
$query =~ s/user=/user=dwho/;
$query =~ s/password=/password=dwho/;
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

# Check lemonldap Cookie
ok( $id =~ /^\w{64}$/, " -> Get cookie : lemonldap=something" )
  or explain( $res->[1], "Set-Cookie: lemonldap=$id" );
ok( ${ $res->[1] }[3] =~ /HttpOnly=1/, " -> Cookie 'lemonldap' is HttpOnly" )
  or explain( $res->[1] );
ok( ${ $res->[1] }[3] =~ /secure/, " -> Cookie 'lemonldap' is secure" )
  or explain( $res->[1] );
count(3);

my $nbr = count_sessions();
ok( $nbr == 1, " -> HTTPS Cookie for one session found" )
  or explain("Number of session(s) found = $nbr");
count(1);
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
    'Connected as Dwho' )
  or print STDERR Dumper( $res->[2]->[0] );
count(1);

# Refresh rights
# ------------------------
ok(
    $res = $client->_get(
        '/refresh',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'Refresh query',
);
count(1);
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
    'Connected as Dwho' )
  or print STDERR Dumper( $res->[2]->[0] );
count(1);

# Log out request
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
count(1);
expectOK($res);

ok( $res->[2]->[0] =~ m%<span trmsg="47">%, 'Dwho has been well disconnected' )
  or print STDERR Dumper( $res->[2]->[0] );
count(1);

clean_sessions();

done_testing( count() );
