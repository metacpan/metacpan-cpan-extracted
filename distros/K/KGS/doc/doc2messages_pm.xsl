<!DOCTYPE xsl:stylesheet>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="text" media-type="text/plain" encoding="utf-8"/>

<xsl:template match="/"><![CDATA[
# This is an automatically generated file. 
# This is an automatically generated file. 
# This is an automatically generated file. 
# This is an automatically generated file. 
# This is an automatically generated file. 

# See doc/protocol.xml and doc/doc2messages_pm.xsl (and doc/Makefile)

package KGS::Messages;

use strict;

our %type;

our %dec_client; # decode messages send to server
our %enc_client; # encode messages send to server
our %dec_server; # decode messages received from server
our %enc_server; # encode messages received from server

{

use Gtk2::GoBoard::Constants; # for MARK_xyz
use Math::BigInt ();

my $data; # stores currently processed decoding/encoding packet

sub _set_data($) { $data = shift } # for debugging or special apps only
sub _get_data() { $data } # for debugging or special apps only

# primitive enc/decoders

#############################################################################

sub dec_U8 {
   (my ($r), $data) = unpack "C a*", $data; $r;
}

sub dec_U16 {
   (my ($r), $data) = unpack "v a*", $data; $r;
}

sub dec_U32 {
   (my ($r), $data) = unpack "V a*", $data; $r;
}

sub dec_U64 {
   # do NOT use Math::BigInt here.
   my ($lo, $hi) = (dec_U32, dec_U32);
   $hi * 2**32 + $lo;
}

sub dec_I8 {
   (my ($r), $data) = unpack "c a*", $data;
   $r;
}

sub dec_I16 {
   (my ($r), $data) = unpack "v a*", $data;
   unpack "s", pack "S", $r;
}

sub dec_I32 {
   (my ($r), $data) = unpack "V a*", $data;
   unpack "i", pack "I", $r;
}

sub dec_DATA {
   (my ($r), $data) = ($data, ""); $r;
}

sub dec_ZSTRING {
   $data =~ s/^((?:..)*?)(?:\x00\x00|\Z)//s;
   # use Encode...
   join "", map chr, unpack "v*", $1;
}

BEGIN { *dec_STRING = \&dec_ZSTRING };

sub dec_CONSTANT {
   $_[0];
}

sub dec_password {
   dec_U64;
}

sub dec_HEX { # for debugging
   "HEX: " . unpack "H*", $data;#d#
}

#############################################################################

sub enc_U8 {
   $data .= pack "C", $_[0];
}

sub enc_U16 {
   $data .= pack "v", $_[0];
}

sub enc_U32 {
   $data .= pack "V", $_[0];
}

sub enc_U64 {
   my $i = new Math::BigInt $_[0];

   enc_U32 $i & 0xffffffff;
   enc_U32 $i >> 32;
}

sub enc_I8 {
   $data .= pack "c", $_[0];
}

sub enc_I16 {
   enc_U16 unpack "S", pack "s", $_[0];
}

sub enc_I32 {
   enc_U32 unpack "I", pack "i", $_[0];
}

sub enc_DATA {
   # a dream!
   $data .= $_[0];
}

sub enc_ZSTRING {
   # should use encode for speed and clarity ;)
   $data .= pack "v*", (map ord, split //, $_[0]), 0;
}

sub enc_STRING {
   # should use encode for speed and clarity ;)
   $data .= pack "v*", map ord, split //, $_[0];
}

sub enc_CONSTANT {
   # nop
}

sub enc_password {
   # $hash must be 64 bit
   my $hash = new Math::BigInt;
   $hash = $hash * 1055 + ord for split //, $_[0];
   enc_U64 $hash & new Math::BigInt "0xffffffffffffffff";
}

sub enc_HEX {
   die "enc_HEX not defined for good";
}

]]>

#############################################################################
# types
<xsl:apply-templates select="descendant::type"/>

#############################################################################
# structures
<xsl:apply-templates select="descendant::struct"/>

#############################################################################
# "less" primitive types<![CDATA[

# this was the most horrible thing to decode. still not everything is decoded correctly(?)
sub dec_TREE {
   my @r;
   my $old_data = $data;#d#
   while (length $data) {
      my $type = dec_U8;
      my $add = $type < 128;

      my $ofs = (length $old_data) - (length $data);#d#

      $type &= 127;

      if ($type == 127) {
         dec_U8; # unused?? *sigh*
         push @r, [add_node => dec_I32];

      } elsif ($type == 126) {
         push @r, [set_node => dec_I32];

      } elsif ($type == 125) {
         push @r, [set_current => dec_I32];

      } elsif ($type == 34) {
         push @r, [score => dec_U8, dec_score32_1000];

      } elsif ($type == 29) {
         push @r, [type_29 => dec_ZSTRING];
         warn "UNKNOWN TREE TYPE 29 $r[-1][1]\007 PLEASE REPORT";#d#
         die;

      } elsif ($type == 28) {
         # move number, only in variations it seems. oh my.
         push @r, [movenum => dec_ZSTRING];

      } elsif ($type == 26) {
         push @r, [type_26 => dec_U8]; # sets a flag (?)
         warn "unknown tree node 26, please ignore\n";
         # possibly marks moves done while editing, as opposed to game-moves(?)

      } elsif ($type == 25) {
         push @r, [result => dec_result];

      } elsif ($type == 23) {
         push @r, [mark => $add, MARK_GRAYED, dec_U8, dec_U8];

      } elsif ($type == 22) {
         push @r, [mark => $add, dec_U8() ? MARK_SMALL_W : MARK_SMALL_B, dec_U8, dec_U8];

      } elsif ($type == 21) {
         push @r, [mark => $add, MARK_SQUARE, dec_U8, dec_U8];

      } elsif ($type == 20) {
         push @r, [mark => $add, MARK_TRIANGLE, dec_U8, dec_U8];

      } elsif ($type == 19) {
         push @r, [mark => $add, MARK_LABEL, dec_U8, dec_U8, dec_ZSTRING];
         #push @r, [unknown_18 => dec_U8, dec_U32, dec_U32, dec_U8, dec_U32, dec_U32, dec_U32];
         #push @r, [set_timer => (dec_U8, dec_U32, dec_time)[0,2,1]];

      } elsif ($type == 18) {
         push @r, [set_timer => (dec_U8, dec_U32, dec_time)[0,2,1]];

      } elsif ($type == 17) {
         push @r, [set_stone => dec_U8, dec_U8, dec_U8];#d#?

#      } elsif ($type == 16) {
#         push @r, [set_stone => dec_U8, dec_U8, dec_U8];#o#

      } elsif ($type == 15) {
         push @r, [mark => $add, MARK_CIRCLE, dec_U8, dec_U8];#d#?

      } elsif ($type == 14) {
         push @r, [move => dec_U8, dec_U8, dec_U8];

      } elsif (($type >= 4 && $type <= 9)
               || ($type >= 11 && $type <= 13)
               || $type == 24) {

         push @r, [({
               4 => "date",
               5 => "unknown_comment5",
               6 => "game_id", #?#
               7 => "unknown_comment7",
               8 => "unknown_comment8",
               9 => "copyright", #?
              11 => "unknown_comment11",
              12 => "unknown_comment12",
              13 => "unknown_comment13",
              24 => "comment",
               })->{$type} => dec_ZSTRING];

      } elsif ($type == 3) {
         push @r, [rank => dec_U8, dec_U32];

      } elsif ($type == 2) {
         push @r, [player => dec_U8, dec_ZSTRING];

      } elsif ($type == 1) {
         push @r, [sgf_name => dec_ZSTRING];

      } elsif ($type == 0) {
         # as usual, wms finds yet another way to duplicate code... oh well, what a mess.
         # (no wonder he is so keen on keeping it a secret...)

         push @r, [rules => dec_rules];

      # OLD

      } else {
         require KGS::Listener::Debug; # hack
         print STDERR KGS::Listener::Debug::dumpval(\@r);
         printf "offset: 0x%04x\n", $ofs;
         open XTYPE, "|xtype"; print XTYPE $old_data; close XTYPE;
         warn "unknown tree type $type, PLEASE REPORT and include the game you wanted to watch. thx.";

      }

      #push @{$r[-1]}, offset => sprintf "0x%x", $ofs;#d#
      
   }
#         print STDERR KGS::Listener::Debug::dumpval(\@r);#d#
#            return [];#d#
   \@r;
}

sub enc_TREE {
   for (@{$_[0]}) {
      my ($type, @arg) = @$_;

      if ($type eq "add_node") {
         enc_U8 127;
         enc_U8 0; # unused?
         enc_I32 $arg[0];

      } elsif ($type eq "set_node") {
         enc_U8 126;
         enc_I32 $arg[0];

      } elsif ($type eq "set_current") {
         enc_U8 125;
         enc_I32 $arg[0];

      } elsif ($type eq "movenum") {
         enc_U8 28;
         enc_ZSTRING $arg[0];

      } elsif ($type eq "set_stone") {
         enc_U8 16;
         enc_U8 $arg[0];
         enc_U8 $arg[1];
         enc_U8 $arg[2];

      } elsif ($type eq "move") {
         enc_U8 14;
         enc_U8 $arg[0];
         enc_U8 $arg[1];
         enc_U8 $arg[2];

      } elsif ($type eq "comment") {
         enc_U8 24;
         enc_ZSTRING $arg[0];

      } elsif ($type eq "mark") {
         my $op = ({
                  &MARK_GRAYED   => 23,
                  &MARK_SMALL_B  => 22,
                  &MARK_SMALL_W  => 22,
                  &MARK_SQUARE   => 21,
                  &MARK_TRIANGLE => 20,
                  &MARK_LABEL    => 19,
                  &MARK_CIRCLE   => 15,
                })->{$arg[1]};

         enc_U8 $op + ($arg[0] ? 0 : 128);
         enc_U8 $arg[1] == MARK_SMALL_W if $op == 22;
         enc_U8 $arg[2];
         enc_U8 $arg[3];

         enc_ZSTRING $arg[4] if $op == 18;

      # unknown types
      } elsif ($type eq "type_29") {
         enc_U8 29;
         enc_ZSTRING $arg[0];
      } elsif ($type eq "type_26") {
         enc_U8 26;
         enc_U8 $arg[0];

      } else {
         warn "unable to encode tree node type $type\n";
      }
   }
};

]]>

