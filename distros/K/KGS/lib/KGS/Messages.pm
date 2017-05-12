
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



#############################################################################
# types

sub dec_username {
   (my ($r), $data) = unpack "Z10 a*", $data; $r;
}

sub enc_username {
   $data .= pack "a10", $_[0];
}

sub dec_roomname {
   my $res = "";
   my @r = unpack "v25 a*", $data;
   $data = pop @r;
   for (@r) {
      last unless $_;
      $res .= chr $_;
   }
   # dump extra data to file for later analysis
   #my $x = pack "v*", @r; $x =~ s/^(..)*?\x00\x00//s; open DUMP, ">>/root/kgs-dump"; print DUMP $x; close DUMP;#d#
   $res;
}

sub enc_roomname {
   $data .= pack "v25", map ord, split //, $_[0];
}

sub dec_realname {
   my $res = "";
   my @r = unpack "v50 a*", $data;
   $data = pop @r;
   for (@r) {
      last unless $_;
      $res .= chr $_;
   }
   # dump extra data to file for later analysis
   #my $x = pack "v*", @r; $x =~ s/^(..)*?\x00\x00//s; open DUMP, ">>/root/kgs-dump"; print DUMP $x; close DUMP;#d#
   $res;
}

sub enc_realname {
   $data .= pack "v50", map ord, split //, $_[0];
}

sub dec_email {
   my $res = "";
   my @r = unpack "v70 a*", $data;
   $data = pop @r;
   for (@r) {
      last unless $_;
      $res .= chr $_;
   }
   # dump extra data to file for later analysis
   #my $x = pack "v*", @r; $x =~ s/^(..)*?\x00\x00//s; open DUMP, ">>/root/kgs-dump"; print DUMP $x; close DUMP;#d#
   $res;
}

sub enc_email {
   $data .= pack "v70", map ord, split //, $_[0];
}

sub dec_userinfo {
   my $res = "";
   my @r = unpack "v1000 a*", $data;
   $data = pop @r;
   for (@r) {
      last unless $_;
      $res .= chr $_;
   }
   # dump extra data to file for later analysis
   #my $x = pack "v*", @r; $x =~ s/^(..)*?\x00\x00//s; open DUMP, ">>/root/kgs-dump"; print DUMP $x; close DUMP;#d#
   $res;
}

sub enc_userinfo {
   $data .= pack "v1000", map ord, split //, $_[0];
}

sub dec_url {
   (my ($r), $data) = unpack "Z100 a*", $data; $r;
}

sub enc_url {
   $data .= pack "a100", $_[0];
}

sub dec_locale {
   (my ($r), $data) = unpack "Z5 a*", $data; $r;
}

sub enc_locale {
   $data .= pack "a5", $_[0];
}

sub dec_flag {
   (1 / 1) * dec_U8;
}

sub enc_flag {
   enc_U8 $_[0] * 1;
}

sub dec_komi16_2 {
   (1 / 2) * dec_I16;
}

sub enc_komi16_2 {
   enc_I16 $_[0] * 2;
}

sub dec_komi16_4 {
   (1 / 4) * dec_I16;
}

sub enc_komi16_4 {
   enc_I16 $_[0] * 4;
}

sub dec_komi32_2 {
   (1 / 2) * dec_I32;
}

sub enc_komi32_2 {
   enc_I32 $_[0] * 2;
}

sub dec_komi32_4 {
   (1 / 4) * dec_I32;
}

sub enc_komi32_4 {
   enc_I32 $_[0] * 4;
}

sub dec_result {
   (1 / 2) * dec_I32;
}

sub enc_result {
   enc_I32 $_[0] * 2;
}

sub dec_score16_2 {
   (1 / 2) * dec_I16;
}

sub enc_score16_2 {
   enc_I16 $_[0] * 2;
}

sub dec_score16_4 {
   (1 / 4) * dec_I16;
}

sub enc_score16_4 {
   enc_I16 $_[0] * 4;
}

sub dec_score32_4 {
   (1 / 4) * dec_I32;
}

sub enc_score32_4 {
   enc_I32 $_[0] * 4;
}

sub dec_score32_1000 {
   (1 / 1000) * dec_I32;
}

sub enc_score32_1000 {
   enc_I32 $_[0] * 1000;
}

sub dec_time {
   (1 / 1000) * dec_U32;
}

sub enc_time {
   enc_U32 $_[0] * 1000;
}

sub dec_timestamp {
   (1 / 1000) * dec_U64;
}

sub enc_timestamp {
   enc_U64 $_[0] * 1000;
}

sub dec_CLIENTID16 {
   (1 / 1) * dec_U16;
}

sub enc_CLIENTID16 {
   enc_U16 $_[0] * 1;
}

sub dec_CLIENTID8 {
   (1 / 1) * dec_U8;
}

sub enc_CLIENTID8 {
   enc_U8 $_[0] * 1;
}


#############################################################################
# structures

sub dec_message_header {
   my $r = {};
   
   $r->{length} = dec_U16 q||;
   $r->{type} = dec_U16 q||;
   $r;
}

sub enc_message_header {
   
   enc_U16 defined $_[0]{length} ? $_[0]{length} : (q||);
   enc_U16 defined $_[0]{type} ? $_[0]{type} : (q||);
}

sub dec_user {
   my $r = {};
   
   $r->{name} = dec_username q||;
   $r->{flags} = dec_U32 q|1|;
   bless $r, KGS::User::;
   
   $r;
}

sub enc_user {
   
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_U32 defined $_[0]{flags} ? $_[0]{flags} : (q|1|);
}

sub dec_rules {
   my $r = {};
   
   $r->{ruleset} = dec_U8 q||;
   $r->{size} = dec_U8 q||;
   $r->{handicap} = dec_U8 q||;
   $r->{komi} = dec_komi16_2 q||;
   $r->{timesys} = dec_U8 q||;
   $r->{time} = dec_U32 q||;
   $r->{interval} = dec_U32 q||;
   $r->{count} = dec_U16 q||;
   bless $r, KGS::Rules::;
   
   $r;
}

sub enc_rules {
   
   enc_U8 defined $_[0]{ruleset} ? $_[0]{ruleset} : (q||);
   enc_U8 defined $_[0]{size} ? $_[0]{size} : (q||);
   enc_U8 defined $_[0]{handicap} ? $_[0]{handicap} : (q||);
   enc_komi16_2 defined $_[0]{komi} ? $_[0]{komi} : (q||);
   enc_U8 defined $_[0]{timesys} ? $_[0]{timesys} : (q||);
   enc_U32 defined $_[0]{time} ? $_[0]{time} : (q||);
   enc_U32 defined $_[0]{interval} ? $_[0]{interval} : (q||);
   enc_U16 defined $_[0]{count} ? $_[0]{count} : (q||);
}

sub dec_challenge_defaults {
   my $r = {};
   
   $r->{gametype} = dec_U8 q||;
   $r->{ruleset} = dec_U8 q||;
   $r->{size} = dec_U32 q||;
   $r->{timesys} = dec_U32 q||;
   $r->{time} = dec_U32 q||;
   $r->{byo_time} = dec_U32 q||;
   $r->{byo_periods} = dec_U32 q||;
   $r->{can_time} = dec_U32 q||;
   $r->{can_stones} = dec_U32 q||;
   $r->{notes} = dec_STRING q||;
   $r;
}

sub enc_challenge_defaults {
   
   enc_U8 defined $_[0]{gametype} ? $_[0]{gametype} : (q||);
   enc_U8 defined $_[0]{ruleset} ? $_[0]{ruleset} : (q||);
   enc_U32 defined $_[0]{size} ? $_[0]{size} : (q||);
   enc_U32 defined $_[0]{timesys} ? $_[0]{timesys} : (q||);
   enc_U32 defined $_[0]{time} ? $_[0]{time} : (q||);
   enc_U32 defined $_[0]{byo_time} ? $_[0]{byo_time} : (q||);
   enc_U32 defined $_[0]{byo_periods} ? $_[0]{byo_periods} : (q||);
   enc_U32 defined $_[0]{can_time} ? $_[0]{can_time} : (q||);
   enc_U32 defined $_[0]{can_stones} ? $_[0]{can_stones} : (q||);
   enc_STRING defined $_[0]{notes} ? $_[0]{notes} : (q||);
}

sub dec_game {
   my $r = {};
   
   $r->{channel} = dec_U16 q||;
   $r->{type} = dec_U8 q||;
   $r->{black} = dec_user q||;
   $r->{white} = dec_user q||;
   $r->{owner} = dec_user q||;
   $r->{size} = dec_U8 q||;
   $r->{handicap} = dec_I8 q||;
   $r->{komi} = dec_komi16_2 q||;
   $r->{moves} = dec_I16 q||;
   $r->{flags} = dec_U16 q||;
   $r->{observers} = dec_U32 q||;
   $r->{saved} = dec_flag q||;
   $r->{notes} = dec_ZSTRING q||
      if ($r->{handicap} < 0);
   bless $r, KGS::Game::;
   
   $r;
}

