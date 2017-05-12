#!/usr/bin/perl

use FindBin qw( $Bin );
use lib $Bin .q{/../lib};

use Test::More;

require $Bin . q{/../lib/Sample/Simple/Bar.pm};

plan tests => 2;

is ( Sample::Simple::Bar::foo(5, 0),  5, "a-foo works");
is ( Sample::Simple::Bar::foo(0, 7), 70, "b-foo works");

