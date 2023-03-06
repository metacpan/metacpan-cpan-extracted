#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

BEGIN {
   require feature;
   no warnings 'once';
   defined $feature::feature{class} or plan skip_all => "feature 'class' is not available";
}

use experimental 'class';

class AClass {
   field $x = "the scalar field";
   field @y = ( "the array field" );
   field %z = ( name => "the hash field" );
}

my $obj = AClass->new;

use Devel::MAT::Dumper;
use Devel::MAT;

my $ADDR = qr/0x[0-9a-f]+/;

my $DUMPFILE = __FILE__ =~ s/\.t/\.pmat/r;

Devel::MAT::Dumper::dump( $DUMPFILE );
END { unlink $DUMPFILE; }

my $pmat = Devel::MAT->load( $DUMPFILE );
my $df = $pmat->dumpfile;

{
   ok( my $obj = $df->sv_at( 0+$obj ), '$df has obj SV' );
   is( $obj->basetype, "OBJ", 'Object base type' );
   is( $obj->desc, "OBJ()", 'Object ->desc' );

   my $cls = $obj->blessed;
   is( $cls->basetype, "HV", 'Class base type' );
   is( $cls->type, "CLASS", 'Class type' );
   is( $cls->desc, "STASH(2)", 'Class ->desc' );

   is( scalar( my @fields = $cls->fields ), 3, 'Class has 3 fields' );
   is( $fields[0]->fieldix, 0, 'Fields[0] fieldix' );
   is( $fields[0]->name, '$x', 'Fields[0] name' );

   my $xfield = $obj->field( '$x' );
   is( $xfield->desc, "SCALAR(PV)", 'Description of $x field' );

   my $yfield = $obj->field( '@y' );
   is( $yfield->desc, "ARRAY(1)", 'Description of @y field' );

   my $zfield = $obj->field( '%z' );
   is( $zfield->desc, "HASH(1)", 'Description of %z field' );
}

done_testing;