sub enc_game {
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_U8 defined $_[0]{type} ? $_[0]{type} : (q||);
   enc_user defined $_[0]{black} ? $_[0]{black} : (q||);
   enc_user defined $_[0]{white} ? $_[0]{white} : (q||);
   enc_user defined $_[0]{owner} ? $_[0]{owner} : (q||);
   enc_U8 defined $_[0]{size} ? $_[0]{size} : (q||);
   enc_I8 defined $_[0]{handicap} ? $_[0]{handicap} : (q||);
   enc_komi16_2 defined $_[0]{komi} ? $_[0]{komi} : (q||);
   enc_I16 defined $_[0]{moves} ? $_[0]{moves} : (q||);
   enc_U16 defined $_[0]{flags} ? $_[0]{flags} : (q||);
   enc_U32 defined $_[0]{observers} ? $_[0]{observers} : (q||);
   enc_flag defined $_[0]{saved} ? $_[0]{saved} : (q||);
   enc_ZSTRING defined $_[0]{notes} ? $_[0]{notes} : (q||);
}

sub dec_room_game {
   my $r = {};
   
   $r->{channel} = dec_U16 q||;
   $r->{game} = dec_game q||;
   $r;
}

sub enc_room_game {
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_game defined $_[0]{game} ? $_[0]{game} : (q||);
}

sub dec_room_obs {
   my $r = {};
   
   $r->{name} = dec_roomname q||;
   $r->{channel} = dec_U16 q||;
   $r->{flags} = dec_U32 q||;
   $r->{users} = dec_U32 q||;
   $r;
}

sub enc_room_obs {
   
   enc_roomname defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_U32 defined $_[0]{flags} ? $_[0]{flags} : (q||);
   enc_U32 defined $_[0]{users} ? $_[0]{users} : (q||);
}

sub dec_room {
   my $r = {};
   
   $r->{channel} = dec_U16 q||;
   $r->{flags} = dec_U8 q||;
   $r->{group} = dec_U8 q||;
   $r->{users} = dec_U16 q||;
   $r->{games} = dec_U16 q||;
   $r->{name} = dec_STRING q||;
   bless $r, KGS::Room::;
   
   $r;
}

sub enc_room {
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_U8 defined $_[0]{flags} ? $_[0]{flags} : (q||);
   enc_U8 defined $_[0]{group} ? $_[0]{group} : (q||);
   enc_U16 defined $_[0]{users} ? $_[0]{users} : (q||);
   enc_U16 defined $_[0]{games} ? $_[0]{games} : (q||);
   enc_STRING defined $_[0]{name} ? $_[0]{name} : (q||);
}

sub dec_scorevalues {
   my $r = {};
   
   $r->{score} = dec_score32_4 q||;
   $r->{territory} = dec_U32 q||;
   $r->{captures} = dec_U32 q||;
   $r->{i3} = dec_U32 q||;
   $r->{f2} = dec_U32 q||;
   $r->{komi} = dec_komi32_4 q||;
   $r->{i4} = dec_U32 q||;
   bless $r, KGS::Score::;
   
   $r;
}

sub enc_scorevalues {
   
   enc_score32_4 defined $_[0]{score} ? $_[0]{score} : (q||);
   enc_U32 defined $_[0]{territory} ? $_[0]{territory} : (q||);
   enc_U32 defined $_[0]{captures} ? $_[0]{captures} : (q||);
   enc_U32 defined $_[0]{i3} ? $_[0]{i3} : (q||);
   enc_U32 defined $_[0]{f2} ? $_[0]{f2} : (q||);
   enc_komi32_4 defined $_[0]{komi} ? $_[0]{komi} : (q||);
   enc_U32 defined $_[0]{i4} ? $_[0]{i4} : (q||);
}

sub dec_game_record {
   my $r = {};
   
   $r->{timestamp} = dec_timestamp q||;
   $r->{type} = dec_U8 q||;
   $r->{handicap} = dec_U8 q||;
   $r->{revision} = dec_U16 q||;
   $r->{black} = dec_user q||;
   $r->{white} = dec_user q||;
   $r->{owner} = dec_user q||;
   $r->{komi} = dec_U16 q||;
   $r->{score} = dec_score16_2 q||;
   $r->{size} = dec_U8 q||;
   $r->{flags} = dec_U8 q||;
   bless $r, KGS::GameRecord::;
   
   $r;
}

sub enc_game_record {
   
   enc_timestamp defined $_[0]{timestamp} ? $_[0]{timestamp} : (q||);
   enc_U8 defined $_[0]{type} ? $_[0]{type} : (q||);
   enc_U8 defined $_[0]{handicap} ? $_[0]{handicap} : (q||);
   enc_U16 defined $_[0]{revision} ? $_[0]{revision} : (q||);
   enc_user defined $_[0]{black} ? $_[0]{black} : (q||);
   enc_user defined $_[0]{white} ? $_[0]{white} : (q||);
   enc_user defined $_[0]{owner} ? $_[0]{owner} : (q||);
   enc_U16 defined $_[0]{komi} ? $_[0]{komi} : (q||);
   enc_score16_2 defined $_[0]{score} ? $_[0]{score} : (q||);
   enc_U8 defined $_[0]{size} ? $_[0]{size} : (q||);
   enc_U8 defined $_[0]{flags} ? $_[0]{flags} : (q||);
}


#############################################################################
# "less" primitive types

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



#############################################################################
# messages

# login
$dec_client{0x0000} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "login";
   
   $r->{ver_major} = dec_U32 q|2|;
   $r->{ver_minor} = dec_U32 q|6|;
   $r->{ver_micro} = dec_U32 q|1|;
   $r->{name} = dec_username q||;
   $r->{password} = dec_password q|0|;
   $r->{guest} = dec_flag q|1|;
   $r->{_unknown3} = dec_U16 q|0|;
   $r->{locale} = dec_locale q|"en_US"|;
   $r->{clientver} = dec_DATA q|"1.4.2_03:Swing app:Sun Microsystems Inc."|;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{login} = sub {
   $data = "";
   enc_U16 0x0000;
   
   enc_U32 defined $_[0]{ver_major} ? $_[0]{ver_major} : (q|2|);
   enc_U32 defined $_[0]{ver_minor} ? $_[0]{ver_minor} : (q|6|);
   enc_U32 defined $_[0]{ver_micro} ? $_[0]{ver_micro} : (q|1|);
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_password defined $_[0]{password} ? $_[0]{password} : (q|0|);
   enc_flag defined $_[0]{guest} ? $_[0]{guest} : (q|1|);
   enc_U16 defined $_[0]{_unknown3} ? $_[0]{_unknown3} : (q|0|);
   enc_locale defined $_[0]{locale} ? $_[0]{locale} : (q|"en_US"|);
   enc_DATA defined $_[0]{clientver} ? $_[0]{clientver} : (q|"1.4.2_03:Swing app:Sun Microsystems Inc."|);
   $data;
};

# req_userinfo
$dec_client{0x0007} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "req_userinfo";
   
   $r->{name} = dec_username q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{req_userinfo} = sub {
   $data = "";
   enc_U16 0x0007;
   
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   $data;
};

# update_userinfo
$dec_client{0x0007} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "update_userinfo";
   
   $r->{setpass} = dec_flag q||;
   $r->{password} = dec_password q|0|;
   $r->{realname} = dec_realname q||;
   $r->{email} = dec_email q||;
   $r->{info} = dec_userinfo q||;
   $r->{homepage} = dec_url q||;
   $r->{_unused} = dec_U64 q|0|;
   $r->{_unused} = dec_U64 q|0|;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{update_userinfo} = sub {
   $data = "";
   enc_U16 0x0007;
   
   enc_flag defined $_[0]{setpass} ? $_[0]{setpass} : (q||);
   enc_password defined $_[0]{password} ? $_[0]{password} : (q|0|);
   enc_realname defined $_[0]{realname} ? $_[0]{realname} : (q||);
   enc_email defined $_[0]{email} ? $_[0]{email} : (q||);
   enc_userinfo defined $_[0]{info} ? $_[0]{info} : (q||);
   enc_url defined $_[0]{homepage} ? $_[0]{homepage} : (q||);
   enc_U64 defined $_[0]{_unused} ? $_[0]{_unused} : (q|0|);
   enc_U64 defined $_[0]{_unused} ? $_[0]{_unused} : (q|0|);
   $data;
};

# msg_chat
$dec_client{0x0013} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "msg_chat";
   
   $r->{name} = dec_username q||;
   $r->{name2} = dec_username q||;
   $r->{message} = dec_STRING q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{msg_chat} = sub {
   $data = "";
   enc_U16 0x0013;
   
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_username defined $_[0]{name2} ? $_[0]{name2} : (q||);
   enc_STRING defined $_[0]{message} ? $_[0]{message} : (q||);
   $data;
};

# req_stats
$dec_client{0x0014} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "req_stats";
   
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{req_stats} = sub {
   $data = "";
   enc_U16 0x0014;
   
   $data;
};

