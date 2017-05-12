#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Device::ELM327' ) || print "Bail out!
";
}

diag( "Testing Device::ELM327 $Device::ELM327::VERSION, Perl $], $^X" );
