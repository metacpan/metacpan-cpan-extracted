#!/usr/bin/perl

use strict;
use warnings;

use JSPL;

my $rt = JSPL::Runtime->new();
my $cx = $rt->create_context();

$cx->bind_function(return_simple => sub { []; });

$cx->eval("v = return_simple(); undef");
