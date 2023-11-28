#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Ixchel::functions::install_cpanm' ) || print "Bail out!\n";
}

diag( "Testing Ixchel $Ixchel::functions::install_cpanm::VERSION, Perl $], $^X" );
