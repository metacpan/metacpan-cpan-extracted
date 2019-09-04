use Test::More;
use strict;
use warnings;
use Forks::Queue;
use lib '.';   # 5.26 compat
require "t/exercises.tt";


foreach my $impl (IMPL()) {

    my $q = Forks::Queue->new( impl => $impl );
    ok($q);
    $q->put( 1 .. 50 );
    ok($q->pending == 50);
    $q->clear;
    ok($q->pending == 0);
    $q->{file} && ok(-s $q->{file} == $q->{_header_size});
    $q->put( 1 .. 50 );
    ok($q->pending == 50);
    $q->put( 1 .. 50 );
    ok($q->pending == 100);
}

done_testing;
