#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::FailWarnings;

use JavaScript::QuickJS;

my $js = JavaScript::QuickJS->new();

my $result = $js->eval( q<
    [
        true,
        false,
        0,
        -1,
        999,
        99.9999,
        [ "abc", "ünicøde" ],
        { foo: "bar", baz: undefined, undefined: null },
    ];
> );

cmp_deeply(
    $result,
    [
        !!1,
        !!0,
        0,
        -1,
        999,
        num(99.9999, 0.01),
        [ "abc", "ünicøde" ],
        { foo => "bar", baz => undef, undefined => undef },
    ],
    'expected output',
) or diag explain $result;

eval { $js->eval('[].foo.bar.baz = 234') };
my $err = $@;

like($err, qr<TypeError>, 'error type is given');
like($err, qr<bar>, 'error detail (key) is given');
like($err, qr<undefined>, 'error detail (bad value) is given');

ok(
    $js->eval("'Promise' in this"),
    'Promise object exists',
);

done_testing;

1;
