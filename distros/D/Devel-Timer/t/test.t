#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Capture::Tiny qw(capture);
my $tests;
plan tests => 6;

use_ok( 'Devel::Timer');

subtest simple => sub {
    plan tests => 10;

    my ($stdout, $stderr, $exit) = capture {
        my $t = _process();
        $t->report();
    };

    like(  $stderr, qr/Total time/,                "Total time");
    like(  $stderr, qr/Interval  Time    Percent/, "header");
    like(  $stderr, qr/00 -> 01 .* INIT -> A/,     "step 0");
    like(  $stderr, qr/01 -> 02 .* A -> B/,        "step 1");
    like(  $stderr, qr/02 -> 03 .* B -> A/,        "step 2");
    like(  $stderr, qr/03 -> 04 .* A -> B/,        "step 3");
    like(  $stderr, qr/04 -> 05 .* B -> A/,        "step 4");
    like(  $stderr, qr/05 -> 06 .* A -> B/,        "step 5");
    like(  $stderr, qr/06 -> 07 .* B -> C/,        "step 6");
    unlike($stderr, qr/07 -> 08/,                  "no step 7");
    #diag $stderr;
};

subtest another => sub {
    plan tests => 7;

    my ($stdout, $stderr, $exit) = capture {
        my $t = _process();
        $t->report(collapse => 1);
    };

    like(  $stderr, qr/Total time/,                "Total time");
    like(  $stderr, qr/Count     Time    Percent/, "header");
    like(  $stderr, qr/\n + 3 .* A -> B/,          "A -> B");
    like(  $stderr, qr/\n + 1 .* B -> C/,          "B -> C");
    like(  $stderr, qr/\n + 2 .* B -> A/,          "B -> A");
    like(  $stderr, qr/\n + 1 .* INIT -> A/,       "INIT -> A");
    like(  $stderr, qr/A -> B.* B -> C.* B -> A.* INIT -> A/s, 
                                                   "order by time descending");
    #diag $stderr;
};

subtest simple_reset => sub {
    plan tests => 9;

    my ($stdout, $stderr, $exit) = capture {
        my $t = _process();
        $t->reset();
        $t = _process_work($t);
        $t->report();
    };

    like(  $stderr, qr/Total time/,                "Total time");
    like(  $stderr, qr/Interval  Time    Percent/, "header");
    like(  $stderr, qr/00 -> 01 .* A -> B/,        "step 0");
    like(  $stderr, qr/01 -> 02 .* B -> A/,        "step 1");
    like(  $stderr, qr/02 -> 03 .* A -> B/,        "step 2");
    like(  $stderr, qr/03 -> 04 .* B -> A/,        "step 3");
    like(  $stderr, qr/04 -> 05 .* A -> B/,        "step 4");
    like(  $stderr, qr/05 -> 06 .* B -> C/,        "step 5");
    unlike($stderr, qr/06 -> 07/,                  "no step 6");
    #diag $stderr;
};

subtest sort_by_count => sub {
    plan tests => 7;

    my ($stdout, $stderr, $exit) = capture {
        my $t = _process();
        $t->report(collapse => 1, sort_by => 'count');
    };

    like(  $stderr, qr/Total time/,                "Total time");
    like(  $stderr, qr/Count     Time    Percent/, "header");
    like(  $stderr, qr/\n + 3 .* A -> B/,          "A -> B");
    like(  $stderr, qr/\n + 1 .* B -> C/,          "B -> C");
    like(  $stderr, qr/\n + 2 .* B -> A/,          "B -> A");
    like(  $stderr, qr/\n + 1 .* INIT -> A/,       "INIT -> A");
    # If we sort by count there are two possible versions of the report
    # that are correct (because B -> C and INIT -> A both only happened one time
    # so we don't care which one shows up first on the report.
    my $test = 
       (($stderr =~ /A -> B.* B -> A.* B -> C.* INIT -> A/s)  or
       ($stderr =~ /A -> B.* B -> A.* INIT -> A.* B -> C/s));
    ok($test, "sort by count") or diag $stderr;
    #diag $stderr;
};

subtest process => sub {
    plan tests => 24;


    my $t;
    my ($stdout, $stderr, $exit) = capture {
        $t = _process();
        #$t->report(collapse => 1, sort_by => 'count');
    };

    my ($time, $percent, $count);
    ok(($time, $percent, $count) = $t->get_stats("A", "B"),   "get_stats('A', 'B')");
    cmp_ok($time,     '>=', 0.6,   '$time');
    cmp_ok($time,     '<=', 0.8,   '$time');
    cmp_ok($percent,  '>=', 60,    '$percent');
    cmp_ok($percent,  '<=', 70,    '$percent');
    cmp_ok($count,    '==', 3,     '$count');
    ok(($time, $percent, $count) = $t->get_stats("B", "A"),   "get_stats('B', 'A')");
    cmp_ok($time,     '>=', 0,     '$time');
    cmp_ok($time,     '<=', 0.15,  '$time');
    cmp_ok($percent,  '>=', 0,     '$percent');
    cmp_ok($percent,  '<=', 10,    '$percent');
    cmp_ok($count,    '==', 2,     '$count');
    ok(($time, $percent, $count) = $t->get_stats("B", "C"),   "get_stats('B', 'C')");
    cmp_ok($time,     '>=', 0.2,   '$time');
    cmp_ok($time,     '<=', 0.4,   '$time');
    cmp_ok($percent,  '>=', 25,    '$percent');
    cmp_ok($percent,  '<=', 32,    '$percent');
    cmp_ok($count,    '==', 1,     '$count');
    ok(($time, $percent, $count) = $t->get_stats("INIT", "A"), "get_stats('INIT', 'A')");
    cmp_ok($time,     '>=', 0,     '$time');
    cmp_ok($time,     '<=', 0.1,   '$time');
    cmp_ok($percent,  '>=', 0,     '$percent');
    cmp_ok($percent,  '<=', 5,     '$percent');
    cmp_ok($count,    '==', 1,     '$count');
    #diag $stderr;
};



sub _process {
    my $t = _process_init();

    $t = _process_work($t);

    return $t;
}
sub _process_init {

    my $t = Devel::Timer->new();

    return $t;
}

sub _process_work {
    my ($t) = @_;

    $t->mark("A");

    ## do some more work
    select(undef, undef, undef, 0.7);
    $t->mark("B");

    ## do some work
    select(undef, undef, undef, 0.05);
    $t->mark("A");
    $t->mark("B");
    $t->mark("A");
    $t->mark("B");

    ## do some more work
    select(undef, undef, undef, 0.3);
    $t->mark("C");

    return $t;
}
