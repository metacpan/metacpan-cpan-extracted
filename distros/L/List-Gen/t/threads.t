#!/usr/bin/perl
use strict;
use warnings;
$|=1;
BEGIN {
    eval q{
        BEGIN {die if %Devel::Cover::}
        use threads;
        use threads::shared;
    1} or eval q{
        use Test::More skip_all => 'could not use threads';
        exit;
    }
}
use Test::More tests => 13;
use lib qw(../lib lib t/lib);
use List::Gen '*';
use List::Gen::Testing;

{
    my $gen = gen {$_**2} 10;

    t 'threads_all',
        is_deeply => [$gen->threads_all], [$gen->all];

    $gen->threads_stop;
}
{
    my $gen = gen {$_**2} 10;

    t 'threads_all implicit stop',
        is_deeply => [$gen->threads_all], [$gen->all];
}

for (0 .. 9) {
    my $gen = gen {$_**2} $_;

    t "threads_all size $_",
        is_deeply => [$gen->threads_all], [$gen->all];
}
{
    my $fib;
       $fib = cache gen {$_ < 2 ? $_ : $fib->($_ - 1) + $fib->($_ - 2)};

    t 'threads_slice precached',
        is_deeply => [$fib->threads_slice(0 .. 100)], [$fib->slice(0 .. 100)];

    $fib->threads_stop;
}
