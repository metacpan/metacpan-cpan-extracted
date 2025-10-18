# Verify that bad changes are detected

use warnings;
use Test::More;
use strict;
use JSON;
require 't/test-lib.pm';

my $struct = 't/jsonfiles/14-bad.json';

my ( $len, $body ) = substitute_io_handle($struct);

my ( $res, $resBody );
ok(
    $res =
      &client->_post( '/confs/', 'cfgNum=1', $body, 'application/json', $len ),
    "Request succeed"
);
ok( $res->[0] == 200,                       "Result code is 200" );
ok( $resBody = from_json( $res->[2]->[0] ), "Result body contains JSON text" );
ok( $resBody->{result} == 0, "JSON response contains \"result:0\"" )
  or print STDERR Dumper($res);
ok( (
        $resBody->{details}->{__errors__}
          and @{ $resBody->{details}->{__errors__} } == 1
    ),
    '1 error detected'
) or print STDERR Dumper($resBody);

count(5);

done_testing( count() );

unlink "$main::tmpdir/conf/lmConf-2.json";
