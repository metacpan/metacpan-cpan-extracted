#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
BEGIN {
   eval { require Devel::MAT; } or
      plan skip_all => "No Devel::MAT";

   eval { require Devel::MAT::Dumper; Devel::MAT::Dumper->VERSION( '0.45' ) } or
      plan skip_all => "No Devel::MAT::Dumper version 0.45 or above";
   eval { require Object::Pad; Object::Pad->VERSION( '0.66' ) } or
      plan skip_all => "No Object::Pad version 0.66 or above";

   require Devel::MAT::Dumper;
}

use List::Util qw( first );

use Object::Pad;

class AClass
{
   field $afield :param :reader;
}

my $obj = AClass->new( afield => 123 );

( my $file = __FILE__ ) =~ s/\.t$/.pmat/;
Devel::MAT::Dumper::dump( $file );
END { unlink $file if -f $file }

my $pmat = Devel::MAT->load( $file );
my $df = $pmat->dumpfile;

# Boot the tool
$pmat->available_tools;

# class/field/method representation
{
   # TODO: Do we want an `$sv->find_outref` method?
   my $classmeta = ( first { $_->name eq "the Object::Pad class" }
      $pmat->find_symbol( "&AClass::META" )->constval->rv->outrefs
   )->sv;

   ok( $classmeta, 'AClass has a classmeta' );
   isa_ok( $classmeta, "Devel::MAT::SV::C_STRUCT", '$classmeta' );
   isa_ok( $classmeta, "Devel::MAT::Tool::Object::Pad::_ClassSV", '$classmeta' );

   is( $classmeta->desc, "C_STRUCT(Object::Pad/ClassMeta.class)", '$classmeta->desc' );

   is( $classmeta->objectpad_name, "AClass", '$classmeta name' );

   # Field
   my @fieldmetas = $classmeta->field_named(
      # Field was renamed in 0.807
      $Object::Pad::VERSION ge 0.807 ? "the fields AV" : "the direct fields AV"
   )->elems;
   is( scalar @fieldmetas, 1, '$classmeta has 1 fieldmeta' );

   my $fieldmeta = $fieldmetas[0];
   isa_ok( $fieldmeta, "Devel::MAT::SV::C_STRUCT", '$fieldmeta' );
   isa_ok( $fieldmeta, "Devel::MAT::Tool::Object::Pad::_FieldSV", '$fieldmeta' );

   is( $fieldmeta->desc, "C_STRUCT(Object::Pad/FieldMeta)", '$fieldmeta->desc' );

   is( $fieldmeta->objectpad_name, '$afield',   '$fieldmeta name' );
   is( $fieldmeta->objectpad_class, $classmeta, '$fieldmeta class' );

   # Method
   my @methodmetas = $classmeta->field_named( "the direct methods AV" )->elems;
   is( scalar @methodmetas, 1, '$classmeta has 1 methodmeta' );

   my $methodmeta = $methodmetas[0];
   isa_ok( $methodmeta, "Devel::MAT::SV::C_STRUCT", '$methodmeta' );
   isa_ok( $methodmeta, "Devel::MAT::Tool::Object::Pad::_MethodSV", '$methodmeta' );

   is( $methodmeta->desc, "C_STRUCT(Object::Pad/MethodMeta)", '$methodmeta->desc' );

   is( $methodmeta->objectpad_name,  "afield",   '$methodmeta name' );
   is( $methodmeta->objectpad_class, $classmeta, '$methodmeta class' );
}

done_testing;
