# Verify that bas changes are detected

use warnings;
use Test::More;
use strict;
use JSON;
require 't/test-lib.pm';

my $struct = 't/jsonfiles/17-extra2f.json';

my ( $len, $body ) = substitute_io_handle($struct);
my ( $res, $resBody );
ok(
    $res =
      &client->_post( '/confs/', 'cfgNum=1', $body, 'application/json', $len ),
    "Request succeed"
);
ok( $res->[0] == 200,                       "Result code is 200" );
ok( $resBody = from_json( $res->[2]->[0] ), "Result body contains JSON text" );
ok( $resBody->{result} == 1, "JSON response contains \"result:1\"" )
  or print STDERR Dumper($res);

ok( $res = &client->_get( '/confs/2/sfExtra', 'application/json' ),
    'Get combModules' );
ok( $resBody = from_json( $res->[2]->[0] ), "Result body contains JSON text" );

count(6);

done_testing( count() );
