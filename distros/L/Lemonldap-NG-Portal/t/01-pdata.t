use Test::More;
use strict;
use IO::String;
use URI::Escape;

require 't/test-lib.pm';

my $res;
my $tmp;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel      => 'error',
            customPlugins => 't::pdata',
        }
    }
);

# Two simple access to see if pdata is set and restored
ok( $res = $client->_get( '/', ), 'Simple access' );
$tmp = expectCookie( $res, 'lemonldappdata' );
ok( $tmp eq uri_escape('{"mytest":1}'), 'Pdata is {"mytest":1}' )
  or explain( $tmp, uri_escape('{"mytest":1}') );
count(2);

ok( $res = $client->_get( '/', cookie => 'lemonldappdata=' . $tmp, ),
    'Second simple access' );
$tmp = expectCookie( $res, 'lemonldappdata' );
ok( $tmp eq uri_escape('{"mytest":2}'), 'Pdata is {"mytest":2}' )
  or explain( $tmp, uri_escape('{"mytest":2}') );
count(2);

# Try to authenticate
# -------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        cookie => 'lemonldappdata={"mytest":1}',
        length => 23
    ),
    'Auth query'
);
count(1);
expectOK($res);

$tmp = expectCookie( $res, 'lemonldappdata' );
ok( $tmp eq '', 'Pdata is ""' ) or explain( $res, 'lemonldappdata=;' );
count(1);

clean_sessions();

done_testing( count() );
