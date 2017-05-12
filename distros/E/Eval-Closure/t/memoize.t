#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Requires 'Test::Output';

use Eval::Closure;

# XXX this whole test isn't very useful anymore, since we no longer do
# memoization. it would be nice to bring it back at some point though, if there
# was a way to do this without breaking the other tests

plan skip_all => "disabling this test for now";

{
    my $source = 'BEGIN { warn "foo\n" } sub { $foo * 2 }';

    my $code;
    my $bar = 15;
    stderr_is {
        $code = eval_closure(
            source      => $source,
            environment => {
                '$foo' => \$bar,
            },
        );
    } "foo\n", "BEGIN was run";

    is($code->(), 30, "got the right sub");

    my $code2;
    my $baz = 8;
    stderr_is {
        $code2 = eval_closure(
            source      => $source,
            environment => {
                '$foo' => \$baz,
            },
        );
    } '', "BEGIN was not run twice";

    is($code2->(), 16, "got the right sub");
}

{
    my $source = 'BEGIN { warn "bar\n" } sub { $bar * 2 }';

    my $code;
    my $foo = 60;
    stderr_is {
        $code = eval_closure(
            source      => $source,
            environment => {
                '$bar' => \$foo,
            },
            description => 'foo',
        );
    } "bar\n", "BEGIN was run";

    is($code->(), 120, "got the right sub");

    my $code2;
    my $baz = 23;
    { local $TODO = "description breaks memoization";
    stderr_is {
        $code2 = eval_closure(
            source      => $source,
            environment => {
                '$bar' => \$baz,
            },
            description => 'baz',
        );
    } '', "BEGIN was not run twice";
    }

    is($code2->(), 46, "got the right sub");
}

{
    my $source = 'BEGIN { warn "baz\n" } sub { Carp::confess "baz" }';

    my $code;
    stderr_is {
        $code = eval_closure(
            source      => $source,
            description => 'first',
        );
    } "baz\n", "BEGIN was run";

    like(exception { $code->() }, qr/baz at first line 1/,
         "got the right description");

    my $code2;
    { local $TODO = "description breaks memoization";
    stderr_is {
        $code2 = eval_closure(
            source      => $source,
            description => 'second',
        );
    } '', "BEGIN was not run twice";
    }

    like(exception { $code2->() }, qr/baz at second line 1/,
         "got the right description");
}

done_testing;
