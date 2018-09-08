#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;

use Scalar::Util qw( weaken );

use Devel::MAT::Dumper;
use Devel::MAT;

my $ADDR = qr/0x[0-9a-f]+/;

my $DUMPFILE = __FILE__ =~ s/\.t/\.pmat/r;

Devel::MAT::Dumper::dump( $DUMPFILE );
END { unlink $DUMPFILE; }

my $pmat = Devel::MAT->load( $DUMPFILE );
my $df = $pmat->dumpfile;

ok( my $defstash = $df->defstash, '$df has default stash' );

BEGIN { our $PACKAGE_SCALAR = "some value" }
{
   ok( my $gv = $defstash->value( "PACKAGE_SCALAR" ), 'default stash has PACKAGE_SCALAR GV' );
   ok( my $sv = $gv->scalar, 'PACKAGE_SCALAR GV has SCALAR' );

   is( $sv->symname, '$main::PACKAGE_SCALAR', 'PACKAGE_SCALAR SV has a name' );
   is( $sv->basetype, 'SV', 'SV base type' );

   identical( $pmat->find_symbol( '$PACKAGE_SCALAR' ), $sv,
      '$pmat->find_symbol $PACKAGE_SCALAR' );

   identical( $pmat->find_symbol( '$::PACKAGE_SCALAR' ), $sv,
      '$pmat->find_symbol $::PACKAGE_SCALAR' );

   identical( $pmat->find_symbol( '$main::PACKAGE_SCALAR' ), $sv,
      '$pmat->find_symbol $main::PACKAGE_SCALAR' );

   is( $sv->pv, "some value", 'PACKAGE_SCALAR SV has PV' );
}

BEGIN { our @PACKAGE_ARRAY = qw( A B C ) }
{
   ok( my $gv = $defstash->value( "PACKAGE_ARRAY" ), 'default stash hash PACKAGE_ARRAY GV' );
   ok( my $av = $gv->array, 'PACKAGE_ARRAY GV has ARRAY' );

   is( $av->symname, '@main::PACKAGE_ARRAY', 'PACKAGE_ARRAY AV has a name' );
   is( $av->basetype, 'AV', 'AV base type' );

   identical( $pmat->find_symbol( '@PACKAGE_ARRAY' ), $av,
      '$pmat->find_symbol @PACKAGE_ARRAY' );

   is( $av->elem(1)->pv, "B", 'PACKAGE_ARRAY AV has elements' );
}

BEGIN { our %PACKAGE_HASH = ( one => 1, two => 2 ) }
{
   ok( my $gv = $defstash->value( "PACKAGE_HASH" ), 'default stash hash PACKAGE_HASH GV' );
   ok( my $hv = $gv->hash, 'PACKAGE_HASH GV has HASH' );

   is( $gv->basetype, 'GV', 'GV base type' );
   is( $hv->symname, '%main::PACKAGE_HASH', 'PACKAGE_HASH hv has a name' );
   is( $hv->basetype, 'HV', 'HV base type' );

   identical( $pmat->find_symbol( '%PACKAGE_HASH' ), $hv,
      '$pmat->find_symbol %PACKAGE_HASH' );

   is( $hv->value("one")->uv, 1, 'PACKAGE_HASH HV has elements' );
}

{
   ok( my $backrefs = $defstash->backrefs, 'Default stash HV has backrefs' );
   ok( $backrefs->is_backrefs, 'Backrefs AV knows it is a backrefs list' );
}

sub PACKAGE_CODE { my $lexvar = "An unlikely scalar value"; }
{
   ok( my $cv = $defstash->value_code( "PACKAGE_CODE" ), 'default stash has PACKAGE_CODE CV' );

   is( $cv->symname, '&main::PACKAGE_CODE', 'PACKAGE_CODE CV has a name' );
   is( $cv->basetype, 'CV', 'CV base type' );

   is( $cv->depth, 0, 'PACKAGE_CODE CV currently has depth 0' );

   identical( $pmat->find_symbol( '&PACKAGE_CODE' ), $cv,
      '$pmat->find_symbol &PACKAGE_CODE' );

   is( $cv->padname( 1 )->name, '$lexvar', 'PACKAGE_CODE CV has padname(1)' );
   is( $cv->padix_from_padname( '$lexvar' ), 1, 'PACKAGE_CODE CV can find padix from padname' );
   cmp_ok( $cv->max_padix, '>=', 1, 'PACKAGE_CODE CV has at least 1 pad entry' );

   my @constants = $cv->constants;
   ok( @constants, 'CV has constants' );
   is( $constants[0]->pv, "An unlikely scalar value", 'CV constants' );

   # PADNAMES stopped being a real thing after 5.20
   if( $df->{perlver} <= ( ( 5 << 24 ) | ( 20 << 16 ) | 0xffff ) ) {
      is( $cv->padnames_av->type, "PADNAMES", 'CV has padnames' );
   }

   my $pad0 = $cv->pad(1);
   is( $pad0->type, "PAD", 'CV has pad(1)' );
   is( $pad0->padcv, $cv, 'PAD at 1 has padcv' );

   is( $pad0->lexvar( '$lexvar' ), $cv->lexvar( '$lexvar', 1 ), 'CV has lexvar' );
}

