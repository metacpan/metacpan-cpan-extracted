#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 8;

BEGIN {
    use_ok( 'Math::DWT' ) || print "Bail out!\n";
    use_ok( 'Math::DWT::Wavelet::Haar' ) || print "Bail out!\n";
    use_ok( 'Math::DWT::Wavelet::Daubechies' ) || print "Bail out!\n";
    use_ok( 'Math::DWT::Wavelet::Coiflet' ) || print "Bail out!\n";
    use_ok( 'Math::DWT::Wavelet::Symlet' ) || print "Bail out!\n";
    use_ok( 'Math::DWT::Wavelet::Biorthogonal' ) || print "Bail out!\n";
    use_ok( 'Math::DWT::Wavelet::ReverseBiorthogonal' ) || print "Bail out!\n";
    use_ok( 'Math::DWT::Wavelet::DiscreteMeyer' ) || print "Bail out!\n";
}

diag( "Testing Math::DWT $Math::DWT::VERSION, Perl $], $^X" );