#############################################################################
# messages
<xsl:apply-templates select="descendant::message"/>
}

1;
</xsl:template>

<xsl:template match="type[@type = 'S']">
sub dec_<xsl:value-of select="@name"/> {
   my $res = "";
   my @r = unpack "v<xsl:value-of select="@length"/> a*", $data;
   $data = pop @r;
   for (@r) {
      last unless $_;
      $res .= chr $_;
   }
   # dump extra data to file for later analysis
   #my $x = pack "v*", @r; $x =~ s/^(..)*?\x00\x00//s; open DUMP, ">>/root/kgs-dump"; print DUMP $x; close DUMP;#d#
   $res;
}

sub enc_<xsl:value-of select="@name"/> {
   $data .= pack "v<xsl:value-of select="@length"/>", map ord, split //, $_[0];
}
</xsl:template>

<xsl:template match="type[@type = 'A']">
sub dec_<xsl:value-of select="@name"/> {
   (my ($r), $data) = unpack "Z<xsl:value-of select="@length"/> a*", $data; $r;
}

sub enc_<xsl:value-of select="@name"/> {
   $data .= pack "a<xsl:value-of select="@length"/>", $_[0];
}
</xsl:template>

<xsl:template match="type[@multiplier]">
sub dec_<xsl:value-of select="@name"/> {
   (1 / <xsl:value-of select="@multiplier"/>) * dec_<xsl:value-of select="@type"/>;
}

