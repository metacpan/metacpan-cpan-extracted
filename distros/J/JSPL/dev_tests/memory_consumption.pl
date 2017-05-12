#!/usr/bin/perl
use strict;
use warnings;

use JSPL;

warn "$$\n";

my $cx = JSPL->stock_context();
# For JSPL v1.X be two orders of magnitude harder than original JavaScript.pm

$cx->bind_function(returns_array_ref => sub { return [1 .. 100]; });

{
    $cx->eval(q/
for (var i = 0; i < 2000001; i++) {
    var v = returns_array_ref();
    if(i % 10000 == 0)
        say("Created " + i + " array refs");
}
/);
}

# Wait for ok
<>;
