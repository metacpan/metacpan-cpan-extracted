#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use FindBin;
use lib $FindBin::RealBin."/../lib";

plan tests => 1;

BEGIN {
    use_ok( 'Finance::IG' ) || print "Bail out!\n";
}

diag( "Testing Finance::IG $Finance::IG::VERSION, Perl $], $^X" );
