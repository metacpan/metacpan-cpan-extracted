#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Digest::FNV::PurePerl' );
}

diag( "Testing Digest::FNV::PurePerl $Digest::FNV::PurePerl::VERSION, Perl $], $^X" );
