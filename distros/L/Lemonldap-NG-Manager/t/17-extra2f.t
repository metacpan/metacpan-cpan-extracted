# Verify that bas changes are detected

use Test::More;
use strict;
use JSON;
require 't/test-lib.pm';

my $struct = 't/jsonfiles/17-extra2f.json';

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

ok( $res = &client->_get( '/confs/2/sfExtra', 'application/json' ),
    'Get combModules' );
ok( $resBody = from_json( $res->[2]->[0] ), "Result body contains JSON text" );

count(6);

done_testing( count() );

unlink 't/conf/lmConf-2.json';

`rm -rf t/sessions`;
