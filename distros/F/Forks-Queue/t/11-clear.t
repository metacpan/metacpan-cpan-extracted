use Test::More;
use strict;
use warnings;
use Forks::Queue;
use lib '.';   # 5.26 compat
require "t/exercises.tt";


foreach my $impl (IMPL()) {

    my $q = Forks::Queue->new( impl => $impl );
    ok($q, "$impl queue created");
    $q->put( 1 .. 50 );
    ok($q->pending == 50, "queue populated");
    $q->clear;
    ok($q->pending == 0, "clear function depopulates queue");
    $q->{file} &&
	ok(-s $q->{file} == $q->{_header_size},
	   "queue file contains header but no items");
    $q->put( 1 .. 50 );
    ok($q->pending == 50, "queue repopulated");
    $q->put( 1 .. 50 );
    ok($q->pending == 100, "queue more populated");
}

done_testing;
