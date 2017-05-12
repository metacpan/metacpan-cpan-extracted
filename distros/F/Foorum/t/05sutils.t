#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
    $ENV{TEST_FOORUM} = 1;
}

use Test::More tests => 3;
use FindBin;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, 'lib' );
use DBI;
use Foorum::SUtils qw/schema/;
use Foorum::TestUtils qw/rollback_db/;

my $schema = schema();
isa_ok( $schema, 'Foorum::Schema', 'schema() ISA Foorum::Schema' );

my @sources = $schema->sources();
ok( grep { 'User'  eq $_ } @sources, 'sources contains User' );
ok( grep { 'Forum' eq $_ } @sources, 'sources contains Forum' );

END {

    # Keep Database the same from original
    rollback_db();
}
