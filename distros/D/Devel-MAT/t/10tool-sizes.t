#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Devel::MAT::Dumper;
use Devel::MAT;

my $DUMPFILE = "test.pmat";

our $EMPTY_SVIV = 123;
our @EMPTY_AV = ();

our @ARRAY = ( 123, 45, [ 6, 7 ] );

Devel::MAT::Dumper::dump( $DUMPFILE );
END { unlink $DUMPFILE; }

my $pmat = Devel::MAT->load( $DUMPFILE );
ok ( scalar( grep { $_ eq "Sizes" } $pmat->available_tools ), 'Sizes tool is available' );

$pmat->load_tool( "Sizes" );

my $sviv_size = $pmat->find_symbol( '$EMPTY_SVIV' )->size;
my $av_size   = $pmat->find_symbol( '@EMPTY_AV' )->size;

my $av = $pmat->find_symbol( '@ARRAY' );
my $av2 = $av->elem(2)->rv;

# Structure
{
   is( scalar $av->structure_set, 4, '$av->structure_set' );

   cmp_ok( $av->size, '>', $av_size, '$av->size > $av_size' );
   is( $av->structure_size,
       $av->size + 3*$sviv_size,
       '$av->structure_size' );
}

# Owned
{
   is( scalar $av->owned_set, 7, '$av->owned_set' );

   is( $av->owned_size,
       $av->size + 3*$sviv_size + $av2->size + 2*$sviv_size,
       '$av->owned_size' );
}

done_testing;
