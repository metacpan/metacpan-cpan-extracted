#!perl

use Test::More tests => 1;

use strict;
use warnings;

use JavaScript;

# Create a new runtime
my $rt1 = JavaScript::Runtime->new();

# Create a new context
my $cx1 = $rt1->create_context();
my $rval = $cx1->eval_file("t/07-eval-file.js");

is($rval, 51200, "Eval file return value");

