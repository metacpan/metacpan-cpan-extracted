#!perl -T

use Test::More tests => 2;

use File::LinkDir;

my $fld = File::LinkDir->new(
    source => 't/tests/src',
    dest   => 't/tests/dest',
);

ok( defined $fld );

isa_ok( $fld, 'File::LinkDir' );


