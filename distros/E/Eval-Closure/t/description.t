#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Eval::Closure;

my $source = <<'SOURCE';
sub {
    Carp::confess("foo")
}
SOURCE

{
    my $code = eval_closure(
        source => $source,
    );

    like(
        exception { $code->() },
        qr/^foo at \(eval \d+\) line \d+/,
        "no location info if context isn't passed"
    );
}

{
    my $code = eval_closure(
        source      => $source,
        description => 'accessor foo (defined at Class.pm line 282)',
    );

    like(
        exception { $code->() },
        qr/^foo at accessor foo \(defined at Class\.pm line 282\) line 2/,
        "description is set"
    );
}

{
    my $code = eval_closure(
        source      => $source,
        line        => 100,
        description => 'accessor foo (defined at Class.pm line 282)',
    );

    like(
        exception { $code->() },
        qr/^foo at accessor foo \(defined at Class\.pm line 282\) line 101/,
        "description is set"
    );
}
done_testing;
