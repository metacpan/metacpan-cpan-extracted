#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'IO::AIO::LoadLimited' ) || print "Bail out!\n";
}

diag( "Testing IO::AIO::LoadLimited $IO::AIO::LoadLimited::VERSION, Perl $], $^X" );
