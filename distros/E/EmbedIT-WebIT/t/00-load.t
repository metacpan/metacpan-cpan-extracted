#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'EmbedIT::WebIT' );
}

diag( "Testing EmbedIT::WebIT $EmbedIT::WebIT::VERSION, Perl $], $^X" );
