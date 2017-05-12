#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MLDBM::Serializer::JSON' ) || print "Bail out!
";
}

diag( "Testing MLDBM::Serializer::JSON $MLDBM::Serializer::JSON::VERSION, Perl $], $^X" );
