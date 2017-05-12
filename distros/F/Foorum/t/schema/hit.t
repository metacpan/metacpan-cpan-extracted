#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DBD::SQLite }
        or plan skip_all => 'DBD::SQLite is required for this test';
    $ENV{TEST_FOORUM} = 1;
    plan tests => 5;
}

use FindBin;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, '..', 'lib' );
use Foorum::SUtils qw/schema/;
use Foorum::TestUtils qw/rollback_db/;
my $schema = schema();

my $hit_res = $schema->resultset('Hit');

my $ret = $hit_res->register( 'test1', 2 );
my $hit_rs = $hit_res->search(
    {   object_type => 'test1',
        object_id   => 2
    }
)->first;
isnt( $hit_rs, undef, 'hit_rs is not undef' );
is( $hit_rs->hit_new, 1, 'hit_new OK' );
is( $hit_rs->hit_all, 1, 'hit_all OK' );
is( $ret,             1, 'return value OK' );
cmp_ok( $hit_rs->last_update_time, '>', 0, 'last_update_time OK' );

$hit_res->search(
    {   object_type => 'test1',
        object_id   => 2
    }
)->delete;

END {

    # Keep Database the same from original
    rollback_db();
}

1;