# idle_reset
$dec_client{0x0016} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "idle_reset";
   
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{idle_reset} = sub {
   $data = "";
   enc_U16 0x0016;
   
   $data;
};

# ping
$dec_client{0x001d} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "ping";
   
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{ping} = sub {
   $data = "";
   enc_U16 0x001d;
   
   $data;
};

# req_usergraph
$dec_client{0x001e} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "req_usergraph";
   
   $r->{name} = dec_username q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{req_usergraph} = sub {
   $data = "";
   enc_U16 0x001e;
   
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   $data;
};

# req_pic
$dec_client{0x0021} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "req_pic";
   
   $r->{name} = dec_username q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{req_pic} = sub {
   $data = "";
   enc_U16 0x0021;
   
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   $data;
};

# upload_pic
$dec_client{0x0021} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "upload_pic";
   
   $r->{name} = dec_username q||;
   $r->{data} = dec_DATA q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{upload_pic} = sub {
   $data = "";
   enc_U16 0x0021;
   
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_DATA defined $_[0]{data} ? $_[0]{data} : (q||);
   $data;
};

# send_memo
$dec_client{0x0023} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "send_memo";
   
   $r->{name} = dec_username q||;
   $r->{cid} = dec_CLIENTID16 q||;
   $r->{msg} = dec_STRING q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{send_memo} = sub {
   $data = "";
   enc_U16 0x0023;
   
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_CLIENTID16 defined $_[0]{cid} ? $_[0]{cid} : (q||);
   enc_STRING defined $_[0]{msg} ? $_[0]{msg} : (q||);
   $data;
};

# delete_memos
$dec_client{0x0024} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "delete_memos";
   
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{delete_memos} = sub {
   $data = "";
   enc_U16 0x0024;
   
   $data;
};

# gnotice
$dec_client{0x0100} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "gnotice";
   
   $r->{notice} = dec_STRING q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{gnotice} = sub {
   $data = "";
   enc_U16 0x0100;
   
   enc_STRING defined $_[0]{notice} ? $_[0]{notice} : (q||);
   $data;
};

# notify_add
$dec_client{0x0200} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "notify_add";
   
   $r->{name} = dec_username q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{notify_add} = sub {
   $data = "";
   enc_U16 0x0200;
   
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   $data;
};

# notify_del
$dec_client{0x0201} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "notify_del";
   
   $r->{name} = dec_username q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{notify_del} = sub {
   $data = "";
   enc_U16 0x0201;
   
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   $data;
};

# list_rooms
$dec_client{0x0318} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "list_rooms";
   
   $r->{group} = dec_U8 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{list_rooms} = sub {
   $data = "";
   enc_U16 0x0318;
   
   enc_U8 defined $_[0]{group} ? $_[0]{group} : (q||);
   $data;
};

# new_room
$dec_client{0x031a} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "new_room";
   
   $r->{name} = dec_username q||;
   $r->{i1} = dec_U32 q|0|;
   $r->{b1} = dec_U8 q|0|;
   $r->{b2} = dec_U8 q|255|;
   $r->{b3} = dec_U8 q|255|;
   $r->{group} = dec_U8 q|1|;
   $r->{name} = dec_ZSTRING q||;
   $r->{description} = dec_ZSTRING q||;
   $r->{flags} = dec_U8 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{new_room} = sub {
   $data = "";
   enc_U16 0x031a;
   
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_U32 defined $_[0]{i1} ? $_[0]{i1} : (q|0|);
   enc_U8 defined $_[0]{b1} ? $_[0]{b1} : (q|0|);
   enc_U8 defined $_[0]{b2} ? $_[0]{b2} : (q|255|);
   enc_U8 defined $_[0]{b3} ? $_[0]{b3} : (q|255|);
   enc_U8 defined $_[0]{group} ? $_[0]{group} : (q|1|);
   enc_ZSTRING defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_ZSTRING defined $_[0]{description} ? $_[0]{description} : (q||);
   enc_U8 defined $_[0]{flags} ? $_[0]{flags} : (q||);
   $data;
};

# req_upd_rooms
$dec_client{0x031b} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "req_upd_rooms";
   
   $r->{channel} = dec_U16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{req_upd_rooms} = sub {
   $data = "";
   enc_U16 0x031b;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   $data;
};

# req_game_record
$dec_client{0x0413} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "req_game_record";
   
   $r->{name} = dec_username q||;
   $r->{timestamp} = dec_timestamp q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{req_game_record} = sub {
   $data = "";
   enc_U16 0x0413;
   
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_timestamp defined $_[0]{timestamp} ? $_[0]{timestamp} : (q||);
   $data;
};

# join_room
$dec_client{0x4300} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "join_room";
   
   $r->{channel} = dec_U16 q||;
   $r->{user} = dec_user q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{join_room} = sub {
   $data = "";
   enc_U16 0x4300;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_user defined $_[0]{user} ? $_[0]{user} : (q||);
   $data;
};

# msg_room
$dec_client{0x4301} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "msg_room";
   
   $r->{channel} = dec_U16 q||;
   $r->{name} = dec_username q||;
   $r->{message} = dec_STRING q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{msg_room} = sub {
   $data = "";
   enc_U16 0x4301;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_STRING defined $_[0]{message} ? $_[0]{message} : (q||);
   $data;
};

# part_room
$dec_client{0x4302} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "part_room";
   
   $r->{channel} = dec_U16 q||;
   $r->{name} = dec_username q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{part_room} = sub {
   $data = "";
   enc_U16 0x4302;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   $data;
};

# new_game
$dec_client{0x4305} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "new_game";
   
   $r->{channel} = dec_U16 q||;
   $r->{cid} = dec_CLIENTID16 q||;
   $r->{gametype} = dec_U8 q||;
   $r->{flags} = dec_U8 q||;
   $r->{rules} = dec_rules q||;
   $r->{notes} = dec_STRING q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{new_game} = sub {
   $data = "";
   enc_U16 0x4305;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_CLIENTID16 defined $_[0]{cid} ? $_[0]{cid} : (q||);
   enc_U8 defined $_[0]{gametype} ? $_[0]{gametype} : (q||);
   enc_U8 defined $_[0]{flags} ? $_[0]{flags} : (q||);
   enc_rules defined $_[0]{rules} ? $_[0]{rules} : (q||);
   enc_STRING defined $_[0]{notes} ? $_[0]{notes} : (q||);
   $data;
};

# load_game
$dec_client{0x430a} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "load_game";
   
   $r->{channel} = dec_U16 q||;
   $r->{timestamp} = dec_timestamp q||;
   $r->{user} = dec_username q||;
   $r->{flags} = dec_U8 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{load_game} = sub {
   $data = "";
   enc_U16 0x430a;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_timestamp defined $_[0]{timestamp} ? $_[0]{timestamp} : (q||);
   enc_username defined $_[0]{user} ? $_[0]{user} : (q||);
   enc_U8 defined $_[0]{flags} ? $_[0]{flags} : (q||);
   $data;
};

# req_games
$dec_client{0x430b} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "req_games";
   
   $r->{channel} = dec_U16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{req_games} = sub {
   $data = "";
   enc_U16 0x430b;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   $data;
};

# req_desc
$dec_client{0x4319} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "req_desc";
   
   $r->{channel} = dec_U16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{req_desc} = sub {
   $data = "";
   enc_U16 0x4319;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   $data;
};

# challenge
$dec_client{0x4400} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "challenge";
   
   $r->{channel} = dec_U16 q||;
   $r->{black} = dec_user q||;
   $r->{white} = dec_user q||;
   $r->{gametype} = dec_U8 q||;
   $r->{cid} = dec_CLIENTID8 q||;
   $r->{rules} = dec_rules q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{challenge} = sub {
   $data = "";
   enc_U16 0x4400;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_user defined $_[0]{black} ? $_[0]{black} : (q||);
   enc_user defined $_[0]{white} ? $_[0]{white} : (q||);
   enc_U8 defined $_[0]{gametype} ? $_[0]{gametype} : (q||);
   enc_CLIENTID8 defined $_[0]{cid} ? $_[0]{cid} : (q||);
   enc_rules defined $_[0]{rules} ? $_[0]{rules} : (q||);
   $data;
};

# join_game
$dec_client{0x4403} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "join_game";
   
   $r->{channel} = dec_U16 q||;
   $r->{user} = dec_user q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{join_game} = sub {
   $data = "";
   enc_U16 0x4403;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_user defined $_[0]{user} ? $_[0]{user} : (q||);
   $data;
};

# part_game
$dec_client{0x4404} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "part_game";
   
   $r->{channel} = dec_U16 q||;
   $r->{name} = dec_username q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{part_game} = sub {
   $data = "";
   enc_U16 0x4404;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   $data;
};

