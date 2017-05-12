#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DBD::SQLite }
        or plan skip_all => 'DBD::SQLite is required for this test';
    $ENV{TEST_FOORUM} = 1;
    plan tests => 12;
}

use FindBin;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, '..', 'lib' );
use Foorum::SUtils qw/schema/;
use Foorum::TestUtils qw/rollback_db/;
my $schema = schema();

my $tbl = $schema->resultset('UserOnline');

my $sid1 = '592b2952f82e5ccba9efef44d449a4f73c47049a';
my $sid2 = 'a2ee56f9f1be271d820b09e1845364625dc86430';
my $sid3 = 'bd57aced938ac441a59ba5613a818d74c66aefe2';
my $sid4 = 'e2f1e61bdea452610a9084679cb01ad8fbe79d9f';

# create data
$tbl->create(
    {   sessionid  => $sid1,
        user_id    => 1,
        path       => 'forum/FoorumTest',
        title      => 'Foorum Test',
        start_time => time() - 800,
        last_time  => time(),
    }
);
$tbl->create(
    {   sessionid  => $sid2,
        user_id    => 0,
        path       => 'forum/FoorumTest2',
        title      => 'Foorum Test',
        start_time => time() - 360,
        last_time  => time() - 200,
    }
);
$tbl->create(
    {    # outdated user
        sessionid  => $sid3,
        user_id    => 2,
        path       => 'forum/FoorumTest2',
        title      => 'Foorum Test2',
        start_time => time() - 3700,
        last_time  => time() - 2000,
    }
);

# test functions
# 1, get_data
my @rets = $tbl->get_data($sid1);
@rets = @{ $rets[0] };    # since return is (\@onlines, $pager);
is( scalar @rets,        2,     'get_data 2 session' );
is( $rets[0]->sessionid, $sid1, 'get_data by last_time DESC 1' );
is( $rets[1]->sessionid, $sid2, 'get_data by last_time DESC 2' );

# 2, get_data with non-exists $sid4
@rets = $tbl->get_data($sid4);
@rets = @{ $rets[0] };           # since return is (\@onlines, $pager);
is( scalar @rets, 3,      'get_data 3 session' );
is( $rets[-1],    'SELF', 'return SELF' );

# 3, get_data with FoorumCode
@rets = $tbl->get_data( $sid1, 'FoorumTest' );
@rets = @{ $rets[0] };           # since return is (\@onlines, $pager);
is( scalar @rets,        1,     'get_data with FoorumTest' );
is( $rets[0]->sessionid, $sid1, 'get_data with FoorumTest result' );

# 4, test whos_view_this_page
@rets = $tbl->whos_view_this_page( $sid2, 'forum/FoorumTest2' );
is( scalar @rets, 1, 'whos_view_this_page with forum/FoorumTest2' );
is( $rets[0]->sessionid, $sid2, 'whos_view_this_page1 result' );

# 5, test whos_view_this_page with non-exists $sid4
@rets = $tbl->whos_view_this_page( $sid4, 'forum/FoorumTest2' );
is( scalar @rets,        2,     'whos_view_this_page with non-exists $sid4' );
is( $rets[0]->sessionid, $sid2, 'whos_view_this_page2 result' );
is( $rets[-1], 'SELF', 'return SELF' );

END {

    # Keep Database the same from original
    rollback_db();
}

1;
