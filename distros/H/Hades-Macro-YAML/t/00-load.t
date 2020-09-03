#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Hades::Macro::YAML' ) || print "Bail out!\n";
}

diag( "Testing Hades::Macro::YAML $Hades::Macro::YAML::VERSION, Perl $], $^X" );
