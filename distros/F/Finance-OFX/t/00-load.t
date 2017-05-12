#!perl -T

use Test::More tests => 7;

BEGIN {
    use_ok( 'Finance::OFX' ) || print "Bail out!\n";
    use_ok( 'Finance::OFX::Account' ) || print "Bail out!\n";
    use_ok( 'Finance::OFX::Institution' ) || print "Bail out!\n";
    use_ok( 'Finance::OFX::Parse' ) || print "Bail out!\n";
    use_ok( 'Finance::OFX::Response' ) || print "Bail out!\n";
    use_ok( 'Finance::OFX::Tree' ) || print "Bail out!\n";
    use_ok( 'Finance::OFX::UserAgent' ) || print "Bail out!\n";
}

diag( "Testing Finance::OFX $Finance::OFX::VERSION, Perl $], $^X" );
