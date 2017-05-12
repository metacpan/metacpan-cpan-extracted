use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'HON::I18N::Converter' ) || print "Bail out!\n";
}

diag( "Testing HON::I18N::Converter $HON::I18N::Converter::VERSION, Perl $], $^X" );
