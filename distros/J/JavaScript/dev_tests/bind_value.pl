#!/usr/bin/perl

use strict;
use warnings;

use JavaScript;

my $rt = JavaScript::Runtime->new();
my $cx = $rt->create_context();

$cx->bind_function(write => sub { print @_, "\n"; });

$cx->eval("foo = 1; write(foo)");

$cx->bind_value(foo => 10);

$cx->eval("write(foo)");

JavaScript::dump_sv_report_used();