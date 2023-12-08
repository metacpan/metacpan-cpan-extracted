#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Deep;
use Test::Fatal;

use JavaScript::QuickJS;

for my $mod (qw(os std)) {
    my $js = JavaScript::QuickJS->new()->$mod();

    # ensure that this doesn't crash
    is(
        exception { $js->eval_module( qq<import * as what from "$mod";> ) },
        undef,
        "JS with $mod(): module can import $mod",
    );

    my $keys = $js->eval( qq<Object.keys($mod)> );
    cmp_deeply(
        $keys,
        superbagof( ignore() ),
        "JS with $mod(): global “$mod” exists in script mode",
    ) or diag explain $keys;

    my $js2 = JavaScript::QuickJS->new();
    cmp_deeply(
        exception { $js2->eval_module( qq<import * as what from "$mod";> ) },
        re(qr/ReferenceError/),
        "JS without $mod(): module fails to import $mod",
    );

    cmp_deeply(
        exception { $js2->eval( qq<Object.keys($mod)> ) },
        re(qr/ReferenceError/),
        "JS without $mod(): script lacks global $mod",
    );
}

done_testing;
