#!perl -T

use Test::More tests => 1;

use lib qw( lib );

BEGIN {
    use_ok( 'Lingua::EN::NameParse::Simple' );
}

diag( "Testing Lingua::EN::NameParse::Simple $Lingua::EN::NameParse::Simple::VERSION, Perl $], $^X" );
