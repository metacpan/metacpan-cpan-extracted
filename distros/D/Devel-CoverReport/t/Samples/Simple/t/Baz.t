#!/usr/bin/perl

use FindBin qw( $Bin );
use lib $Bin .q{/../lib};

use Test::More;

require $Bin . q{/../lib/Sample/Simple/Baz.pm};

plan tests => 4;

is ( Sample::Simple::Baz::foo(5, 20),  5, "a+b-foo works, range 1");
is ( Sample::Simple::Baz::foo(7,  7), 70, "a+b-foo works, range 2");
is ( Sample::Simple::Baz::foo(20, 5), 20, "a+x-foo works, range 3");

is ( Sample::Simple::Baz::foo(0, 0), undef, "no a, no b works too");

