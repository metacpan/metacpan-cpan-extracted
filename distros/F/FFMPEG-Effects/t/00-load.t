#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'FFMPEG::Effects' ) || print "Bail out!
";
}

diag( "Testing FFMPEG::Effects $FFMPEG::Effects::VERSION, Perl $], $^X" );
