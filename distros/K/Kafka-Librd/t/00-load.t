#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Kafka::Librd' ) || print "Bail out!\n";
}

diag( "Testing Kafka::Librd $Kafka::Librd::VERSION, Perl $], $^X" );
