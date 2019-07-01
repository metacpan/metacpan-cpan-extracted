use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel            => 'error',
            useSafeJail         => 1,
            'corsAllow_Origin'  => '',
            'corsAllow_Methods' => 'POST',
            'cspFormAction'     => '*'
        }
    }
);

# Test normal first access
# ------------------------
ok( $res = $client->_get('/'), 'Unauth JSON request' );
count(1);
expectReject($res);

# Test "first access" with good url
ok(
    $res =
      $client->_get( '/', query => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==' ),
    'Unauth ajax request with good url'
);
count(1);
expectReject($res);

ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu' );
ok( $res->[2]->[0] =~ m%<span id="languages"></span>%, ' Language icons found' )
  or print STDERR Dumper( $res->[2]->[0] );
count(2);

# CORS
ok( $res->[1]->[12] eq 'Access-Control-Allow-Origin', ' CORS origin found' )
  or print STDERR Dumper( $res->[1] );
ok( $res->[1]->[13] eq '', " CORS origin ''" )
  or print STDERR Dumper( $res->[1] );
ok( $res->[1]->[14] eq 'Access-Control-Allow-Credentials',
    ' CORS credentials found' )
  or print STDERR Dumper( $res->[1] );
ok( $res->[1]->[15] eq 'true', " CORS credentials 'true'" )
  or print STDERR Dumper( $res->[1] );
ok( $res->[1]->[16] eq 'Access-Control-Allow-Headers', " CORS headers found" )
  or print STDERR Dumper( $res->[1] );
ok( $res->[1]->[17] eq '*', " CORS headers '*'" )
  or print STDERR Dumper( $res->[1] );
ok( $res->[1]->[18] eq 'Access-Control-Allow-Methods', " CORS methods found" )
  or print STDERR Dumper( $res->[1] );
ok( $res->[1]->[19] eq 'POST', " CORS methods 'POST'" )
  or print STDERR Dumper( $res->[1] );
ok( $res->[1]->[20] eq 'Access-Control-Expose-Headers',
    " CORS expose-headers found" )
  or print STDERR Dumper( $res->[1] );
ok( $res->[1]->[21] eq '*', " CORS expose-headers '*'" )
  or print STDERR Dumper( $res->[1] );
ok( $res->[1]->[22] eq 'Access-Control-Max-Age', ' CORS max-age found' )
  or print STDERR Dumper( $res->[1] );
ok( $res->[1]->[23] == 86400, ' CORS max-age 86400' )
  or print STDERR Dumper( $res->[1] );
count(12);

#CSP
ok( $res->[1]->[26] eq 'Content-Security-Policy', ' CSP found' )
  or print STDERR Dumper( $res->[1] );
ok(
    $res->[1]->[27] =~
/default-src 'self';img-src 'self' data:;style-src 'self';font-src 'self';connect-src 'self';script-src 'self';form-action \*;frame-ancestors 'none'/,
    ' CSP headers found'
) or print STDERR Dumper( $res->[1] );
count(2);

# Try to authenticate with good password
# --------------------------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
    ),
    'Auth query'
);
count(1);
expectOK($res);
my $id = expectCookie($res);

# Try to get a redirection for an auth user with a valid url
# ----------------------------------------------------------
ok(
    $res = $client->_get(
        '/',
        query  => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'Auth ajax request with good url'
);
count(1);
expectRedirection( $res, 'http://test1.example.com/' );
expectAuthenticatedAs( $res, 'dwho' );

ok(
    $res = $client->_get(
        'http://test1.example.com/',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'Get test1'
);
count(1);

ok( $res->[1]->[14] eq 'Access-Control-Allow-Origin', ' CORS origin found' )
  or print STDERR Dumper( $res->[1] );
ok( $res->[1]->[15] eq '', " CORS origin ''" )
  or print STDERR Dumper( $res->[1] );
ok( $res->[1]->[16] eq 'Access-Control-Allow-Credentials',
    ' CORS credentials found' )
  or print STDERR Dumper( $res->[1] );
ok( $res->[1]->[17] eq 'true', " CORS credentials 'true'" )
  or print STDERR Dumper( $res->[1] );
ok( $res->[1]->[18] eq 'Access-Control-Allow-Headers', " CORS headers found" )
  or print STDERR Dumper( $res->[1] );
ok( $res->[1]->[19] eq '*', " CORS headers '*'" )
  or print STDERR Dumper( $res->[1] );
ok( $res->[1]->[20] eq 'Access-Control-Allow-Methods', " CORS methods found" )
  or print STDERR Dumper( $res->[1] );
ok( $res->[1]->[21] eq 'POST', " CORS methods 'POST'" )
  or print STDERR Dumper( $res->[1] );
ok( $res->[1]->[22] eq 'Access-Control-Expose-Headers',
    " CORS expose-headers found" )
  or print STDERR Dumper( $res->[1] );
ok( $res->[1]->[23] eq '*', " CORS expose-headers '*'" )
  or print STDERR Dumper( $res->[1] );
ok( $res->[1]->[24] eq 'Access-Control-Max-Age', ' CORS max-age found' )
  or print STDERR Dumper( $res->[1] );
ok( $res->[1]->[25] == 86400, ' CORS max-age 86400' )
  or print STDERR Dumper( $res->[1] );
count(12);

# Test logout
$client->logout($id);

#print STDERR Dumper($res);

clean_sessions();

done_testing( count() );