# set_tree
$dec_client{0x4405} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "set_tree";
   
   $r->{channel} = dec_U16 q||;
   $r->{tree} = dec_TREE q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{set_tree} = sub {
   $data = "";
   enc_U16 0x4405;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_TREE defined $_[0]{tree} ? $_[0]{tree} : (q||);
   $data;
};

# upd_tree
$dec_client{0x4406} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "upd_tree";
   
   $r->{channel} = dec_U16 q||;
   $r->{tree} = dec_TREE q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{upd_tree} = sub {
   $data = "";
   enc_U16 0x4406;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_TREE defined $_[0]{tree} ? $_[0]{tree} : (q||);
   $data;
};

# mark_dead
$dec_client{0x4407} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "mark_dead";
   
   $r->{channel} = dec_U16 q||;
   $r->{x} = dec_U8 q||;
   $r->{y} = dec_U8 q||;
   $r->{dead} = dec_flag q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{mark_dead} = sub {
   $data = "";
   enc_U16 0x4407;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_U8 defined $_[0]{x} ? $_[0]{x} : (q||);
   enc_U8 defined $_[0]{y} ? $_[0]{y} : (q||);
   enc_flag defined $_[0]{dead} ? $_[0]{dead} : (q||);
   $data;
};

# get_tree
$dec_client{0x4408} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "get_tree";
   
   $r->{channel} = dec_U16 q||;
   $r->{node} = dec_U32 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{get_tree} = sub {
   $data = "";
   enc_U16 0x4408;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_U32 defined $_[0]{node} ? $_[0]{node} : (q||);
   $data;
};

# game_done
$dec_client{0x440a} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "game_done";
   
   $r->{channel} = dec_U16 q||;
   $r->{id} = dec_U32 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{game_done} = sub {
   $data = "";
   enc_U16 0x440a;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_U32 defined $_[0]{id} ? $_[0]{id} : (q||);
   $data;
};

# claim_win
$dec_client{0x440c} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "claim_win";
   
   $r->{channel} = dec_U16 q||;
   $r->{player} = dec_U8  q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{claim_win} = sub {
   $data = "";
   enc_U16 0x440c;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_U8  defined $_[0]{player} ? $_[0]{player} : (q||);
   $data;
};

# add_time
$dec_client{0x440d} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "add_time";
   
   $r->{channel} = dec_U16 q||;
   $r->{time} = dec_U32 q||;
   $r->{player} = dec_U8 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{add_time} = sub {
   $data = "";
   enc_U16 0x440d;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_U32 defined $_[0]{time} ? $_[0]{time} : (q||);
   enc_U8 defined $_[0]{player} ? $_[0]{player} : (q||);
   $data;
};

# req_undo
$dec_client{0x440e} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "req_undo";
   
   $r->{channel} = dec_U16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{req_undo} = sub {
   $data = "";
   enc_U16 0x440e;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   $data;
};

# grant_undo
$dec_client{0x440f} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "grant_undo";
   
   $r->{channel} = dec_U16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{grant_undo} = sub {
   $data = "";
   enc_U16 0x440f;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   $data;
};

# resign_game
$dec_client{0x4410} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "resign_game";
   
   $r->{channel} = dec_U16 q||;
   $r->{player} = dec_U8 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{resign_game} = sub {
   $data = "";
   enc_U16 0x4410;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_U8 defined $_[0]{player} ? $_[0]{player} : (q||);
   $data;
};

# set_teacher
$dec_client{0x441a} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "set_teacher";
   
   $r->{channel} = dec_U16 q||;
   $r->{name} = dec_username q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{set_teacher} = sub {
   $data = "";
   enc_U16 0x441a;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   $data;
};

# allow_user
$dec_client{0x4422} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "allow_user";
   
   $r->{channel} = dec_U16 q||;
   $r->{othername} = dec_username q||;
   $r->{name} = dec_username q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{allow_user} = sub {
   $data = "";
   enc_U16 0x4422;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_username defined $_[0]{othername} ? $_[0]{othername} : (q||);
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   $data;
};

# set_privacy
$dec_client{0x4423} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "set_privacy";
   
   $r->{channel} = dec_U16 q||;
   $r->{private} = dec_flag q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{set_privacy} = sub {
   $data = "";
   enc_U16 0x4423;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_flag defined $_[0]{private} ? $_[0]{private} : (q||);
   $data;
};

# game_move
$dec_client{0x4427} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "game_move";
   
   $r->{channel} = dec_U16 q||;
   $r->{x} = dec_U8 q||;
   $r->{y} = dec_U8 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{game_move} = sub {
   $data = "";
   enc_U16 0x4427;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_U8 defined $_[0]{x} ? $_[0]{x} : (q||);
   enc_U8 defined $_[0]{y} ? $_[0]{y} : (q||);
   $data;
};

# reject_challenge
$dec_client{0x4429} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "reject_challenge";
   
   $r->{channel} = dec_U16 q||;
   $r->{name} = dec_username q||;
   $r->{gametype} = dec_U8 q||;
   $r->{cid} = dec_CLIENTID8 q||;
   $r->{rules} = dec_rules q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{reject_challenge} = sub {
   $data = "";
   enc_U16 0x4429;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_U8 defined $_[0]{gametype} ? $_[0]{gametype} : (q||);
   enc_CLIENTID8 defined $_[0]{cid} ? $_[0]{cid} : (q||);
   enc_rules defined $_[0]{rules} ? $_[0]{rules} : (q||);
   $data;
};

# more_comments
$dec_client{0x442d} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "more_comments";
   
   $r->{channel} = dec_U16 q||;
   $r->{node} = dec_U32 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{more_comments} = sub {
   $data = "";
   enc_U16 0x442d;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_U32 defined $_[0]{node} ? $_[0]{node} : (q||);
   $data;
};

# save_game
$dec_client{0x442e} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "save_game";
   
   $r->{channel} = dec_U16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{save_game} = sub {
   $data = "";
   enc_U16 0x442e;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   $data;
};

# req_result
$dec_client{0x4433} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "req_result";
   
   $r->{channel} = dec_U16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{req_result} = sub {
   $data = "";
   enc_U16 0x4433;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   $data;
};

# set_quiet
$dec_client{0x4434} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "set_quiet";
   
   $r->{channel} = dec_U16 q||;
   $r->{quiet} = dec_flag q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{set_quiet} = sub {
   $data = "";
   enc_U16 0x4434;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_flag defined $_[0]{quiet} ? $_[0]{quiet} : (q||);
   $data;
};

# msg_game
$dec_client{0x4436} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "msg_game";
   
   $r->{channel} = dec_U16 q||;
   $r->{message} = dec_STRING q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{msg_game} = sub {
   $data = "";
   enc_U16 0x4436;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_STRING defined $_[0]{message} ? $_[0]{message} : (q||);
   $data;
};

# quit
$dec_client{0xffff} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "quit";
   
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_client{quit} = sub {
   $data = "";
   enc_U16 0xffff;
   
   $data;
};

# login
$dec_server{0x0001} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "login";
   
   $r->{message} = dec_CONSTANT q|login successful|;
   $r->{success} = dec_CONSTANT q|1|;
   $r->{user} = dec_user q||;
   $r->{unknown1} = dec_U16 q||;
   $r->{unknown2} = dec_U16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{login} = sub {
   $data = "";
   enc_U16 0x0001;
   
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|login successful|);
   enc_CONSTANT defined $_[0]{success} ? $_[0]{success} : (q|1|);
   enc_user defined $_[0]{user} ? $_[0]{user} : (q||);
   enc_U16 defined $_[0]{unknown1} ? $_[0]{unknown1} : (q||);
   enc_U16 defined $_[0]{unknown2} ? $_[0]{unknown2} : (q||);
   $data;
};

# login
$dec_server{0x0002} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "login";
   
   $r->{message} = dec_CONSTANT q|login successful: client version is outdated.|;
   $r->{success} = dec_CONSTANT q|1|;
   $r->{user} = dec_user q||;
   $r->{unknown1} = dec_U16 q||;
   $r->{unknown2} = dec_U16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{login} = sub {
   $data = "";
   enc_U16 0x0002;
   
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|login successful: client version is outdated.|);
   enc_CONSTANT defined $_[0]{success} ? $_[0]{success} : (q|1|);
   enc_user defined $_[0]{user} ? $_[0]{user} : (q||);
   enc_U16 defined $_[0]{unknown1} ? $_[0]{unknown1} : (q||);
   enc_U16 defined $_[0]{unknown2} ? $_[0]{unknown2} : (q||);
   $data;
};

# login
$dec_server{0x0003} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "login";
   
   $r->{message} = dec_CONSTANT q|login failed: client version out of date|;
   $r->{user} = dec_user q||;
   $r->{unknown1} = dec_U16 q||;
   $r->{unknown2} = dec_U16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{login} = sub {
   $data = "";
   enc_U16 0x0003;
   
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|login failed: client version out of date|);
   enc_user defined $_[0]{user} ? $_[0]{user} : (q||);
   enc_U16 defined $_[0]{unknown1} ? $_[0]{unknown1} : (q||);
   enc_U16 defined $_[0]{unknown2} ? $_[0]{unknown2} : (q||);
   $data;
};

