#!/usr/bin/perl

use FindBin qw( $Bin );
use lib $Bin .q{/../lib};

use Test::More;

require $Bin . q{/../lib/Sample/Simple/Baz.pm};

plan tests => 3;

is ( Sample::Simple::Baz::foo(5,  0),  5, "a-foo works, range 1");
is ( Sample::Simple::Baz::foo(7,  0), 70, "a-foo works, range 2");
is ( Sample::Simple::Baz::foo(20, 0), 20, "a-foo works, range 3");

