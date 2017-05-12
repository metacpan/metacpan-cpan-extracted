=head1 NAME

Deliantra::Protocol::Constants - export protocol-related cf constants

=head1 SYNOPSIS

   use Deliantra::Protocol::Constants;

=head1 DESCRIPTION

=over 4

=cut

package Deliantra::Protocol::Constants;

our $VERSION = '0.1';

use common::sense;

use AnyEvent;
use IO::Socket::INET;

my %CONSTANTS = (
   TICK		=> 0.120, # one server tick, not exposed through the protocol of course
   CS_QUERY_YESNO	=> 0x1,
   CS_QUERY_SINGLECHAR	=> 0x2,
   CS_QUERY_HIDEINPUT	=> 0x4,
   CS_SAY_NORMAL	=> 0x1,
   CS_SAY_SHOUT	=> 0x2,
   CS_SAY_GSAY	=> 0x4,
   FLOAT_MULTI	=> 100000,
   FLOAT_MULTF	=> 100000.0,
   CS_STAT_HP	=> 1,
   CS_STAT_MAXHP	=> 2,
   CS_STAT_SP	=> 3,
   CS_STAT_MAXSP	=> 4,
   CS_STAT_STR	=> 5,
   CS_STAT_INT	=> 6,
   CS_STAT_WIS	=> 7,
   CS_STAT_DEX	=> 8,
   CS_STAT_CON	=> 9,
   CS_STAT_CHA	=> 10,
   CS_STAT_EXP	=> 11,
   CS_STAT_LEVEL	=> 12,
   CS_STAT_WC	=> 13,
   CS_STAT_AC	=> 14,
   CS_STAT_DAM	=> 15,
   CS_STAT_ARMOUR	=> 16,
   CS_STAT_SPEED	=> 17,
   CS_STAT_FOOD	=> 18,
   CS_STAT_WEAP_SP	=> 19,
   CS_STAT_RANGE	=> 20,
   CS_STAT_TITLE	=> 21,
   CS_STAT_POW	=> 22,
   CS_STAT_GRACE	=> 23,
   CS_STAT_MAXGRACE	=> 24,
   CS_STAT_FLAGS	=> 25,
   CS_STAT_WEIGHT_LIM	=> 26,
   CS_STAT_EXP64	=> 28,
   CS_STAT_SPELL_ATTUNE	=> 29,
   CS_STAT_SPELL_REPEL	=> 30,
   CS_STAT_SPELL_DENY	=> 31,
   CS_STAT_RESIST_START	=> 100,
   CS_STAT_RESIST_END	=> 117,
   CS_STAT_RES_PHYS	=> 100,
   CS_STAT_RES_MAG	=> 101,
   CS_STAT_RES_FIRE	=> 102,
   CS_STAT_RES_ELEC	=> 103,
   CS_STAT_RES_COLD	=> 104,
   CS_STAT_RES_CONF	=> 105,
   CS_STAT_RES_ACID	=> 106,
   CS_STAT_RES_DRAIN	=> 107,
   CS_STAT_RES_GHOSTHIT	=> 108,
   CS_STAT_RES_POISON	=> 109,
   CS_STAT_RES_SLOW	=> 110,
   CS_STAT_RES_PARA	=> 111,
   CS_STAT_TURN_UNDEAD	=> 112,
   CS_STAT_RES_FEAR	=> 113,
   CS_STAT_RES_DEPLETE	=> 114,
   CS_STAT_RES_DEATH	=> 115,
   CS_STAT_RES_HOLYWORD	=> 116,
   CS_STAT_RES_BLIND	=> 117,
   CS_STAT_SKILLINFO	=> 140,
   CS_NUM_SKILLS	=> 50,
   SF_FIREON		=> 0x01,
   SF_RUNON 		=> 0x02,
   NDI_BLACK		=> 0,
   NDI_WHITE		=> 1,
   NDI_NAVY 		=> 2,
   NDI_RED		=> 3,
   NDI_ORANGE	=> 4,
   NDI_BLUE		=> 5,
   NDI_DK_ORANGE	=> 6,
   NDI_GREEN		=> 7,
   NDI_LT_GREEN	=> 8,
   NDI_GREY 		=> 9,
   NDI_BROWN		=> 10,
   NDI_GOLD 		=> 11,
   NDI_TAN  		=> 12,
   NDI_MAX_COLOR	=> 12,
   NDI_COLOR_MASK	=> 0x1f,
   NDI_REPLY	=> 0x20,
   NDI_NOCRATE  => 0x40,
   NDI_CLEAR	=> 0x80,
   a_none   		=> 0,
   a_readied		=> 1,
   a_wielded		=> 2,
   a_worn   		=> 3,
   a_active 		=> 4,
   a_applied		=> 5,
   F_APPLIED		=> 0x000F,
   F_LOCATION	=> 0x00F0,
   F_UNPAID 		=> 0x0200,
   F_MAGIC  		=> 0x0400,
   F_CURSED 		=> 0x0800,
   F_DAMNED 		=> 0x1000,
   F_OPEN   		=> 0x2000,
   F_NOPICK 		=> 0x4000,
   F_LOCKED 		=> 0x8000,
   CF_FACE_NONE	=> 0,
   CF_FACE_BITMAP	=> 1,
   CF_FACE_XPM	=> 2,
   CF_FACE_PNG	=> 3,
   CF_FACE_CACHE	=> 0x10,
   FACE_FLOOR	=> 0x80,
   FACE_COLOR_MASK	=> 0xf,
   UPD_LOCATION	=> 0x01,
   UPD_FLAGS		=> 0x02,
   UPD_WEIGHT	=> 0x04,
   UPD_FACE		=> 0x08,
   UPD_NAME		=> 0x10,
   UPD_ANIM		=> 0x20,
   UPD_ANIMSPEED	=> 0x40,
   UPD_NROF		=> 0x80,
   UPD_SP_MANA	=> 0x01,
   UPD_SP_GRACE	=> 0x02,
   UPD_SP_LEVEL	=> 0x04,
   SOUND_NORMAL	=> 0,
   SOUND_SPELL	=> 1,

   PICKUP_NOTHING => 0x00000000,
  
   PICKUP_DEBUG   => 0x10000000,
   PICKUP_INHIBIT => 0x20000000,
   PICKUP_STOP    => 0x40000000,
   PICKUP_NEWMODE => 0x80000000,
  
   PICKUP_RATIO   => 0x0000000F,
  
   PICKUP_FOOD    => 0x00000010,
   PICKUP_DRINK   => 0x00000020,
   PICKUP_VALUABLES => 0x00000040,
   PICKUP_BOW     => 0x00000080,
  
   PICKUP_ARROW   => 0x00000100,
   PICKUP_HELMET  => 0x00000200,
   PICKUP_SHIELD  => 0x00000400,
   PICKUP_ARMOUR  => 0x00000800,
  
   PICKUP_BOOTS   => 0x00001000,
   PICKUP_GLOVES  => 0x00002000,
   PICKUP_CLOAK   => 0x00004000,
   PICKUP_KEY     => 0x00008000,
  
   PICKUP_MISSILEWEAPON => 0x00010000,
   PICKUP_ALLWEAPON => 0x00020000,
   PICKUP_MAGICAL => 0x00040000,
   PICKUP_POTION  => 0x00080000,
  
   PICKUP_SPELLBOOK => 0x00100000,
   PICKUP_SKILLSCROLL => 0x00200000,
   PICKUP_READABLES => 0x00400000,
   PICKUP_MAGIC_DEVICE => 0x00800000,
  
   PICKUP_NOT_CURSED => 0x01000000,
  
   PICKUP_JEWELS => 0x02000000,
   PICKUP_FLESH  => 0x04000000,
);

eval join "\n", (map "sub $_ () { $CONSTANTS{$_} }", keys %CONSTANTS), 1
   or die;

sub import {
   my $caller = caller;

   *{"$caller\::$_"} = \&$_
      for keys %CONSTANTS;
}

=back

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

 Robin Redeker <elmex@ta-sa.org>
 http://www.ta-sa.org/

=cut

1