# login
$dec_server{0x0004} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "login";
   
   $r->{message} = dec_CONSTANT q|login failed: wrong password|;
   $r->{user} = dec_user q||;
   $r->{unknown1} = dec_U16 q||;
   $r->{unknown2} = dec_U16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{login} = sub {
   $data = "";
   enc_U16 0x0004;
   
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|login failed: wrong password|);
   enc_user defined $_[0]{user} ? $_[0]{user} : (q||);
   enc_U16 defined $_[0]{unknown1} ? $_[0]{unknown1} : (q||);
   enc_U16 defined $_[0]{unknown2} ? $_[0]{unknown2} : (q||);
   $data;
};

# login
$dec_server{0x0005} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "login";
   
   $r->{message} = dec_CONSTANT q|login failed: specified user does not exist|;
   $r->{user} = dec_user q||;
   $r->{unknown1} = dec_U16 q||;
   $r->{unknown2} = dec_U16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{login} = sub {
   $data = "";
   enc_U16 0x0005;
   
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|login failed: specified user does not exist|);
   enc_user defined $_[0]{user} ? $_[0]{user} : (q||);
   enc_U16 defined $_[0]{unknown1} ? $_[0]{unknown1} : (q||);
   enc_U16 defined $_[0]{unknown2} ? $_[0]{unknown2} : (q||);
   $data;
};

# login
$dec_server{0x0006} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "login";
   
   $r->{message} = dec_CONSTANT q|login failed: other user of same name already exists|;
   $r->{user} = dec_user q||;
   $r->{unknown1} = dec_U16 q||;
   $r->{unknown2} = dec_U16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{login} = sub {
   $data = "";
   enc_U16 0x0006;
   
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|login failed: other user of same name already exists|);
   enc_user defined $_[0]{user} ? $_[0]{user} : (q||);
   enc_U16 defined $_[0]{unknown1} ? $_[0]{unknown1} : (q||);
   enc_U16 defined $_[0]{unknown2} ? $_[0]{unknown2} : (q||);
   $data;
};

# userinfo
$dec_server{0x0008} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "userinfo";
   
   $r->{_unused0} = dec_flag q||;
   $r->{user} = dec_user q||;
   $r->{_unused1} = dec_U64 q||;
   $r->{realname} = dec_realname q||;
   $r->{email} = dec_email q||;
   $r->{info} = dec_userinfo q||;
   $r->{homepage} = dec_url q||;
   $r->{regdate} = dec_timestamp q||;
   $r->{lastlogin} = dec_timestamp q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{userinfo} = sub {
   $data = "";
   enc_U16 0x0008;
   
   enc_flag defined $_[0]{_unused0} ? $_[0]{_unused0} : (q||);
   enc_user defined $_[0]{user} ? $_[0]{user} : (q||);
   enc_U64 defined $_[0]{_unused1} ? $_[0]{_unused1} : (q||);
   enc_realname defined $_[0]{realname} ? $_[0]{realname} : (q||);
   enc_email defined $_[0]{email} ? $_[0]{email} : (q||);
   enc_userinfo defined $_[0]{info} ? $_[0]{info} : (q||);
   enc_url defined $_[0]{homepage} ? $_[0]{homepage} : (q||);
   enc_timestamp defined $_[0]{regdate} ? $_[0]{regdate} : (q||);
   enc_timestamp defined $_[0]{lastlogin} ? $_[0]{lastlogin} : (q||);
   $data;
};

# upd_userinfo_result
$dec_server{0x0009} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "upd_userinfo_result";
   
   $r->{name} = dec_username q||;
   $r->{message} = dec_CONSTANT q|Thanks for registering.|;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{upd_userinfo_result} = sub {
   $data = "";
   enc_U16 0x0009;
   
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|Thanks for registering.|);
   $data;
};

# upd_userinfo_result
$dec_server{0x000a} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "upd_userinfo_result";
   
   $r->{name} = dec_username q||;
   $r->{message} = dec_CONSTANT q|The user "%s" has been successfully updated.|;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{upd_userinfo_result} = sub {
   $data = "";
   enc_U16 0x000a;
   
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|The user "%s" has been successfully updated.|);
   $data;
};

# upd_userinfo_result
$dec_server{0x000b} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "upd_userinfo_result";
   
   $r->{name} = dec_username q||;
   $r->{message} = dec_CONSTANT q|There is no user "%s". Update failed.|;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{upd_userinfo_result} = sub {
   $data = "";
   enc_U16 0x000b;
   
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|There is no user "%s". Update failed.|);
   $data;
};

# userinfo_failed
$dec_server{0x0012} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "userinfo_failed";
   
   $r->{name} = dec_username q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{userinfo_failed} = sub {
   $data = "";
   enc_U16 0x0012;
   
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   $data;
};

# msg_chat
$dec_server{0x0013} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "msg_chat";
   
   $r->{name} = dec_username q||;
   $r->{name2} = dec_username q||;
   $r->{message} = dec_STRING q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{msg_chat} = sub {
   $data = "";
   enc_U16 0x0013;
   
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_username defined $_[0]{name2} ? $_[0]{name2} : (q||);
   enc_STRING defined $_[0]{message} ? $_[0]{message} : (q||);
   $data;
};

# stats
$dec_server{0x0015} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "stats";
   
   $r->{ver_major} = dec_U16 q||;
   $r->{ver_minor} = dec_U16 q||;
   $r->{ver_micro} = dec_U16 q||;
   $r->{boot_time} = dec_timestamp q||;
   $r->{users_cur} = dec_U32 q||;
   $r->{users_max} = dec_U32 q||;
   $r->{users_lim} = dec_U32 q||;
   $r->{accts_cur} = dec_U32 q||;
   $r->{accts_max} = dec_U32 q||;
   $r->{unknown1} = dec_U32 q||;
   $r->{work_max} = dec_U32 q||;
   $r->{rooms_cur} = dec_U32 q||;
   $r->{rooms_max} = dec_U32 q||;
   $r->{rooms_lim} = dec_U32 q||;
   $r->{games_cur} = dec_U32 q||;
   $r->{games_max} = dec_U32 q||;
   $r->{games_lim} = dec_U32 q||;
   $r->{results_cur} = dec_U32 q||;
   $r->{results_max} = dec_U32 q||;
   $r->{unknown2} = dec_U32 q||;
   $r->{params_cur} = dec_U32 q||;
   $r->{params_max} = dec_U32 q||;
   $r->{bytes_in} = dec_U64 q||;
   $r->{packets_in} = dec_U64 q||;
   $r->{bytes_out} = dec_U64 q||;
   $r->{packets_out} = dec_U64 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{stats} = sub {
   $data = "";
   enc_U16 0x0015;
   
   enc_U16 defined $_[0]{ver_major} ? $_[0]{ver_major} : (q||);
   enc_U16 defined $_[0]{ver_minor} ? $_[0]{ver_minor} : (q||);
   enc_U16 defined $_[0]{ver_micro} ? $_[0]{ver_micro} : (q||);
   enc_timestamp defined $_[0]{boot_time} ? $_[0]{boot_time} : (q||);
   enc_U32 defined $_[0]{users_cur} ? $_[0]{users_cur} : (q||);
   enc_U32 defined $_[0]{users_max} ? $_[0]{users_max} : (q||);
   enc_U32 defined $_[0]{users_lim} ? $_[0]{users_lim} : (q||);
   enc_U32 defined $_[0]{accts_cur} ? $_[0]{accts_cur} : (q||);
   enc_U32 defined $_[0]{accts_max} ? $_[0]{accts_max} : (q||);
   enc_U32 defined $_[0]{unknown1} ? $_[0]{unknown1} : (q||);
   enc_U32 defined $_[0]{work_max} ? $_[0]{work_max} : (q||);
   enc_U32 defined $_[0]{rooms_cur} ? $_[0]{rooms_cur} : (q||);
   enc_U32 defined $_[0]{rooms_max} ? $_[0]{rooms_max} : (q||);
   enc_U32 defined $_[0]{rooms_lim} ? $_[0]{rooms_lim} : (q||);
   enc_U32 defined $_[0]{games_cur} ? $_[0]{games_cur} : (q||);
   enc_U32 defined $_[0]{games_max} ? $_[0]{games_max} : (q||);
   enc_U32 defined $_[0]{games_lim} ? $_[0]{games_lim} : (q||);
   enc_U32 defined $_[0]{results_cur} ? $_[0]{results_cur} : (q||);
   enc_U32 defined $_[0]{results_max} ? $_[0]{results_max} : (q||);
   enc_U32 defined $_[0]{unknown2} ? $_[0]{unknown2} : (q||);
   enc_U32 defined $_[0]{params_cur} ? $_[0]{params_cur} : (q||);
   enc_U32 defined $_[0]{params_max} ? $_[0]{params_max} : (q||);
   enc_U64 defined $_[0]{bytes_in} ? $_[0]{bytes_in} : (q||);
   enc_U64 defined $_[0]{packets_in} ? $_[0]{packets_in} : (q||);
   enc_U64 defined $_[0]{bytes_out} ? $_[0]{bytes_out} : (q||);
   enc_U64 defined $_[0]{packets_out} ? $_[0]{packets_out} : (q||);
   $data;
};

