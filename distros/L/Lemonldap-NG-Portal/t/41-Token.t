use Test::More;
use strict;
use IO::String;
use JSON;
use Lemonldap::NG::Portal::Main::Constants 'PE_NOTOKEN';

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel     => 'error',
            useSafeJail  => 1,
            requireToken => '"Bad rule"',
        }
    }
);

# Test normal first access
# ------------------------
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Unauth request' );
count(1);

my ( $host, $url, $query ) = expectForm( $res, '#', undef, 'token' );
ok( $res->[2]->[0] =~ m%<input[^>]*name="password"%,
    'Password: Found password input' );
count(1);

$query =~ s/.*\b(token=[^&]+).*/$1/;

# Try to auth without token
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23
    ),
    'Try to auth without token'
);
count(1);
expectReject($res);

my $json;
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{error} == PE_NOTOKEN, 'Response is PE_NOTOKEN' )
  or explain( $json, "error => 81" );
count(2);

# Try to auth with token
$query .= '&user=dwho&password=dwho';
ok(
    $res =
      $client->_post( '/', IO::String->new($query), length => length($query) ),
    'Try to auth with token'
);
count(1);
expectOK($res);
my $id = expectCookie($res);

# Verify auth
ok( $res = $client->_get( '/', cookie => "lemonldap=$id" ), 'Verify auth' );
count(1);
expectOK($res);

# Try to reuse the same token
ok(
    $res =
      $client->_post( '/', IO::String->new($query), length => length($query) ),
    'Try to reuse the same token'
);
expectReject($res);
ok(
    $res = $client->_post(
        '/', IO::String->new($query),
        length => length($query),
        accept => 'text/html'
    ),
    'Verify that there is a new token'
);
expectForm( $res, '#', undef, 'token' );
count(2);

clean_sessions();

done_testing( count() );
