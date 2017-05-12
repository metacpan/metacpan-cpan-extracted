#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use ok "Devel::Sub::Which";

# bart found this in 0.01's import
{
	package foo;
	use Devel::Sub::Which qw/:universal ref_to_name/;
}

ok(foo->can('ref_to_name'), "ref_to_name imported despite appearing after :universal");

