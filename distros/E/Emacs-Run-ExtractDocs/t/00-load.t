#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Emacs::Run::ExtractDocs' );
}

diag( "Testing Emacs::Run::ExtractDocs $Emacs::Run::ExtractDocs::VERSION, Perl $], $^X" );
