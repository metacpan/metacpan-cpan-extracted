#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Exporter' );
    use_ok( 'List::ToHumanString' );
}

diag( "Testing List::ToHumanString $List::ToHumanString::VERSION, Perl $], $^X" );
