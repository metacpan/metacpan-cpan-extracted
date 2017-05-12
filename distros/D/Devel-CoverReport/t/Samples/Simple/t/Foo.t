#!/usr/bin/perl

use FindBin qw( $Bin );
use lib $Bin .q{/../lib};

use Test::More;

require $Bin . q{/../lib/Sample/Simple/Foo.pm};

plan tests => 1;

ok (-e $Bin . q{/../lib/Sample/Simple/Foo.pm}, q{Foo exists.});

