use strict;
use warnings;

use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'Grep::Query' ) || print "Bail out!\n";
    use_ok( 'Grep::Query::FieldAccessor' ) || print "Bail out!\n";
    use_ok( 'Grep::Query::Parser' ) || print "Bail out!\n";
    use_ok( 'Grep::Query::Parser::QOPS' ) || print "Bail out!\n";
}

diag( "Testing Grep::Query $Grep::Query::VERSION, Perl $], $^X" );
