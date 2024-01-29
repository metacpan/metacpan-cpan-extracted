#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
BEGIN {
   eval { require Devel::MAT; } or
      plan skip_all => "No Devel::MAT";
   Devel::MAT->VERSION( '0.48' ); # format_sv shows exemplar element

   eval { require Devel::MAT::Dumper; Devel::MAT::Dumper->VERSION( '0.45' ) } or
      plan skip_all => "No Devel::MAT::Dumper version 0.45 or above";
   eval { require Object::Pad; Object::Pad->VERSION( '0.66' ) } or
      plan skip_all => "No Object::Pad version 0.66 or above";

   require Devel::MAT::Dumper;
}

use Commandable::Invocation;

{
   # lexically guard Object::Pad from the code later on
   use Object::Pad;

   class NativeClass
   {
      # one field of each container type
      field $sfield;
      field @afield;
      field %hfield;

      ADJUST {
         $sfield = 123;
         @afield = ( 4, 5, 6 );
         %hfield = ( key => "value" );
      }
   }

   class HashClass :repr(HASH)
   {
      field $x = "HASH";
   }

   package ForeignBase { sub new { bless [], shift } }

   class MagicClass :isa(ForeignBase) :repr(magic)
   {
      field $x = "magic";
   }

   role ARole
   {
      field $rolefield = 789;
   }

   class SubClass :isa(NativeClass) :does(ARole)
   {
      field $morefield = 456;
   }
}

my $nativeobj = NativeClass->new;

my $hashobj = HashClass->new;

my $magicobj = MagicClass->new;

my $subobj = SubClass->new;

( my $file = __FILE__ ) =~ s/\.t$/.pmat/;
Devel::MAT::Dumper::dump( $file );
END { unlink $file if -f $file }

my $pmat = Devel::MAT->load( $file );
my $df = $pmat->dumpfile;

# Boot the tool
$pmat->available_tools;

# TODO: Consider extracting this into some sort of reusable library, maybe even
# into Devel::MAT itself
my $output;
package Devel::MAT::Cmd {
   sub printf {
      shift;
      my ( $fmt, @args ) = @_;
      $output .= sprintf $fmt, @args;
   }
}

sub output_matches_ok(&$$)
{
   my ( $code, $want, $name ) = @_;

   $output = "";
   $code->();

   $want = quotemeta $want;
   $want =~ s/_ADDR_/0x[0-9a-f]+/g;
   $want =~ s/_NUM_/\\d+/g;

   like( $output, qr/^$want$/, $name );
}

# classes command
{
   output_matches_ok {
      $pmat->run_command( Commandable::Invocation->new( "classes" ) );
   } <<'EOF', 'output from "classes" command';
role ARole at C_STRUCT(Object::Pad/ClassMeta.role) at _ADDR_
class HashClass at C_STRUCT(Object::Pad/ClassMeta.class) at _ADDR_
class MagicClass at C_STRUCT(Object::Pad/ClassMeta.class) at _ADDR_
class NativeClass at C_STRUCT(Object::Pad/ClassMeta.class) at _ADDR_
class SubClass at C_STRUCT(Object::Pad/ClassMeta.class) at _ADDR_
EOF
}

# fields
{
   output_matches_ok {
      $pmat->run_command( Commandable::Invocation->new( sprintf "fields 0x%x", 0+$nativeobj ) );
   } <<'EOF', 'output from "fields" command';
The field AV ARRAY(3)=NativeClass at _ADDR_
Ix Field   Value
0  $sfield SCALAR(UV) at _ADDR_ = 123
1  @afield ARRAY(3) at _ADDR_ = [SCALAR(UV) at _ADDR_, ...]
2  %hfield HASH(1) at _ADDR_ = {{key} => SCALAR(PV) at _ADDR_}
EOF

   output_matches_ok {
      $pmat->run_command( Commandable::Invocation->new( sprintf "fields 0x%x", 0+$hashobj ) );
   } <<'EOF', 'output from "fields" command';
The field AV ARRAY(1) at _ADDR_
Ix Field Value
0  $x    SCALAR(PV) at _ADDR_ = "HASH"
EOF

   output_matches_ok {
      $pmat->run_command( Commandable::Invocation->new( sprintf "fields 0x%x", 0+$magicobj ) );
   } <<'EOF', 'output from "fields" command';
The field AV ARRAY(1) at _ADDR_
Ix Field Value
0  $x    SCALAR(PV) at _ADDR_ = "magic"
EOF

   output_matches_ok {
      $pmat->run_command( Commandable::Invocation->new( sprintf "fields 0x%x", 0+$subobj ) );
   } <<'EOF', 'output from "fields" command';
The field AV ARRAY(5)=SubClass at _ADDR_
Ix Field               Value
0  NativeClass/$sfield SCALAR(UV) at _ADDR_ = 123
1  NativeClass/@afield ARRAY(3) at _ADDR_ = [SCALAR(UV) at _ADDR_, ...]
2  NativeClass/%hfield HASH(1) at _ADDR_ = {{key} => SCALAR(PV) at _ADDR_}
3  $morefield          SCALAR(UV) at _ADDR_ = 456
4  ARole/$rolefield    SCALAR(UV) at _ADDR_ = 789
EOF
}

# outrefs override on field AVs
{
   output_matches_ok {
      $pmat->run_command( Commandable::Invocation->new( sprintf "outrefs 0x%x", 0+$subobj ) );
   } <<'EOF', 'output from "outrefs" command on Field AV';
s  the $morefield field           SCALAR(UV) at _ADDR_
s  the ARole/$rolefield field     SCALAR(UV) at _ADDR_
s  the NativeClass/$sfield field  SCALAR(UV) at _ADDR_
s  the NativeClass/%hfield field  REF() at _ADDR_
s  the NativeClass/@afield field  REF() at _ADDR_
EOF

   output_matches_ok {
      $pmat->run_command( Commandable::Invocation->new( sprintf "outrefs 0x%x --all", 0+$subobj ) );
   } <<'EOF', 'output from "outrefs --all" command on Field AV';
s  the $morefield field                  SCALAR(UV) at _ADDR_
s  the ARole/$rolefield field            SCALAR(UV) at _ADDR_
s  the NativeClass/$sfield field         SCALAR(UV) at _ADDR_
s  the NativeClass/%hfield field         REF() at _ADDR_
i  the NativeClass/%hfield field via RV  HASH(1) at _ADDR_
s  the NativeClass/@afield field         REF() at _ADDR_
i  the NativeClass/@afield field via RV  ARRAY(3) at _ADDR_
w  the bless package                     STASH(_NUM_) at _ADDR_
EOF
}

done_testing;
