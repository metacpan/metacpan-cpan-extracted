#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Drought::PET::Thornthwaite' ) || print "Bail out!\n";
}

diag( "Testing Drought::PET::Thornthwaite $Drought::PET::Thornthwaite::VERSION, Perl $], $^X" );
