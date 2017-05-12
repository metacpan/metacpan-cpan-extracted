#!perl

use Test::More tests => 1;

use strict;
use warnings;

use JSPL;

# Create a new runtime
my $rt1 = JSPL::Runtime->new();

# Create a new context
my $cx1 = $rt1->create_context();
my $rval = $cx1->eval_file("t/07-eval-file.js");

is($rval, 51200, "Eval file return value");

