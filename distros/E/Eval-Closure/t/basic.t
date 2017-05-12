#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Eval::Closure;

{
    my $code = eval_closure(
        source => 'sub { die "called\n" }',
    );
    ok($code, "got something");

    like(exception { $code->() }, qr/^called$/, "got the right thing");
}

{
    my $foo = [];

    my $code = eval_closure(
        source      => 'sub { push @$bar, @_ }',
        environment => {
            '$bar' => \$foo,
        },
    );
    ok($code, "got something");

    $code->(1);

    is_deeply($foo, [1], "got the right thing");
}

{
    my $foo = [1, 2, 3];

    my $code = eval_closure(
        # not sure if strict leaking into evals is intended, i think i remember
        # it being changed in newer perls
        source => 'do { no strict; sub { $foo } }',
    );

    ok($code, "got something");

    ok(!$code->(), "environment is clean");
}

done_testing;