# idle_warn
$dec_server{0x0016} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "idle_warn";
   
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{idle_warn} = sub {
   $data = "";
   enc_U16 0x0016;
   
   $data;
};

# login
$dec_server{0x0018} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "login";
   
   $r->{message} = dec_CONSTANT q|logged out: another client logged in with your username|;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{login} = sub {
   $data = "";
   enc_U16 0x0018;
   
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|logged out: another client logged in with your username|);
   $data;
};

# login
$dec_server{0x001c} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "login";
   
   $r->{message} = dec_CONSTANT q|logged out: idle for too long|;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{login} = sub {
   $data = "";
   enc_U16 0x001c;
   
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|logged out: idle for too long|);
   $data;
};

# error
$dec_server{0x0020} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "error";
   
   $r->{message} = dec_CONSTANT q|Sorry, you have too many unfinished games. You cannot turn on your rank. Please finish some of your games, then try again.|;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{error} = sub {
   $data = "";
   enc_U16 0x0020;
   
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|Sorry, you have too many unfinished games. You cannot turn on your rank. Please finish some of your games, then try again.|);
   $data;
};

# login
$dec_server{0x0022} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "login";
   
   $r->{reason} = dec_STRING q||;
   $r->{result} = dec_CONSTANT q|user or ip blocked|;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{login} = sub {
   $data = "";
   enc_U16 0x0022;
   
   enc_STRING defined $_[0]{reason} ? $_[0]{reason} : (q||);
   enc_CONSTANT defined $_[0]{result} ? $_[0]{result} : (q|user or ip blocked|);
   $data;
};

# timewarning_default
$dec_server{0x001b} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "timewarning_default";
   
   $r->{channel} = dec_U16 q||;
   $r->{time} = dec_U16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{timewarning_default} = sub {
   $data = "";
   enc_U16 0x001b;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_U16 defined $_[0]{time} ? $_[0]{time} : (q||);
   $data;
};

# idle_err
$dec_server{0x001c} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "idle_err";
   
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{idle_err} = sub {
   $data = "";
   enc_U16 0x001c;
   
   $data;
};

# ping
$dec_server{0x001d} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "ping";
   
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{ping} = sub {
   $data = "";
   enc_U16 0x001d;
   
   $data;
};

# usergraph
$dec_server{0x001e} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "usergraph";
   
   $r->{name} = dec_username q||;
   $r->{data} = (my $array = []);
   while (length $data) {
      push @$array, dec_I16 ;
   }

   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{usergraph} = sub {
   $data = "";
   enc_U16 0x001e;
   
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_I16 defined $_[0]{data} ? $_[0]{data} : (q||);
   $data;
};

# userpic
$dec_server{0x0021} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "userpic";
   
   $r->{name} = dec_username q||;
   $r->{data} = dec_DATA q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{userpic} = sub {
   $data = "";
   enc_U16 0x0021;
   
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_DATA defined $_[0]{data} ? $_[0]{data} : (q||);
   $data;
};

# memo_error
$dec_server{0x0025} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "memo_error";
   
   $r->{name} = dec_username q||;
   $r->{cid} = dec_CLIENTID16 q||;
   $r->{message} = dec_CONSTANT q|memo send failed: account already exists|;
   $r->{subtype} = dec_CONSTANT q|25|;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{memo_error} = sub {
   $data = "";
   enc_U16 0x0025;
   
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_CLIENTID16 defined $_[0]{cid} ? $_[0]{cid} : (q||);
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|memo send failed: account already exists|);
   enc_CONSTANT defined $_[0]{subtype} ? $_[0]{subtype} : (q|25|);
   $data;
};

# memo_error
$dec_server{0x0026} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "memo_error";
   
   $r->{name} = dec_username q||;
   $r->{cid} = dec_CLIENTID16 q||;
   $r->{message} = dec_CONSTANT q|memo send failed: error 26|;
   $r->{subtype} = dec_CONSTANT q|26|;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{memo_error} = sub {
   $data = "";
   enc_U16 0x0026;
   
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_CLIENTID16 defined $_[0]{cid} ? $_[0]{cid} : (q||);
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|memo send failed: error 26|);
   enc_CONSTANT defined $_[0]{subtype} ? $_[0]{subtype} : (q|26|);
   $data;
};

# memo_error
$dec_server{0x0027} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "memo_error";
   
   $r->{name} = dec_username q||;
   $r->{cid} = dec_CLIENTID16 q||;
   $r->{message} = dec_CONSTANT q|memo send failed: user is online, use chat|;
   $r->{subtype} = dec_CONSTANT q|27|;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{memo_error} = sub {
   $data = "";
   enc_U16 0x0027;
   
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_CLIENTID16 defined $_[0]{cid} ? $_[0]{cid} : (q||);
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|memo send failed: user is online, use chat|);
   enc_CONSTANT defined $_[0]{subtype} ? $_[0]{subtype} : (q|27|);
   $data;
};

# memo_error
$dec_server{0x0028} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "memo_error";
   
   $r->{name} = dec_username q||;
   $r->{cid} = dec_CLIENTID16 q||;
   $r->{message} = dec_CONSTANT q|memo send failed: error 28|;
   $r->{subtype} = dec_CONSTANT q|28|;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{memo_error} = sub {
   $data = "";
   enc_U16 0x0028;
   
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_CLIENTID16 defined $_[0]{cid} ? $_[0]{cid} : (q||);
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|memo send failed: error 28|);
   enc_CONSTANT defined $_[0]{subtype} ? $_[0]{subtype} : (q|28|);
   $data;
};

# memo
$dec_server{0x0029} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "memo";
   
   $r->{name} = dec_username q||;
   $r->{time} = dec_timestamp q||;
   $r->{message} = dec_ZSTRING q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{memo} = sub {
   $data = "";
   enc_U16 0x0029;
   
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_timestamp defined $_[0]{time} ? $_[0]{time} : (q||);
   enc_ZSTRING defined $_[0]{message} ? $_[0]{message} : (q||);
   $data;
};

# memo_sent
$dec_server{0x002a} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "memo_sent";
   
   $r->{name} = dec_username q||;
   $r->{cid} = dec_CLIENTID16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{memo_sent} = sub {
   $data = "";
   enc_U16 0x002a;
   
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_CLIENTID16 defined $_[0]{cid} ? $_[0]{cid} : (q||);
   $data;
};

# gnotice
$dec_server{0x0100} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "gnotice";
   
   $r->{notice} = dec_STRING q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{gnotice} = sub {
   $data = "";
   enc_U16 0x0100;
   
   enc_STRING defined $_[0]{notice} ? $_[0]{notice} : (q||);
   $data;
};

# notify_event
$dec_server{0x0202} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "notify_event";
   
   $r->{event} = dec_U32 q||;
   $r->{user} = dec_user q||;
   $r->{gamerecord} = dec_game_record q||
      if ($r->{event} == 2);
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{notify_event} = sub {
   $data = "";
   enc_U16 0x0202;
   
   enc_U32 defined $_[0]{event} ? $_[0]{event} : (q||);
   enc_user defined $_[0]{user} ? $_[0]{user} : (q||);
   enc_game_record defined $_[0]{gamerecord} ? $_[0]{gamerecord} : (q||);
   $data;
};

# login_done
$dec_server{0x030c} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "login_done";
   
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{login_done} = sub {
   $data = "";
   enc_U16 0x030c;
   
   $data;
};

# priv_room
$dec_server{0x0310} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "priv_room";
   
   $r->{name} = dec_STRING q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{priv_room} = sub {
   $data = "";
   enc_U16 0x0310;
   
   enc_STRING defined $_[0]{name} ? $_[0]{name} : (q||);
   $data;
};

# upd_rooms
$dec_server{0x0318} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "upd_rooms";
   
   $r->{rooms} = (my $array = []);
   while (length $data) {
      push @$array, dec_room ;
   }

   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{upd_rooms} = sub {
   $data = "";
   enc_U16 0x0318;
   
   enc_room defined $_[0]{rooms} ? $_[0]{rooms} : (q||);
   $data;
};

# chal_defaults
$dec_server{0x0411} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "chal_defaults";
   
   $r->{channel} = dec_U16 q||;
   $r->{defaults} = dec_challenge_defaults q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{chal_defaults} = sub {
   $data = "";
   enc_U16 0x0411;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_challenge_defaults defined $_[0]{defaults} ? $_[0]{defaults} : (q||);
   $data;
};

