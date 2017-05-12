#!/usr/bin/perl

use FindBin qw( $Bin );
use lib $Bin .q{/../lib};

use Test::More;

require $Bin . q{/../lib/Sample/Simple/Baz.pm};

plan tests => 3;

is ( Sample::Simple::Baz::foo(undef, 5),   5, "b-foo works, range 1");
is ( Sample::Simple::Baz::foo(undef, 7),  70, "b-foo works, range 2");
is ( Sample::Simple::Baz::foo(undef, 20), 20, "b-foo works, range 3");

