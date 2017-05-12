#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Finance-Quote-Grab.
#
# Finance-Quote-Grab is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Finance-Quote-Grab is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Finance-Quote-Grab.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Encode;

#------------------------------------------------------------------------------
# 8859-7 transliteration
#
# The 8859-7 bytes here in the source are for ease of seeing what they're
# supposed to be, but they're only in the comments, the tr printed is
# all-ascii.
#
# This is for some greek characters found in otherwise English names, like
# ÂÁÍÊ (0xC2,0xC1,0xCD,0xCA) for BANK in ALPHA.ATH.  That comes out looking
# ok in Gtk or anywhere with good fonts, but for a tty a change to the
# actual intended latin characters is needed to make it printable.
#

my @table
  = (
     #            # A0   NO-BREAK SPACE
     #            # A1 ¡ MODIFIER LETTER REVERSED COMMA
     #            # A2 ¢ MODIFIER LETTER APOSTROPHE
     #            # A3 £ POUND SIGN
     #            # A4
     #            # A5
     #            # A6 ¦ BROKEN BAR
     #            # A7 § SECTION SIGN
     #            # A8 ¨ DIAERESIS
     #            # A9
     #            # AA
     #            # AB « LEFT-POINTING DOUBLE ANGLE QUOTATION MARK
     #            # AC ¬ NOT SIGN
     #            # AD ­ SOFT HYPHEN
     #            # AE
     #            # AF ¯ HORIZONTAL BAR
     #            # B0 ° DEGREE SIGN
     #            # B1 ± PLUS-MINUS SIGN
     #            # B2 ² SUPERSCRIPT TWO
     #            # B3 ³ SUPERSCRIPT THREE
     #            # B4 ´ GREEK TONOS
     #            # B5 µ GREEK DIALYTIKA TONOS
     0xB6 => 'A', # B6 ¶ GREEK CAPITAL LETTER ALPHA WITH TONOS
     #            # B7 · MIDDLE DOT
     0xB8 => 'E', # B8 ¸ GREEK CAPITAL LETTER EPSILON WITH TONOS
     0xB9 => 'H', # B9 ¹ GREEK CAPITAL LETTER ETA WITH TONOS
     0xBA => 'I', # BA º GREEK CAPITAL LETTER IOTA WITH TONOS
     #            # BB » RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK
     #            # BC ¼ GREEK CAPITAL LETTER OMICRON WITH TONOS
     #            # BD ½ VULGAR FRACTION ONE HALF
     #            # BE ¾ GREEK CAPITAL LETTER UPSILON WITH TONOS
     0xBF => 'O', # BF ¿ GREEK CAPITAL LETTER OMEGA WITH TONOS
     #            # C0 À GREEK SMALL LETTER IOTA WITH DIALYTIKA AND TONOS
     0xC1 => 'A', # C1 Á GREEK CAPITAL LETTER ALPHA
     0xC2 => 'B', # C2 Â GREEK CAPITAL LETTER BETA
     0xC3 => 'G', # C3 Ã GREEK CAPITAL LETTER GAMMA
     0xC4 => 'D', # C4 Ä GREEK CAPITAL LETTER DELTA
     0xC5 => 'E', # C5 Å GREEK CAPITAL LETTER EPSILON
     0xC6 => 'Z', # C6 Æ GREEK CAPITAL LETTER ZETA
     0xC7 => 'H', # C7 Ç GREEK CAPITAL LETTER ETA
     #            # C8 È GREEK CAPITAL LETTER THETA
     0xC9 => 'I', # C9 É GREEK CAPITAL LETTER IOTA
     0xCA => 'K', # CA Ê GREEK CAPITAL LETTER KAPPA
     0xCB => 'L', # CB Ë GREEK CAPITAL LETTER LAMDA
     0xCC => 'M', # CC Ì GREEK CAPITAL LETTER MU
     0xCD => 'N', # CD Í GREEK CAPITAL LETTER NU
     0xCE => 'X', # CE Î GREEK CAPITAL LETTER XI
     #            # CF Ï GREEK CAPITAL LETTER OMICRON
     0xD0 => 'P', # D0 Ð GREEK CAPITAL LETTER PI
     0xD1 => 'R', # D1 Ñ GREEK CAPITAL LETTER RHO
     #            # D2
     0xD3 => 'S', # D3 Ó GREEK CAPITAL LETTER SIGMA
     0xD4 => 'T', # D4 Ô GREEK CAPITAL LETTER TAU
     #            # D5 Õ GREEK CAPITAL LETTER UPSILON
     #            # D6 Ö GREEK CAPITAL LETTER PHI
     #            # D7 × GREEK CAPITAL LETTER CHI
     #            # D8 Ø GREEK CAPITAL LETTER PSI
     0xD9 => 'O', # D9 Ù GREEK CAPITAL LETTER OMEGA
     #            # DA Ú GREEK CAPITAL LETTER IOTA WITH DIALYTIKA
     #            # DB Û GREEK CAPITAL LETTER UPSILON WITH DIALYTIKA
     0xDC => 'a', # DC Ü GREEK SMALL LETTER ALPHA WITH TONOS
     0xDD => 'e', # DD Ý GREEK SMALL LETTER EPSILON WITH TONOS
     #            # DE Þ GREEK SMALL LETTER ETA WITH TONOS
     0xDF => 'i', # DF ß GREEK SMALL LETTER IOTA WITH TONOS
     #            # E0 à GREEK SMALL LETTER UPSILON WITH DIALYTIKA AND TONOS
     0xE1 => 'a', # E1 á GREEK SMALL LETTER ALPHA
     0xE2 => 'b', # E2 â GREEK SMALL LETTER BETA
     0xE3 => 'g', # E3 ã GREEK SMALL LETTER GAMMA
     0xE4 => 'd', # E4 ä GREEK SMALL LETTER DELTA
     0xE5 => 'e', # E5 å GREEK SMALL LETTER EPSILON
     0xE6 => 'z', # E6 æ GREEK SMALL LETTER ZETA
     #            # E7 ç GREEK SMALL LETTER ETA
     #            # E8 è GREEK SMALL LETTER THETA
     0xE9 => 'i', # E9 é GREEK SMALL LETTER IOTA
     0xEA => 'k', # EA ê GREEK SMALL LETTER KAPPA
     0xEB => 'l', # EB ë GREEK SMALL LETTER LAMDA
     0xEC => 'm', # EC ì GREEK SMALL LETTER MU
     0xED => 'n', # ED í GREEK SMALL LETTER NU
     #            # EE î GREEK SMALL LETTER XI
     #            # EF ï GREEK SMALL LETTER OMICRON
     0xF0 => 'p', # F0 ð GREEK SMALL LETTER PI
     0xF1 => 'r', # F1 ñ GREEK SMALL LETTER RHO
     0xF2 => 's', # F2 ò GREEK SMALL LETTER FINAL SIGMA
     0xF3 => 's', # F3 ó GREEK SMALL LETTER SIGMA
     0xF4 => 't', # F4 ô GREEK SMALL LETTER TAU
     #            # F5 õ GREEK SMALL LETTER UPSILON
     #            # F6 ö GREEK SMALL LETTER PHI
     #            # F7 ÷ GREEK SMALL LETTER CHI
     #            # F8 ø GREEK SMALL LETTER PSI
     0xF9 => 'o', # F9 ù GREEK SMALL LETTER OMEGA
     0xFA => 'i', # FA ú GREEK SMALL LETTER IOTA WITH DIALYTIKA
     #            # FB û GREEK SMALL LETTER UPSILON WITH DIALYTIKA
     #            # FC ü GREEK SMALL LETTER OMICRON WITH TONOS
     #            # FD ý GREEK SMALL LETTER UPSILON WITH TONOS
     0xFE => 'o', # FE þ GREEK SMALL LETTER OMEGA WITH TONOS
     #            # FF
    );

my $tr_from;
my $tr_to;

while (@table) {
  my $from_ord = shift @table;
  my $to_chr = shift @table;

  my $from_chr = sprintf('\\x%02X', $from_ord);

  $tr_from .= $from_chr;
  $tr_to .= $to_chr;
}

# $tr_from =~ s/-/\\-/g; # escape "tr" dash as range
# $tr_to   =~ s/-/\\-/g;

print "tr{$tr_from}\n  {$tr_to}\n";
exit 0;


# Local variables:
# coding: iso-8859-7
# End:

