#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    if (!eval { require 5.018; 1 }) {
        plan skip_all => "this test requires 5.18";
    }
}
use 5.018;

use Eval::Closure;

my $sub = eval_closure(
    source => 'sub { foo() }',
    environment => {
        '&foo' => sub { state $i++ },
    }
);

is($sub->(), 0);
is($sub->(), 1);
is($sub->(), 2);

done_testing;
