#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Eval::Closure;

{
    my $code = eval_closure(
        source =>
            'sub {'
          .     '"foo"'
          . '}',
    );
    ok($code, "got code");
    is($code->(), "foo", "got the right code");
}

{
    my $code = eval_closure(
        source => [
            'sub {',
                '"foo"',
            '}',
        ],
    );
    ok($code, "got code");
    is($code->(), "foo", "got the right code");
}

done_testing;
