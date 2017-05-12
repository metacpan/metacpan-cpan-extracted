#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
	plan tests => 3;
}

BEGIN {
    use_ok( 'Gcode::Interpreter' ) || print "Bail out!\n";
}

diag( "Testing Gcode::Interpreter $Gcode::Interpreter::VERSION, Perl $], $^X" );

my $obj;

ok($obj = Gcode::Interpreter->new());

isa_ok($obj, 'Gcode::Interpreter::Ultimaker');

