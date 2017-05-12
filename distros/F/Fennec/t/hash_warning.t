#!/usr/bin/env perl
package Test::HashWarning;
use strict;
use warnings;

use Fennec;

tests 'sub' => (
    sub => sub { ok( 1, "sanity" ) },
);

tests 'code' => (
    code => sub { ok( 1, "sanity" ) },
);

tests 'method' => (
    method => sub { ok( 1, "sanity" ) },
);

tests 'sub tail' => (
    foo => 'bar',
    sub { ok( 1, "sanity" ) },
);

tests 'sub param' => (
    foo => 'bar',
    sub => sub { ok( 1, "sanity" ) },
    baz => 'bar',
);

tests 'method param' => (
    foo    => 'bar',
    method => sub { ok( 1, "sanity" ) },
    baz    => 'bar',
);

tests 'code param' => (
    foo  => 'bar',
    code => sub { ok( 1, "sanity" ) },
    baz  => 'bar',
);

done_testing;
