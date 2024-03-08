#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Devel::MAT::Dumper;
$Devel::MAT::Dumper::VERSION >= 0.38 or
   plan skip_all => "Devel::MAT::Dumper too old to capture 'local' saves";
$] >= 5.018 or
   plan skip_all => "Devel::MAT::Dumper can't capture 'local' saves from this version of perl";

use Devel::MAT;

our $SVAR = "old value";
local $SVAR = "new value";  # SV

our @AVAR = ( 1, 2, 3 );
local @AVAR = ( 4, 5 );  # AV

our %HVAR = ( old => "value" );
local %HVAR = ( new => "value" );  # HV

sub GVAR { 1 }  my $codeline = __LINE__;
no warnings 'redefine';
local *GVAR = sub { 2 };

my @ARRAY = (qw( a b c ));
local $ARRAY[1] = "d";  # AELEM

my %HASH = ( key => "oldval" );
local $HASH{key} = "newval";  # HELEM

my $DUMPFILE = __FILE__ =~ s/\.t/\.pmat/r;

Devel::MAT::Dumper::dump( $DUMPFILE );
END { unlink $DUMPFILE if defined $DUMPFILE; }

my $pmat = Devel::MAT->load( $DUMPFILE );
my $df = $pmat->dumpfile;

# SVAR
{
   my $gv = $pmat->find_glob( "SVAR" );
   my ( $savedref ) = grep { $_->name =~ m/^saved / } $gv->outrefs;

   is( $savedref->name, "saved value of SCALAR slot", '$savedref->name' );
   is( $savedref->sv->pv, "old value", '$savedref->sv->pv' );
}

# AVAR
{
   my $gv = $pmat->find_glob( "AVAR" );
   my ( $savedref ) = grep { $_->name =~ m/^saved / } $gv->outrefs;

   is( $savedref->name, "saved value of ARRAY slot", '$savedref->name' );
   is( $savedref->sv->elems, 3, '$savedref->sv->elems' );
}

# HVAR
{
   my $gv = $pmat->find_glob( "HVAR" );
   my ( $savedref ) = grep { $_->name =~ m/^saved / } $gv->outrefs;

   is( $savedref->name, "saved value of HASH slot", '$savedref->name' );
   ok( $savedref->sv->value( "old" ), '$savedref->sv has "old" key' );
}

# GVAR
{
   my $gv = $pmat->find_glob( "GVAR" );
   my ( $savedref ) = grep { $_->name =~ m/^saved / } $gv->outrefs;

   is( $savedref->name, "saved value of CODE slot", '$savedref->name' );
   is( $savedref->sv->line, $codeline, '$savedref->sv->line' );
}

# AELEM
{
   my $av = $pmat->dumpfile->main_cv->lexvar( '@ARRAY' );
   my ( $savedref ) = grep { $_->name =~ m/^saved / } $av->outrefs;

   is( $savedref->name, "saved value of element [1]", '$savedref->name' );
   is( $savedref->sv->pv, "b", '$savedref->sv->pv' );
}

# HELEM
{
   my $hv = $pmat->dumpfile->main_cv->lexvar( '%HASH' );
   my ( $savedref ) = grep { $_->name =~ m/^saved / } $hv->outrefs;

   is( $savedref->name, "saved value of value {key}", '$savedref->name' );
   is( $savedref->sv->pv, "oldval", '$savedref->sv->pv' );
}

done_testing;
