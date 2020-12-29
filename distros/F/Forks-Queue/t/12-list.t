use Test::More;
use strict;
use warnings;
use Forks::Queue;
use lib '.';   # 5.26 compat
require "t/exercises.tt";

foreach my $impl (IMPL()) {

    my $q = Forks::Queue->new( impl => $impl, list => [ 1 .. 50 ]);
    ok($q, "$impl queue created");
    ok($q->pending == 50, "initial queue is populated");

    my $q2 = Forks::Queue->new(
        impl => $impl,
        join => 1,
        file => $q->{file}, db_file => $q->{db_file},
        list => [ 'A' .. 'Z' ]);

    ok($q->pending == 76, "queue more populated");
    ok($q2->pending == 76, "linked queue more populated");

    $q->clear;
    ok($q->pending == 0, "clear depopulates queue");
    ok($q2->pending == 0, "clear depopulated linked queue");
    if ($impl ne 'SQLite') {
        ok(-s $q->{file} == $q->{_header_size},
	    "queue has no items, file size equals header size");
    }
    $q->put( 1 .. 50 );
    ok($q->pending == 50, "queue repopulated");
    $q->put( 1 .. 50 );
    ok($q->pending == 100, "queue more populated");
}


done_testing;
