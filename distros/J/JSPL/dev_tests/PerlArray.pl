#!/usr/bin/perl

use strict;
use warnings;

use JSPL;

my $cx = JSPL->create_runtime->create_context;

$cx->bind_function(println => sub { print STDERR @_, "\n" });

$cx->eval(q{
   var pa = new PerlArray();
   pa.push(10, 20, 30);
});