# already_playing
$dec_server{0x0412} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "already_playing";
   
   $r->{message} = dec_CONSTANT q|Sorry, you are already playing in one game, so you can't start playing in another.|;
   $r->{cid} = dec_CLIENTID16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{already_playing} = sub {
   $data = "";
   enc_U16 0x0412;
   
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|Sorry, you are already playing in one game, so you can't start playing in another.|);
   enc_CLIENTID16 defined $_[0]{cid} ? $_[0]{cid} : (q||);
   $data;
};

# game_record
$dec_server{0x0414} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "game_record";
   
   $r->{name} = dec_username q||;
   $r->{more} = dec_flag q||;
   $r->{games} = (my $array = []);
   while (length $data) {
      push @$array, dec_game_record ;
   }

   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{game_record} = sub {
   $data = "";
   enc_U16 0x0414;
   
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_flag defined $_[0]{more} ? $_[0]{more} : (q||);
   enc_game_record defined $_[0]{games} ? $_[0]{games} : (q||);
   $data;
};

# error
$dec_server{0x0417} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "error";
   
   $r->{message} = dec_CONSTANT q|Sorry, your opponent is currently not logged in, so you can't resume this game.|;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{error} = sub {
   $data = "";
   enc_U16 0x0417;
   
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|Sorry, your opponent is currently not logged in, so you can't resume this game.|);
   $data;
};

# error
$dec_server{0x0418} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "error";
   
   $r->{message} = dec_CONSTANT q|Sorry, your opponent is already playing in a game, so you cannot continue this one.|;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{error} = sub {
   $data = "";
   enc_U16 0x0418;
   
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|Sorry, your opponent is already playing in a game, so you cannot continue this one.|);
   $data;
};

# error
$dec_server{0x0419} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "error";
   
   $r->{message} = dec_CONSTANT q|Sorry, the server is out of boards! Please wait a few minutes and try to start a game again.|;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{error} = sub {
   $data = "";
   enc_U16 0x0419;
   
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|Sorry, the server is out of boards! Please wait a few minutes and try to start a game again.|);
   $data;
};

# upd_game2
$dec_server{0x041c} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "upd_game2";
   
   $r->{channel_junk} = dec_U16 q||;
   $r->{game} = dec_game q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{upd_game2} = sub {
   $data = "";
   enc_U16 0x041c;
   
   enc_U16 defined $_[0]{channel_junk} ? $_[0]{channel_junk} : (q||);
   enc_game defined $_[0]{game} ? $_[0]{game} : (q||);
   $data;
};

# error
$dec_server{0x041f} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "error";
   
   $r->{message} = dec_CONSTANT q|Sorry, the game you tried to load was not correctly saved...probably caused by the server crashing. It cannot be recovered.|;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{error} = sub {
   $data = "";
   enc_U16 0x041f;
   
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|Sorry, the game you tried to load was not correctly saved...probably caused by the server crashing. It cannot be recovered.|);
   $data;
};

# error
$dec_server{0x0420} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "error";
   
   $r->{message} = dec_CONSTANT q|Sorry, user "%s" has left the game you are starting before you could challenge them. You will have to play against somebody else.|;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{error} = sub {
   $data = "";
   enc_U16 0x0420;
   
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|Sorry, user "%s" has left the game you are starting before you could challenge them. You will have to play against somebody else.|);
   $data;
};

# error
$dec_server{0x0421} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "error";
   
   $r->{message} = dec_CONSTANT q|Sorry, this game is a private lesson. You will not be allowed to observe it.|;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{error} = sub {
   $data = "";
   enc_U16 0x0421;
   
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|Sorry, this game is a private lesson. You will not be allowed to observe it.|);
   $data;
};

# add_global_challenges
$dec_server{0x043a} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "add_global_challenges";
   
   $r->{games} = (my $array = []);
   while (length $data) {
      push @$array, dec_room_game ;
   }

   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{add_global_challenges} = sub {
   $data = "";
   enc_U16 0x043a;
   
   enc_room_game defined $_[0]{games} ? $_[0]{games} : (q||);
   $data;
};

# join_room
$dec_server{0x4300} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "join_room";
   
   $r->{channel} = dec_U16 q||;
   $r->{users} = (my $array = []);
   while (length $data) {
      push @$array, dec_user ;
   }

   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{join_room} = sub {
   $data = "";
   enc_U16 0x4300;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_user defined $_[0]{users} ? $_[0]{users} : (q||);
   $data;
};

# msg_room
$dec_server{0x4301} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "msg_room";
   
   $r->{channel} = dec_U16 q||;
   $r->{name} = dec_username q||;
   $r->{message} = dec_STRING q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{msg_room} = sub {
   $data = "";
   enc_U16 0x4301;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_STRING defined $_[0]{message} ? $_[0]{message} : (q||);
   $data;
};

# part_room
$dec_server{0x4302} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "part_room";
   
   $r->{channel} = dec_U16 q||;
   $r->{user} = dec_user q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{part_room} = sub {
   $data = "";
   enc_U16 0x4302;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_user defined $_[0]{user} ? $_[0]{user} : (q||);
   $data;
};

# del_room
$dec_server{0x4303} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "del_room";
   
   $r->{channel} = dec_U16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{del_room} = sub {
   $data = "";
   enc_U16 0x4303;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   $data;
};

# upd_games
$dec_server{0x4304} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "upd_games";
   
   $r->{channel} = dec_U16 q||;
   $r->{games} = (my $array = []);
   while (length $data) {
      push @$array, dec_game ;
   }

   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{upd_games} = sub {
   $data = "";
   enc_U16 0x4304;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_game defined $_[0]{games} ? $_[0]{games} : (q||);
   $data;
};

# desc_room
$dec_server{0x4319} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "desc_room";
   
   $r->{channel} = dec_U16 q||;
   $r->{owner} = dec_username q||;
   $r->{description} = dec_STRING q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{desc_room} = sub {
   $data = "";
   enc_U16 0x4319;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_username defined $_[0]{owner} ? $_[0]{owner} : (q||);
   enc_STRING defined $_[0]{description} ? $_[0]{description} : (q||);
   $data;
};

# challenge
$dec_server{0x4400} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "challenge";
   
   $r->{channel} = dec_U16 q||;
   $r->{black} = dec_user q||;
   $r->{white} = dec_user q||;
   $r->{gametype} = dec_U8 q||;
   $r->{cid} = dec_CLIENTID8 q||;
   $r->{rules} = dec_rules q||;
   $r->{notes} = dec_STRING q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{challenge} = sub {
   $data = "";
   enc_U16 0x4400;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_user defined $_[0]{black} ? $_[0]{black} : (q||);
   enc_user defined $_[0]{white} ? $_[0]{white} : (q||);
   enc_U8 defined $_[0]{gametype} ? $_[0]{gametype} : (q||);
   enc_CLIENTID8 defined $_[0]{cid} ? $_[0]{cid} : (q||);
   enc_rules defined $_[0]{rules} ? $_[0]{rules} : (q||);
   enc_STRING defined $_[0]{notes} ? $_[0]{notes} : (q||);
   $data;
};

# upd_game
$dec_server{0x4401} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "upd_game";
   
   $r->{channel} = dec_U16 q||;
   $r->{game} = dec_game q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{upd_game} = sub {
   $data = "";
   enc_U16 0x4401;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_game defined $_[0]{game} ? $_[0]{game} : (q||);
   $data;
};

# del_game
$dec_server{0x4402} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "del_game";
   
   $r->{channel} = dec_U16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{del_game} = sub {
   $data = "";
   enc_U16 0x4402;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   $data;
};

# upd_observers
$dec_server{0x4403} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "upd_observers";
   
   $r->{channel} = dec_U16 q||;
   $r->{users} = (my $array = []);
   while (length $data) {
      push @$array, dec_user ;
   }

   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{upd_observers} = sub {
   $data = "";
   enc_U16 0x4403;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_user defined $_[0]{users} ? $_[0]{users} : (q||);
   $data;
};

# del_observer
$dec_server{0x4404} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "del_observer";
   
   $r->{channel} = dec_U16 q||;
   $r->{name} = dec_username q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{del_observer} = sub {
   $data = "";
   enc_U16 0x4404;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   $data;
};

# set_tree
$dec_server{0x4405} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "set_tree";
   
   $r->{channel} = dec_U16 q||;
   $r->{tree} = dec_TREE q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{set_tree} = sub {
   $data = "";
   enc_U16 0x4405;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_TREE defined $_[0]{tree} ? $_[0]{tree} : (q||);
   $data;
};

# upd_tree
$dec_server{0x4406} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "upd_tree";
   
   $r->{channel} = dec_U16 q||;
   $r->{tree} = dec_TREE q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{upd_tree} = sub {
   $data = "";
   enc_U16 0x4406;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_TREE defined $_[0]{tree} ? $_[0]{tree} : (q||);
   $data;
};

# superko
$dec_server{0x4409} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "superko";
   
   $r->{channel} = dec_U16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{superko} = sub {
   $data = "";
   enc_U16 0x4409;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   $data;
};

