#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use List::Util qw( pairgrep );
use Scalar::Util qw( weaken );

use Devel::MAT::Dumper;
use Devel::MAT;

my $DUMPFILE = "test.pmat";

# Set up a reference cycle with an easy-to-find PV in it
# Run this from an anonymous sub so we know the lexical is dropped
do {
   my $av = [ undef, "This is" ];
   $av->[0] = $av;
   $av->[1] .= " a cycle";
   undef $av;
};
# It might still be in the temp SV; try to overwrite it
my $tmp = [];
$tmp->[0] = 0;
undef $tmp;

Devel::MAT::Dumper::dump( $DUMPFILE );
END { unlink $DUMPFILE; }

my $pmat = Devel::MAT->load( $DUMPFILE );
ok( scalar( grep { $_ eq "Reachability" } $pmat->available_tools ), 'Reachability tool is available' );

$pmat->load_tool( "Reachability" );

my $df = $pmat->dumpfile;

{
   my $defstash = $df->defstash;
   ok( $defstash->reachable, 'Default stash is reachable' );

   my $dump = $pmat->find_symbol( "&Devel::MAT::Dumper::dump" );
   ok( $dump->reachable, '&Devel::MAT::Dumper::dump is reachable' );
}

SKIP: {
   my @pvs = grep { $_->desc eq "SCALAR(P)" and $_->pv eq join " ", qw( This is a cycle ) } $df->heap;

   skip "Could not find SCALAR(P) containing 'This is a cycle'", 1 unless @pvs;
   skip "Could not uniquely identify the PV in the cyclic leak AV", 1 unless @pvs == 1;

   my ( $pv ) = @pvs;

   ok( !$pv->reachable, "'This is a cycle' PV is not reachable" );
   if( $pv->reachable ) {
      diag( "PV is:" );
      diag( $_ ) for $pmat->identify( $pv );
   }
}

done_testing;
