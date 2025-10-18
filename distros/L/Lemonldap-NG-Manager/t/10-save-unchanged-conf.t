# Verify that an unmodified configuration is rejected

use warnings;
use Data::Dumper;
use Test::More;
use strict;
use JSON;
require 't/test-lib.pm';

my @struct =
  qw[t/jsonfiles/01-base-tree.json t/jsonfiles/02-base-tree-all-nodes-opened.json];
my @desc = ( 'Unopened conf', 'Unchanged conf with all nodes opened' );
my $confFiles =
  [ "$main::tmpdir/conf/lmConf-1.json", "$main::tmpdir/conf/lmConf-2.json" ];

# Try to save an unmodified conf
for my $filename (@struct) {
    my ( $len, $body ) = substitute_io_handle($filename);
    my $desc = shift @desc;
    my ( $res, $resBody );
    ok(
        $res = &client->_post(
            '/confs/', 'cfgNum=1', $body, 'application/json', $len
        ),
        "$desc: positive result"
    );
    ok( $res->[0] == 200, "$desc: result code is 200" )
      or print STDERR Dumper($res);
    ok(
        $resBody = from_json( $res->[2]->[0] ),
        "$desc: result body contains JSON text"
    );

    #print STDERR Dumper($resBody);
    ok( $resBody->{result} == 0, "$desc: JSON response contains \"result:0\"" );
    ok( $resBody->{message} eq '__confNotChanged__',
        "$desc: conf was not changed" )
      or print STDERR Dumper($resBody);
    ok( !-e $confFiles->[1], "$desc: file isn't created" );

    #print STDERR Dumper($resBody);
    count(6);
}
eval { unlink $confFiles->[1]; rmdir $main::tmpdir; };

done_testing( count() );
