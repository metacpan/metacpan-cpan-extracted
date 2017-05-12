#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'FFmpeg::Stream::Helper' ) || print "Bail out!\n";
}

diag( "Testing FFmpeg::Stream::Helper $FFmpeg::Stream::Helper::VERSION, Perl $], $^X" );
