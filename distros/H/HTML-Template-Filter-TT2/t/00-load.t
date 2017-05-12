#!perl -T
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok( 'HTML::Template::Filter::TT2' );
}

diag( "Testing HTML::Template::Filter::TT2 $HTML::Template::Filter::TT2::VERSION, Perl $], $^X" );