BEGIN { our @AofA = ( [] ); }
{
   my $av = $pmat->find_symbol( '@AofA' );

   ok( my $rv = $av->elem(0), 'AofA AV has elem[0]' );
   ok( my $av2 = $rv->rv, 'RV has rv' );

   my @outrefs_direct = $av->outrefs_direct;
   is( scalar @outrefs_direct, 1, '$av->outrefs_direct is 1' );
   is( $outrefs_direct[0]->sv,       $rv,           'AV outref[0] SV is $rv' );
   is( $outrefs_direct[0]->strength, "strong",      'AV outref[0] strength is strong' );
   is( $outrefs_direct[0]->name,     "element [0]", 'AV outref[0] name' );

   my @outrefs_indirect = $av->outrefs_indirect;
   is( scalar @outrefs_indirect, 1, '$av->outrefs_indirect is 1' );
   is( $outrefs_indirect[0]->sv,        $av2,                'AV outref[0] SV is $av2' );
   is( $outrefs_indirect[0]->strength, "indirect",           'AV outref[0] strength is indirect' );
   is( $outrefs_indirect[0]->name,     "element [0] via RV", 'AV outref[0] name' );
}

BEGIN { our $LVREF = \substr our $TMPPV = "abc", 1, 2 }
{
   my $sv = $pmat->find_symbol( '$LVREF' );

   ok( my $rv = $sv->rv, 'LVREF SV has RV' );
   is( $rv->lvtype, "x", '$rv->lvtype is x' );
}

BEGIN { our $strongref = []; weaken( our $weakref = $strongref ) }
{
   my $rv_strong = $pmat->find_symbol( '$strongref' );
   my $rv_weak   = $pmat->find_symbol( '$weakref' );

   identical( $rv_strong->rv, $rv_weak->rv, '$strongref and $weakref have same referrant' );

   ok( !$rv_strong->is_weak, '$strongref is not weak' );
   ok(  $rv_weak->is_weak,   '$weakref is weak'       ); # and longcat is long

   my $target = $rv_weak->rv;
   ok( my $backrefs = $target->backrefs, 'Weakref target has backrefs' );
}

# Code hidden in a BEGIN block wouldn't be seen
sub make_closure
{
   my $env; sub { $env };
}
BEGIN { our $CLOSURE = make_closure(); }
{
   my $closure = $pmat->find_symbol( '$CLOSURE' )->rv;

   ok( $closure->is_cloned, '$closure is cloned' );

   my $protosub = $closure->protosub;
   ok( defined $protosub, '$closure has a protosub' );

   ok( $protosub->is_clone,  '$protosub is a clone' );
}

BEGIN { our @QUOTING = ( "1\\2", "don't", "do\0this", "at\x9fhome", "LONG"x100 ); }
{
   my $av = $pmat->find_symbol( '@QUOTING' );

   is_deeply( [ map { $_->qq_pv( 20 ) } $av->elems ],
              [ "'1\\\\2'", "'don\\'t'", '"do\\x00this"', '"at\\x9fhome"', "'LONGLONGLONGLONGLONG'..." ],
              '$sv->qq_pv quotes correctly' );
}

BEGIN {
   our $BYTESTRING = do { no utf8; "\xa0bytes are here" };
   our $UTF8STRING = do { use utf8; "\x{2588}UTF-8 bytes are here" };
}
{
   {
      no utf8;
      my $bytesv = $pmat->find_symbol( '$BYTESTRING' );
      ok( !$bytesv->pv_is_utf8, '$BYTESTRING lacks SvUTF8' );
      ok( $bytesv->pv =~ m/\xa0/, '$BYTESTRING contains \xa0 byte' );
   }

   {
      use utf8;
      my $utf8sv = $pmat->find_symbol( '$UTF8STRING' );
      ok( $utf8sv->pv_is_utf8, '$UTF8STRING has SvUTF8' );
      ok( $utf8sv->pv =~ m/\x{2588}/, '$UTF8STRING contains U+2588' );
   }
}

{
   my $stderr = $pmat->find_glob( 'STDERR' )->io;

   is( $stderr->ofileno, 2, '$stderr has ofileno 2' );
}

{ package Inner; sub method {} }
{
   my $innerstash = $pmat->find_stash( "Inner" );
   is( $innerstash->stashname, "Inner", 'Inner stashname' );

   ok( $innerstash->value( "method" ), 'Inner stash has method' );
}

done_testing;
