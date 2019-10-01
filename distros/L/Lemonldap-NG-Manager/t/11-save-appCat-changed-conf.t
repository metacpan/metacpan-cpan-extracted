# Verify that an unmodified configuration is rejected

use Data::Dumper;
use Test::More;
use strict;
use JSON;
require 't/test-lib.pm';

my @struct    = qw[t/jsonfiles/03-base-tree-appCat-modifed.json];
my @desc      = ('Changed conf with deleted Category');
my $confFiles = [ 't/conf/lmConf-1.json', 't/conf/lmConf-2.json' ];

sub body {
    return 0 unless (@struct);
    my $t = shift @struct;
    return IO::File->new( $t, 'r' );
}

# Delete lmConf-2.json if exists
eval { unlink $confFiles->[1]; };
mkdir 't/sessions';

# Try to save a modified conf
while ( my $body = &body() ) {
    my $desc = shift @desc;
    my ( $res, $resBody );
    ok(
        $res =
          &client->_post( '/confs/', 'cfgNum=1', $body, 'application/json' ),
        "$desc: positive result"
    );
    ok( $res->[0] == 200, "$desc: result code is 200" )
      or print STDERR Dumper($res);
    ok(
        $resBody = from_json( $res->[2]->[0] ),
        "$desc: result body contains JSON text"
    );

    #print STDERR Dumper($resBody);
    ok( $resBody->{result} == 1, "$desc: JSON response contains \"result:1\"" );
    ok( @{ $resBody->{details}->{__changes__} } eq 2,
        "$desc: conf has changed" )
      or print STDERR Dumper($resBody);
    ok(
        $resBody->{details}->{__changes__}->[0]->{new} eq
          'categoryList, Administration, Documentation',
        "$desc: new key received"
    ) or print STDERR Dumper($resBody);
    ok(
        $resBody->{details}->{__changes__}->[0]->{old} eq
          'categoryList, Administration, Documentation, Sample applications',
        "$desc: old key received"
    ) or print STDERR Dumper($resBody);
    ok(
        $resBody->{details}->{__changes__}->[0]->{key} eq
          'Deletes in cat(s), Sample applications',
        "$desc: key received"
    ) or print STDERR Dumper($resBody);
    ok( -e $confFiles->[1], "$desc: file is created" );

    #print STDERR Dumper($resBody);
    count(9);
}
eval { unlink $confFiles->[1]; rmdir 't/sessions'; };

done_testing( count() );

# Remove sessions directory
`rm -rf t/sessions`;