sub enc_<xsl:value-of select="@name"/> {
   enc_<xsl:value-of select="@type"/> $_[0] * <xsl:value-of select="@multiplier"/>;
}
</xsl:template>

<xsl:template match="member[@array = 'yes']" mode="dec">
   $r->{<xsl:value-of select="@name"/>} = (my $array = []);
   while (length $data) {
      push @$array, dec_<xsl:value-of select="@type"/>
                        <xsl:text> </xsl:text>;
   }
</xsl:template>

<xsl:template match="member" mode="dec">
   $r->{<xsl:value-of select="@name"/>} = dec_<xsl:value-of select="@type"/>
                                              <xsl:text> </xsl:text>
                                              <xsl:value-of select="concat('q|',@value,'|')"/>
   <xsl:if test="@guard-cond">
      if ($r->{<xsl:value-of select="@guard-member"/>} <xsl:value-of select="@guard-cond"/>)</xsl:if>
   <xsl:text>;</xsl:text>
</xsl:template>

<xsl:template match="member" mode="enc">
   enc_<xsl:value-of select="@type"/> defined $_[0]{<xsl:value-of select="@name"/>} ? $_[0]{<xsl:value-of select="@name"/>
   <xsl:text>} : (</xsl:text>
   <xsl:value-of select="concat('q|',@value,'|')"/>
   <xsl:text>);</xsl:text>
</xsl:template>

<xsl:template match="struct">
sub dec_<xsl:value-of select="@name"/> {
   my $r = {};
   <xsl:apply-templates select="member" mode="dec"/>
   <xsl:if test="@class">
   bless $r, <xsl:value-of select="@class"/>::;
   </xsl:if>
   $r;
}

sub enc_<xsl:value-of select="@name"/> {
   <xsl:apply-templates select="member" mode="enc"/>
}
</xsl:template>

<xsl:template match="message">
# <xsl:value-of select="@name"/>
$dec_<xsl:value-of select="@src"/>{0x<xsl:value-of select="@type"/>} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "<xsl:value-of select="@name"/>";
   <xsl:apply-templates select="member" mode="dec"/>
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_<xsl:value-of select="@src"/>{<xsl:value-of select="@name"/>} = sub {
   $data = "";
   enc_U16 0x<xsl:value-of select="@type"/>;
   <xsl:apply-templates select="member" mode="enc"/>
   $data;
};
</xsl:template>

<xsl:template match="text()">
</xsl:template>

</xsl:stylesheet>

