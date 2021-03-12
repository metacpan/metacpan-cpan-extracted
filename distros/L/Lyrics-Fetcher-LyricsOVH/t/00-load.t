#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Lyrics::Fetcher::LyricsOVH' ) || print "Bail out!\n";
}

diag( "Testing Lyrics::Fetcher::LyricsOVH $Lyrics::Fetcher::LyricsOVH::VERSION, Perl $], $^X" );
