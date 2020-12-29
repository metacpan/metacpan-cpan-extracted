use Test::More;
use strict;
use warnings;
use Forks::Queue;
use lib '.';   # 5.26 compat
require "t/exercises.tt";

foreach my $impl (IMPL()) {

    my $q = Forks::Queue->new( impl => $impl, list => [ 1 .. 50 ],
                               style => 'fifo' );
    ok($q, "$impl queue created");
    ok($q->pending == 50, '50 items found');

    my @u = $q->extract;
    ok(@u == 1 && $u[0] == 1, 'bare extract gets 1st elem') or diag @u;

    my @t = $q->extract(5);
    ok(@t == 1, "extract(arg) retrieves 1 elem");
    ok($t[0] == 7, 'extract(arg) gets arg+1-th elem') or diag @t;

    @u = $q->extract(-10);
    ok(@u == 1 && $u[0] == 41, 'extract(-arg) reads from back') or diag @u;

    @u = $q->extract(32,5);
    ok(@u == 5 && join(" ",@u) eq "35 36 37 38 39",
       'extract(arg,count) gets multiple elem') or diag "@u";

    @u = $q->extract(-6,3);
    ok(@u == 3 && join(" ",@u) eq "45 46 47",
       'extract(-arg,count) gets multiple elem from back') or diag "@u";

    @u = $q->extract(100);
    ok(!@u, 'extract past end returns nothing') or diag @u;

    @u = $q->extract(-100);
    ok(!@u, 'extract past start returns nothing') or diag @u;

    ok($q->pending == 39, '11 items extracted so far');
    $q->put( 'A' .. 'Z' );

    @u = $q->extract(60,10);
    ok(@u == 5 && join(" ",@u) eq "V W X Y Z",
       'extract with high count returns avail') or diag "@u";

    @u = $q->extract(-65,10);
    ok(@u == 5 && join(" ",@u) eq "2 3 4 5 6",
       'extract with high neg count returns avail') or diag "@u";
}

done_testing;
