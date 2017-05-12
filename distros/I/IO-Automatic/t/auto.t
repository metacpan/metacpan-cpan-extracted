#!perl -w
use strict;
use Test::More tests => 3;
use_ok('IO::Automatic');
my $scalar;
my $io = IO::Automatic->new( \$scalar );
ok( $io, "got an IO for a scalar ref" );
print $io "Hello, World";
is( $scalar, "Hello, World", "scalar printed to" );
