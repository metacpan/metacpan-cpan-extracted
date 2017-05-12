#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DBD::SQLite }
        or plan skip_all => 'DBD::SQLite is required for this test';
    $ENV{TEST_FOORUM} = 1;
    plan tests => 3;
}

use FindBin;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, '..', 'lib' );
use Foorum::SUtils qw/schema/;
use Foorum::TestUtils qw/rollback_db/;

my $schema = schema();

my $visit_res = $schema->resultset('Visit');

# test make_visited
$visit_res->make_visited( 'test', 1, 2 );
my $count = $visit_res->count(
    { object_type => 'test', object_id => 1, user_id => 2 } );
is( $count, 1, 'make_visited OK' );

# test is_visited
my $ret = $visit_res->is_visited( 'test', 1, 2 );
is_deeply( $ret, { test => { 1 => 1 } }, 'is_visited OK' );

# test make_un_visited
$visit_res->make_un_visited( 'test', 1 );
$count = $visit_res->count(
    { object_type => 'test', object_id => 1, user_id => 2 } );
is( $count, 0, 'make_visited OK' );

END {

    # Keep Database the same from original
    rollback_db();
}

1;
