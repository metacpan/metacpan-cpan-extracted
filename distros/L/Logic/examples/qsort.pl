#!/usr/bin/perl

use lib 'blib/lib';
use Logic::Easy;

sub qsort : Multi(qsort) {
    SIG [];
    ();
}

sub qsort : Multi(qsort) {
    SIG cons($x, $xs);
    my @pre  = grep { $_ < $x } @$xs;
    my @post = grep { $_ >= $x } @$xs;
    (qsort(@pre), $x, qsort(@post));
}

print join(',', qsort(2, 6, 5, 3, 1, 4)), "\n";
