#!perl

use strict;
use warnings;

use Test::More;
use HTML::Packer; 

if (! eval "use Test::Memory::Cycle; 1;" ) {
	plan skip_all => 'Test::Memory::Cycle required for this test';
}

my $packer = HTML::Packer->init;
memory_cycle_ok( $packer );

my $row = "<html><head> <title>Foo</title></head><body></body></html>";

for ( 1 .. 5 ) { 
	ok( $packer->minify( \$row,{} ),'minify' );
}

memory_cycle_ok( $packer );
done_testing();
