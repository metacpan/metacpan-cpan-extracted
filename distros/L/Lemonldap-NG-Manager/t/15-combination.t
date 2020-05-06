# Verify that bas changes are detected

use Test::More;
use strict;
use JSON;
require 't/test-lib.pm';

my $struct = 't/jsonfiles/15-combination.json';

sub body {
    return IO::File->new( $struct, 'r' );
}

unlink 't/conf/lmConf-2.json';
mkdir 't/sessions';

my ( $res, $resBody );
ok( $res = &client->_post( '/confs/', 'cfgNum=1', &body, 'application/json' ),
    "Request succeed" );
ok( $res->[0] == 200,                       "Result code is 200" );
ok( $resBody = from_json( $res->[2]->[0] ), "Result body contains JSON text" );
ok( $resBody->{result} == 1, "JSON response contains \"result:1\"" )
  or print STDERR Dumper($res);

ok( $res = &client->_get( '/confs/2/combModules', 'application/json' ),
    'Get combModules' );
ok( $resBody = from_json( $res->[2]->[0] ), "Result body contains JSON text" );

ok( $res = &client->_get( '/confs/2/ldapServer', 'application/json' ),
    'Get combModules' );
ok( $resBody = from_json( $res->[2]->[0] ), "Result body contains JSON text" );
ok(
    $resBody->{value} eq 'ldap://192.168.1.1',
    'Key ldapServer has been modified'
);

count(9);

done_testing( count() );

unlink 't/conf/lmConf-2.json';

`rm -rf t/sessions`;
