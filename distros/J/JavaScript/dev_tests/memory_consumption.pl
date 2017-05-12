#!/usr/bin/perl

use strict;
use warnings;

use JavaScript;

print $$, "\n";

my $rt = JavaScript::Runtime->new();
my $cx = $rt->create_context();

my $r = {};
$cx->bind_function(returns_array_ref => sub { return [1..10]; });
$cx->bind_function(writeln => sub { print @_, "\n" });

{
    $cx->eval(q/
for (var i = 0; i < 200001; i++) {
    var v = returns_array_ref();
    if (i % 10000 == 0) {
        writeln("Created " + i + " array refs");
    }
}
/);
}

# Wait for ok
<>;