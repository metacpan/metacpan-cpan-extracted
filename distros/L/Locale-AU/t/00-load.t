#!perl -T

use strict;
use warnings;

use Test::Most tests => 1;

BEGIN {
    use_ok( 'Locale::AU' ) || print "Bail out!
";
}

diag( "Testing Locale::AU $Locale::AU::VERSION, Perl $], $^X" );
