#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'File::Format::CRD' );
    use_ok( 'File::Format::CRD::Reader' );
}

diag( "Testing File::Format::CRD $File::Format::CRD::VERSION, Perl $], $^X" );
