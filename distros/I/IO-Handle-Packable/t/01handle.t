#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::Handle::Packable;

my $fh = IO::Handle::Packable->new;

{
   ok( $fh->open( \( my $buffer = "" ), ">" ), '$fh can ->open a memory buffer for writing' );

   $fh->print( "Output\n" );
   is( $buffer, "Output\n", '$fh can ->print to buffer' );
}

{
   ok( $fh->open( \"Input\n", "<" ), '$fh can ->open a memory buffer for reading' );

   is( <$fh>, "Input\n", '$fh can ->getline' );
}

done_testing;
