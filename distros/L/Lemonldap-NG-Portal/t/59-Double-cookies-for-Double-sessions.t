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
            securedCookie       => 2,
            https               => 0,
            singleSession       => 1,
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

$client->logout($id1);
clean_sessions();

done_testing( count() );
