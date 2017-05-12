use Test::More;
use strict;
use warnings;
use Forks::Queue;
require "t/exercises.tt";

foreach my $impl (IMPL()) {

    my $q = Forks::Queue->new( impl => $impl, list => [ 1 .. 50 ]);
    ok($q);
    ok($q->pending == 50);

    my $q2 = Forks::Queue->new(
        impl => $impl,
        join => 1,
        file => $q->{file}, db_file => $q->{db_file},
        list => [ 'A' .. 'Z' ]);

    ok($q->pending == 76);
    ok($q2->pending == 76);

    $q->clear;
    ok($q->pending == 0);
    ok($q2->pending == 0);
    if ($impl ne 'SQLite') {
        ok(-s $q->{file} == $q->{_header_size});
    }
    $q->put( 1 .. 50 );
    ok($q->pending == 50);
    $q->put( 1 .. 50 );
    ok($q->pending == 100);
}


done_testing;
