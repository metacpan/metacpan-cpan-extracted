#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DBD::SQLite }
        or plan skip_all => 'DBD::SQLite is required for this test';
    $ENV{TEST_FOORUM} = 1;
    plan tests => 7;
}

use FindBin;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, '..', 'lib' );
use Foorum::SUtils qw/schema/;
use Foorum::TestUtils qw/rollback_db/;
my $schema = schema();

my $ssc = $schema->resultset('SecurityCode');

$ssc->create(
    {   type    => 1,              # 'forget_password',
        user_id => 1,
        code    => '1234567890',
        time    => time(),
    }
);
$ssc->create(
    {   type    => 1,              # 'forget_password',
        user_id => 2,
        code    => '1234567899',
        time    => time(),
    }
);

# test functions
# 1, get
my $code = $ssc->get( 'forget_password', 1 );
is( $code, '1234567890', 'get 1234567890 from forget_password 1' );
$code = $ssc->get( 'forget_password', 2 );
is( $code, '1234567899', 'get 1234567890 from forget_password 2' );

# 2, get_or_create
$code = $ssc->get_or_create( 'forget_password', 2 );
is( $code, '1234567899', 'get_or_create 1234567890 from forget_password 2' );
$code = $ssc->get_or_create( 'forget_password', 3 );
is( length($code), 12, 'get_or_create' );
my $code2 = $ssc->get( 'forget_password', 3 );
is( $code2, $code, 'get == get_or_create after get_or_create' );

$ssc->remove( 'forget_password', 1 );
$code = $ssc->get( 'forget_password', 1 );
is( $code, undef, 'get undef from forget_password after remove' );
my $cnt = $ssc->count();
is( $cnt, 2, 'get correct count' );

END {

    # Keep Database the same from original
    rollback_db();
}

1;
