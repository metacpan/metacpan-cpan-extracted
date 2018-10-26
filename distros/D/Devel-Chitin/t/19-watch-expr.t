use strict;
use warnings;

use Test2::V0;  no warnings 'void';
use lib 't/lib';
use TestHelper qw(ok_add_watchexpr ok_location ok_watched_expr_notification db_continue);

my $a;
$DB::single=1; 9;
10;
11;
$a = 2;
13;
$a = 2;
15;
16;
$a = 3;
18;
19;

sub __tests__ {
    plan tests => 3;

    ok_add_watchexpr('$a', 'Add watch expr');
    db_continue;

    ok_watched_expr_notification
        line => 12,
        expr => '$a',
        old => [ undef ],
        new => [ 2 ];

    ok_watched_expr_notification
        line => 17,
        expr => '$a',
        old => [ 2 ],
        new => [ 3 ];
}
