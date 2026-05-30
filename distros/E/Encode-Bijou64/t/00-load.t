use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('Encode::Bijou64') || print "Bail out!\n";
}

diag( "Testing Encode::Bijou64 $Encode::Bijou64::VERSION, Perl $], $^X" );
