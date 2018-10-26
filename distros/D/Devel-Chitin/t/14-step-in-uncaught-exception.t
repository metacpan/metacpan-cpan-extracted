use strict;
use warnings;

use Test2::V0; no warnings 'void';
use lib 't/lib';
use TestHelper qw(ok_location ok_uncaught_exception db_step);

$DB::single=1;
die "untrapped";   # 9
11;

sub __tests__ {
    plan tests => 2;

    ok_location line => 9;
    db_step;

    ok_uncaught_exception
        line => 9,
        package => 'main',
        subroutine => 'MAIN',
        filename => __FILE__,
        exception => 'untrapped at ' . __FILE__ . " line 9.\n";
}

