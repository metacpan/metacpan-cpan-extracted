#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'FFmpeg::Thumbnail' ) || print "Bail out!
";
}

diag( "Testing FFmpeg::Thumbnail $FFmpeg::Thumbnail::VERSION, Perl $], $^X" );
