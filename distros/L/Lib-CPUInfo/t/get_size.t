#!/usr/bin/perl

use strict;
use warnings;
use Test::More 'tests' => 2 + 1;
use Lib::CPUInfo qw<
    initialize
    deinitialize
    get_max_cache_size
>;

can_ok(
    main::,
    qw<
        initialize
        deinitialize
        get_max_cache_size
    >,
);

ok( initialize(), 'Successfully initialized with initialize()' );
my $size = get_max_cache_size();
like(
    $size,
    qr/^[0-9]+$/xms,
    "get_max_cache_size() ($size)",
);

