#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

BEGIN { $^P |= 0x210 } # PERLDBf_SUBLINE

use Eval::Closure;

unlike(
    exception {
        eval_closure(
            source      => 'sub { $bar }',
            description => 'foo',
        )
    },
    qr/#line/,
    "#line directive isn't added when debugger is active"
);


done_testing;