# game_done
$dec_server{0x440a} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "game_done";
   
   $r->{channel} = dec_U16 q||;
   $r->{id} = dec_U32 q||;
   $r->{black} = dec_flag q||;
   $r->{white} = dec_flag q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{game_done} = sub {
   $data = "";
   enc_U16 0x440a;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_U32 defined $_[0]{id} ? $_[0]{id} : (q||);
   enc_flag defined $_[0]{black} ? $_[0]{black} : (q||);
   enc_flag defined $_[0]{white} ? $_[0]{white} : (q||);
   $data;
};

# final_result
$dec_server{0x440b} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "final_result";
   
   $r->{channel} = dec_U16 q||;
   $r->{blackscore} = dec_scorevalues q||;
   $r->{whitescore} = dec_scorevalues q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{final_result} = sub {
   $data = "";
   enc_U16 0x440b;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_scorevalues defined $_[0]{blackscore} ? $_[0]{blackscore} : (q||);
   enc_scorevalues defined $_[0]{whitescore} ? $_[0]{whitescore} : (q||);
   $data;
};

# out_of_time
$dec_server{0x440c} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "out_of_time";
   
   $r->{channel} = dec_U16 q||;
   $r->{player} = dec_U8 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{out_of_time} = sub {
   $data = "";
   enc_U16 0x440c;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_U8 defined $_[0]{player} ? $_[0]{player} : (q||);
   $data;
};

# req_undo
$dec_server{0x440e} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "req_undo";
   
   $r->{channel} = dec_U16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{req_undo} = sub {
   $data = "";
   enc_U16 0x440e;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   $data;
};

# resign_game
$dec_server{0x4410} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "resign_game";
   
   $r->{channel} = dec_U16 q||;
   $r->{player} = dec_U8 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{resign_game} = sub {
   $data = "";
   enc_U16 0x4410;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_U8 defined $_[0]{player} ? $_[0]{player} : (q||);
   $data;
};

# game_error
$dec_server{0x4415} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "game_error";
   
   $r->{channel} = dec_U16 q||;
   $r->{message} = dec_CONSTANT q|Sorry, this is a lecture game. Only authorized players are allowed to make comments.|;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{game_error} = sub {
   $data = "";
   enc_U16 0x4415;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|Sorry, this is a lecture game. Only authorized players are allowed to make comments.|);
   $data;
};

# set_teacher
$dec_server{0x441a} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "set_teacher";
   
   $r->{channel} = dec_U16 q||;
   $r->{name} = dec_username q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{set_teacher} = sub {
   $data = "";
   enc_U16 0x441a;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   $data;
};

# owner_left
$dec_server{0x441d} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "owner_left";
   
   $r->{channel} = dec_U16 q||;
   $r->{message} = dec_CONSTANT q|Sorry, the owner of this game has left. Nobody will be allowed to edit it until the owner returns.|;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{owner_left} = sub {
   $data = "";
   enc_U16 0x441d;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|Sorry, the owner of this game has left. Nobody will be allowed to edit it until the owner returns.|);
   $data;
};

# teacher_left
$dec_server{0x441e} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "teacher_left";
   
   $r->{channel} = dec_U16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{teacher_left} = sub {
   $data = "";
   enc_U16 0x441e;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   $data;
};

# allow_user_result
$dec_server{0x4422} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "allow_user_result";
   
   $r->{message} = dec_CONSTANT q|User "%s" will now be allowed full access to your game.|;
   $r->{channel} = dec_U16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{allow_user_result} = sub {
   $data = "";
   enc_U16 0x4422;
   
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|User "%s" will now be allowed full access to your game.|);
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   $data;
};

# allow_user_result
$dec_server{0x4424} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "allow_user_result";
   
   $r->{message} = dec_CONSTANT q|Sorry, user "%s" is a guest and cannot be allowed full access to your game.|;
   $r->{channel} = dec_U16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{allow_user_result} = sub {
   $data = "";
   enc_U16 0x4424;
   
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|Sorry, user "%s" is a guest and cannot be allowed full access to your game.|);
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   $data;
};

# allow_user_result
$dec_server{0x4425} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "allow_user_result";
   
   $r->{message} = dec_CONSTANT q|Sorry, user "%s" does not seem to exist and cannot be allowed into your game.|;
   $r->{channel} = dec_U16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{allow_user_result} = sub {
   $data = "";
   enc_U16 0x4425;
   
   enc_CONSTANT defined $_[0]{message} ? $_[0]{message} : (q|Sorry, user "%s" does not seem to exist and cannot be allowed into your game.|);
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   $data;
};

# add_tree
$dec_server{0x4428} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "add_tree";
   
   $r->{channel} = dec_U16 q||;
   $r->{tree} = dec_TREE q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{add_tree} = sub {
   $data = "";
   enc_U16 0x4428;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_TREE defined $_[0]{tree} ? $_[0]{tree} : (q||);
   $data;
};

# reject_challenge
$dec_server{0x4429} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "reject_challenge";
   
   $r->{channel} = dec_U16 q||;
   $r->{name} = dec_username q||;
   $r->{gametype} = dec_U8 q||;
   $r->{cid} = dec_CLIENTID8 q||;
   $r->{rules} = dec_rules q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{reject_challenge} = sub {
   $data = "";
   enc_U16 0x4429;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_username defined $_[0]{name} ? $_[0]{name} : (q||);
   enc_U8 defined $_[0]{gametype} ? $_[0]{gametype} : (q||);
   enc_CLIENTID8 defined $_[0]{cid} ? $_[0]{cid} : (q||);
   enc_rules defined $_[0]{rules} ? $_[0]{rules} : (q||);
   $data;
};

# set_comments
$dec_server{0x442b} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "set_comments";
   
   $r->{channel} = dec_U16 q||;
   $r->{node} = dec_U32 q||;
   $r->{comments} = dec_STRING q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{set_comments} = sub {
   $data = "";
   enc_U16 0x442b;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_U32 defined $_[0]{node} ? $_[0]{node} : (q||);
   enc_STRING defined $_[0]{comments} ? $_[0]{comments} : (q||);
   $data;
};

# add_comments
$dec_server{0x442c} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "add_comments";
   
   $r->{channel} = dec_U16 q||;
   $r->{node} = dec_U32 q||;
   $r->{comments} = dec_STRING q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{add_comments} = sub {
   $data = "";
   enc_U16 0x442c;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_U32 defined $_[0]{node} ? $_[0]{node} : (q||);
   enc_STRING defined $_[0]{comments} ? $_[0]{comments} : (q||);
   $data;
};

# more_comments
$dec_server{0x442d} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "more_comments";
   
   $r->{channel} = dec_U16 q||;
   $r->{node} = dec_U32 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{more_comments} = sub {
   $data = "";
   enc_U16 0x442d;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_U32 defined $_[0]{node} ? $_[0]{node} : (q||);
   $data;
};

# new_game
$dec_server{0x442f} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "new_game";
   
   $r->{channel} = dec_U16 q||;
   $r->{cid} = dec_CLIENTID16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{new_game} = sub {
   $data = "";
   enc_U16 0x442f;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_CLIENTID16 defined $_[0]{cid} ? $_[0]{cid} : (q||);
   $data;
};

# req_result
$dec_server{0x4433} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "req_result";
   
   $r->{channel} = dec_U16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{req_result} = sub {
   $data = "";
   enc_U16 0x4433;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   $data;
};

# set_quiet
$dec_server{0x4434} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "set_quiet";
   
   $r->{channel} = dec_U16 q||;
   $r->{quiet} = dec_flag q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{set_quiet} = sub {
   $data = "";
   enc_U16 0x4434;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_flag defined $_[0]{quiet} ? $_[0]{quiet} : (q||);
   $data;
};

# set_gametime
$dec_server{0x4437} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "set_gametime";
   
   $r->{channel} = dec_U16 q||;
   $r->{black_time} = dec_time q||;
   $r->{black_moves} = dec_U16 q||;
   $r->{white_time} = dec_time q||;
   $r->{white_moves} = dec_U16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{set_gametime} = sub {
   $data = "";
   enc_U16 0x4437;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_time defined $_[0]{black_time} ? $_[0]{black_time} : (q||);
   enc_U16 defined $_[0]{black_moves} ? $_[0]{black_moves} : (q||);
   enc_time defined $_[0]{white_time} ? $_[0]{white_time} : (q||);
   enc_U16 defined $_[0]{white_moves} ? $_[0]{white_moves} : (q||);
   $data;
};

# del_global_challenge
$dec_server{0x443b} = sub {
   $data = $_[0];
   my $r = { DATA => $data };
   $r->{type} = "del_global_challenge";
   
   $r->{channel} = dec_U16 q||;
   $r->{game} = dec_U16 q||;
   $r->{TRAILING_DATA} = $data if length $data;
   $r;
};
$enc_server{del_global_challenge} = sub {
   $data = "";
   enc_U16 0x443b;
   
   enc_U16 defined $_[0]{channel} ? $_[0]{channel} : (q||);
   enc_U16 defined $_[0]{game} ? $_[0]{game} : (q||);
   $data;
};

}

1;
