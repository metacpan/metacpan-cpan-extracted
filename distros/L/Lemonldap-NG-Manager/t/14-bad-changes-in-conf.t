#!/usr/bin/env perl -I pl/lib
#
# Verify that bas changes are detected

use Test::More;
use strict;
use JSON;
use Data::Dumper;
require 't/test-lib.pm';

my $struct = 't/jsonfiles/14-bad.json';

sub body {
    return IO::File->new( $struct, 'r' );
}

unlink 't/conf/lmConf-2.js';

my ( $res, $resBody );
ok( $res = &client->_post( '/confs/', 'cfgNum=1', &body, 'application/json' ),
    "Request succeed" );
ok( $res->[0] == 200, "Result code is 200" );
ok( $resBody = from_json( $res->[2]->[0] ), "Result body contains JSON text" );
ok( $resBody->{result} == 0, "JSON response contains \"result:0\"" )
  or print STDERR Dumper($res);
ok( @{ $resBody->{details}->{__warnings__} } == 1, '1 error detected' )
  or print STDERR Dumper($resBody);

count(5);

done_testing( count() );

unlink 't/conf/lmConf-2.js';
