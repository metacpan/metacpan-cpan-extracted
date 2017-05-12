#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Device::PaloAlto::Firewall' ) || print "Could not load Device::PaloAlto::Firewall\n";
}

diag( "\nTesting Device::PaloAlto::Firewall $Device::PaloAlto::Firewall::VERSION, Perl $], $^X" );

BEGIN {

    use_ok( 'Device::PaloAlto::Firewall::Test' ) || print "Could not load Device::PaloAlto::Firewall::Test\n";
}

diag( "Testing Device::PaloAlto::Firewall::Test $Device::PaloAlto::Firewall::Test::VERSION, Perl $], $^X" );
