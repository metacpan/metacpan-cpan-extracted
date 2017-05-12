#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'MIME::Multipart::ParseSimple' ) || print "Bail out!\n";
}

diag( "Testing MIME::Multipart::ParseSimple $MIME::Multipart::ParseSimple::VERSION, Perl $], $^X" );
