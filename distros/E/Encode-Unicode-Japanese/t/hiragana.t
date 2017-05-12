#! /usr/bin/perl -w
## ----------------------------------------------------------------------------
#  t/hiragana.t
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------

use strict;
use warnings;
use Test::More tests => 6;

use Encode::Unicode::Japanese;
use Encode qw(encode decode);

{
  # HRIAGANA A
  #
  my $utf8 = "\x{3042}"; # "\xe3\x81\x82";
  my $sjis = "\x82\xa0";
  my $euc  = "\xa4\xa2";
	my $jis  = "\e\$B" . "\x24\x22" . "\e(B";
  
  is(encode('unijp-sjis', $utf8), $sjis, 'utf8 => sjis');
  is(encode('unijp-euc',  $utf8), $euc,  'utf8 => euc');
  is(encode('unijp-jis',  $utf8), $jis,  'utf8 => jis');
	
  is(decode('unijp-sjis', $sjis), $utf8,  'sjis => utf8');
  is(decode('unijp-euc',  $euc),  $utf8,  'euc  => utf8');
  is(decode('unijp-jis',  $jis),  $utf8,  'jis  => utf8');
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
