use Test::More;
use strict;
use IO::String;

BEGIN {
    require 't/test-lib.pm';
}

my $res;
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                  => 'error',
            authentication            => 'Demo',
            userDB                    => 'Same',
            loginHistoryEnabled       => 0,
            brutForceProtection       => 0,
            portalMainLogo            => 'common/logos/logo_llng_old.png',
            requireToken              => 0,
            securedCookie             => 2,
            https                     => 0,
            checkUser                 => 1,
            handlerInternalCache      => 0,
            checkUserHiddenAttributes => '_loginHistory hGroups',
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

my $id1 = expectCookie($res);
my $id2 = expectCookie( $res, 'lemonldaphttp' );

# Check lemonldap Cookie
ok( $id1 =~ /^\w{64}$/, " -> Get cookie : lemonldap=something" )
  or explain( $res->[1], "Set-Cookie: lemonldap=$id1" );
ok( ${ $res->[1] }[3] =~ /HttpOnly=1/, " -> Cookie 'lemonldap' is HttpOnly" )
  or explain( $res->[1] );
ok( ${ $res->[1] }[3] =~ /secure/, " -> Cookie 'lemonldap' is secure" )
  or explain( $res->[1] );
count(3);

# Check lemonldaphttp Cookie
ok( $id2 =~ /^\w{64}$/, " -> Get cookie lemonldaphttp=something" )
  or explain( $res->[1], "Set-Cookie: lemonldaphttp=$id2" );
ok(
    ${ $res->[1] }[5] =~ /HttpOnly=1/,
    " -> Cookie 'lemonldaphttp' is HttpOnly"
) or explain( $res->[1] );
ok( ${ $res->[1] }[5] !~ /secure/, " -> Cookie 'lemonldaphttp' is NOT secure" )
  or explain( $res->[1] );
count(3);

my $nbr = count_sessions();
ok( $nbr == 2, " -> Doule Cookies for two sessions found" )
  or explain("Number of session(s) found = $nbr");
count(1);
expectRedirection( $res, 'http://auth.example.com/' );

# Get Menu
# ------------------------
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id1,lemonldaphttp=$id2",
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

# CheckUser form
# ------------------------
ok(
    $res = $client->_get(
        '/checkuser',
        cookie => "lemonldap=$id1,lemonldaphttp=$id2",
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

ok(
    $res = $client->_post(
        '/checkuser',
        IO::String->new($query),
        cookie => "lemonldap=$id1,lemonldaphttp=$id2",
        length => length($query),
        accept => 'text/html',
    ),
    'POST checkuser'
);
my %attributes = map /<td scope="row">(.+)?<\/td>/g, $res->[2]->[0];
ok( scalar keys %attributes == 19, 'Found 19 attributes' )
  or print STDERR "Wrong number of attributes -> " . scalar keys %attributes;
ok( $attributes{'_updateTime'} =~ /^\d{14}$/, 'Timestamp found' )
  or print STDERR Dumper( \%attributes );
count(3);

# Waiting
Time::Fake->offset("+3s");

# Refresh rights
# ------------------------
ok(
    $res = $client->_get(
        '/refresh',
        cookie => "lemonldap=$id1,lemonldaphttp=$id2",
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
        cookie => "lemonldap=$id1,lemonldaphttp=$id2",
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

# CheckUser form
# ------------------------
ok(
    $res = $client->_get(
        '/checkuser',
        cookie => "lemonldap=$id1,lemonldaphttp=$id2",
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

ok(
    $res = $client->_post(
        '/checkuser',
        IO::String->new($query),
        cookie => "lemonldap=$id1,lemonldaphttp=$id2",
        length => length($query),
        accept => 'text/html',
    ),
    'POST checkuser'
);
my %attributes2 = map /<td scope="row">(.+)?<\/td>/g, $res->[2]->[0];
ok( scalar keys %attributes2 == 19, 'Found 19 attributes' )
  or print STDERR "Wrong nunber of attributes -> " . scalar keys %attributes2;
ok( $attributes2{'_updateTime'} =~ /^\d{14}$/, 'Timestamp found' )
  or print STDERR Dumper( \%attributes2 );
count(3);

ok( $attributes2{_updateTime} - $attributes{_updateTime} >= 3,
    '_updateTime has been updated' )
  or print STDERR Dumper( \%attributes2 );
count(1);

# Log out request
# ------------------------
ok(
    $res = $client->_get(
        '/',
        query  => 'logout=1',
        cookie => "lemonldap=$id1,lemonldaphttp=$id2",
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
