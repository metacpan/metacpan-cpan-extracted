#!perl
use Test::More tests => 8;
use strict;
use Devel::Pointer::PP;

ok( Devel::Pointer::PP->can( 'import' ),
    "Devel::Pointer::PP can import()" );

# Test for function exports
for my $function ( 'address_of',
		   'deref',
		   'unsmash_sv',
		   'unsmash_av',
		   'unsmash_av',
		   'unsmash_cv' ) {
    ok( eval { Devel::Pointer::PP->import( $function ); 1 },
	"Devel::Pointer::PP exports $function" );
}

cmp_ok( Devel::Pointer::PP->VERSION, '>=', 0.01,
	"Devel::Pointer::PP->VERSION is specified" );
