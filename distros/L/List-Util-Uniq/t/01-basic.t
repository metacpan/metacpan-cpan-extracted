#!perl

use strict;
use warnings;
use Test::More 0.98;

use List::Util::Uniq qw(
                           uniq
                           uniqint
                           uniqnum
                           uniqstr

                           uniq_adj
                           uniq_adj_ci
                           uniq_ci
                           is_uniq
                           is_uniq_ci
                           is_monovalued
                           is_monovalued_ci

                           dupe
                           dupeint
                           dupenum
                           dupestr

                           dupe_ci

                           pushuniq
                           pushuniqstr
                           pushuniqnum
                           pushuniqint
                        );

subtest "uniq, uniqstr" => sub {
    is_deeply([uniq   (1,"a",2,1,"a","b")], [1,"a",2,"b"]);
    is_deeply([uniqstr(1,"a",2,1,"a","b")], [1,"a",2,"b"]);
};

subtest "uniqnum" => sub {
    is_deeply([uniqnum(1,2,"1.0","1.1")], [1,2,"1.1"]);
};

subtest "uniqint" => sub {
    is_deeply([uniqint(1,2,"1.0","1.1")], [1,2]);
};

subtest "uniq_adj" => sub {
    is_deeply([uniq_adj(1, 2, 4, 4, 4, 2, 4)], [1, 2, 4, 2, 4]);
};

subtest "uniq_adj_ci" => sub {
    is_deeply([uniq_adj   (qw/a b B a b C c/)], [qw/a b B a b C c/]);
    is_deeply([uniq_adj_ci(qw/a b B a b C c/)], [qw/a b a b C/]);
};

subtest "uniq_ci" => sub {
    #is_deeply([uniq   (qw/a b B a b C c/)], [qw/a b B C c/]);
    is_deeply([uniq_ci(qw/a b B a b C c/)], [qw/a b C/]);
    is_deeply([uniq_ci("a","b","B",undef,"c",undef)], ["a","b",undef,"c"]);
};

subtest "is_uniq" => sub {
    ok( is_uniq());
    ok( is_uniq(qw/a/));
    ok( is_uniq(qw/a b/));
    ok( is_uniq(qw/a A/));
    ok(!is_uniq(qw/a a/));
};

subtest "is_uniq_ci" => sub {
    ok( is_uniq_ci());
    ok( is_uniq_ci(qw/a/));
    ok( is_uniq_ci(qw/a b/));
    ok(!is_uniq_ci(qw/a A/));
    ok(!is_uniq_ci(qw/a a/));
};

subtest "is_monovalued" => sub {
    ok( is_monovalued());
    ok( is_monovalued(qw/a/));
    ok(!is_monovalued(qw/a b/));
    ok(!is_monovalued(qw/a A/));
    ok( is_monovalued(qw/a a/));
};

subtest "is_monovalued_ci" => sub {
    ok( is_monovalued_ci());
    ok( is_monovalued_ci(qw/a/));
    ok(!is_monovalued_ci(qw/a b/));
    ok( is_monovalued_ci(qw/a A/));
    ok( is_monovalued_ci(qw/a a/));
};

subtest "dupe" => sub {
    is_deeply([dupe()], []);
    is_deeply([dupe(1,2)], []);
    is_deeply([dupe(qw/a b d d d b c/)], [qw/d d b/]);
    is_deeply([dupe(1, 2, 4, 4, 4, 2, 4)], [4,4,2,4]);

    is_deeply([uniq(dupe(1, 2, 4, 4, 4, 2, 4))], [4,2]);
};

subtest "dupeint" => sub {
    is_deeply([dupeint()], []);
    is_deeply([dupeint(1,2)], []);
    is_deeply([dupeint(1, 2, 4, 4, 4, 2, 4)], [4,4,2,4]);
    is_deeply([dupeint("a","b")], ["b"]);
    is_deeply([dupeint(1, 1.1)], [1.1]);

    is_deeply([uniqint(dupeint(1, 2, 4, 4, 4, 2, 4))], [4,2]);
};

subtest "dupenum" => sub {
    is_deeply([dupenum()], []);
    is_deeply([dupenum(1,2)], []);
    is_deeply([dupenum(1, 2, 4, 4, 4, 2, 4)], [4,4,2,4]);
    is_deeply([dupenum("a","b")], ["b"]);

    is_deeply([uniqnum(dupenum(1, 2, 4, 4, 4, 2, 4))], [4,2]);
};

subtest "dupestr" => sub {
    is_deeply([dupestr()], []);
    is_deeply([dupestr(1,2)], []);
    is_deeply([dupestr(qw/a b d d d b c/)], [qw/d d b/]);
    is_deeply([dupestr(1, 2, 4, 4, 4, 2, 4)], [4,4,2,4]);

    is_deeply([uniqstr(dupestr(qw/a b d d d b c/))], [qw/d b/]);
};

subtest "dupe_ci" => sub {
    is_deeply([dupe_ci(qw/a b B a b C c/)], [qw/B a b c/]);
    is_deeply([dupe_ci("a","b","B",undef,"c",undef)], ["B",undef]);
};

subtest "pushuniq, pushuniqstr" => sub {
    my @ary;

    @ary = (1,"a",2,1,"a","b");
    pushuniq @ary, 1,"a","c","c";
    is_deeply(\@ary, [1,"a",2,1,"a","b","c"]);

    @ary = (1,"a",2,1,"a","b");
    pushuniqstr @ary, 1,"a","c","c";
    is_deeply(\@ary, [1,"a",2,1,"a","b","c"]);
};

subtest "pushuniqnum" => sub {
    my @ary;

    @ary = (1,"1.0",1.1,2);
    pushuniqnum @ary, 2,"1.00",1.2,"1.000",3,3;
    is_deeply(\@ary, [1,"1.0",1.1,2,1.2,3]);
};

subtest "pushuniqint" => sub {
    my @ary;

    @ary = (1,"1.0",1.1,2);
    pushuniqint @ary, 2,"1.00",1.2,"1.000",3,3;
    is_deeply(\@ary, [1,"1.0",1.1,2,3]);
};

DONE_TESTING:
done_testing;
