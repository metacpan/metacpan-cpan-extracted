#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Ereshkigal::Kur' ) || print "Bail out!\n";
}

diag( "Testing Ereshkigal $Ereshkigal::Kur::VERSION, Perl $], $^X" );
