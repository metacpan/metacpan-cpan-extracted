#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use JavaScript::QuickJS;

my $js = JavaScript::QuickJS->new();

# my $cb = $js->eval("function add1(val) { return val + 1 }; add1");
my $cb = $js->helpers->eval("let foo = (val) => val + 1; foo");

is(
    $cb->(2),
    3,
    'JS function called from Perl',
);

undef $cb;

pass 'Still alive (callback reaped)';

undef $js;

pass 'Still alive (JS reaped)';

done_testing();
