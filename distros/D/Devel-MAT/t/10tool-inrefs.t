#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use List::Util qw( pairgrep );

use Devel::MAT::Dumper;
use Devel::MAT;

my $ADDR = qr/0x[0-9a-f]+/;

my $DUMPFILE = __FILE__ =~ s/\.t/\.pmat/r;

Devel::MAT::Dumper::dump( $DUMPFILE );
END { unlink $DUMPFILE; }

my $pmat = Devel::MAT->load( $DUMPFILE );
my $df = $pmat->dumpfile;

$pmat->available_tools;
$pmat->load_tool( "Inrefs" );

BEGIN { our @AofA = ( [] ); }
{
   my $av = $pmat->find_symbol( '@AofA' );

   my $rv  = $av->elem(0);
   my $av2 = $rv->rv;

   my @inrefs_direct = $av2->inrefs_direct;
   is( scalar @inrefs_direct, 1, '$av2->inrefs_direct is 1' );
   is( $inrefs_direct[0]->sv,       $rv,             'AV inref[0] SV is $rv' );
   is( $inrefs_direct[0]->strength, "strong",        'AV inref[0] strength is strong' );
   is( $inrefs_direct[0]->name,     "the referrant", 'AV inref[0] name' );

   my @av2_inrefs = $av2->inrefs;
   is( ( grep { $_->name eq "element [0] via RV" } @av2_inrefs )[0]->sv, $av,
      '$av2 is referred to as element[0] via RV of $av' );

   is( [ map { $_->sv } $av2->inrefs_indirect ], [ $av ],
      '$av2->inrefs_indirect' );
}

{
   my @pvs = grep { $_->desc =~ m/^SCALAR/ and
                    defined $_->pv and
                    $_->pv eq $DUMPFILE } $df->heap;

   # There's likely only one item in this list:
   #   1 value of the $DUMPFILE lexical itself
   my ( $lexical ) = grep {
      grep { $_->name eq 'the lexical $DUMPFILE' } $_->inrefs
   } @pvs;

   ok( $lexical, 'Found the $DUMPFILE lexical' );
}

BEGIN { our $PACKAGE_SCALAR = "some value" }
{
   my $sv = $pmat->find_symbol( '$PACKAGE_SCALAR' );

   my $svnode = $pmat->inref_graph( $sv, depth => 4 );

   ok( defined $svnode, '->inref_graph $sv defined' );

   my ( undef, $gvnode ) = pairgrep { $a->name eq "the scalar" } $svnode->edges_in;
   ok( $gvnode, '$svnode has "the scalar" edge in' );
   is( $gvnode->sv->type, "GLOB", 'gvnode is a GLOB' );

   my ( undef, $stashnode ) = pairgrep { $a->name eq "value {PACKAGE_SCALAR}" } $gvnode->edges_in;
   ok( $stashnode, '$gvnode has value {PACKAGE_SCALAR}' );
   is( $stashnode->sv->type, "STASH", 'svnode stash is a STASH' );

   ok( scalar( grep { $_->name eq "the default stash" } $stashnode->roots ),
      'stashnode has default stash as a root' );
}

done_testing;
