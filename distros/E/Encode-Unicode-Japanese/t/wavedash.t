#! /usr/bin/perl -w
## ----------------------------------------------------------------------------
#  t/wavedash.t
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------

use strict;
use warnings;
use Test::More tests => 21;

use Encode::Unicode::Japanese;
use Encode qw(encode decode);

{
  # WAVE-DASH
  #
  my $uni_WAVEDASH  = "\x{301c}";
  my $uni_FULLTILDE = "\x{FF5E}";
  my $sjis_WAVEDASH = "\x81\x60";
  my $euc_WAVEDASH  = "\xa1\xc1";
  my $jis_WAVEDASH  = "\e\$B" . "\x21\x41" . "\e(B";
  
  # Unicode::Japanese (sjis)
  is(encode('unijp-sjis', $uni_WAVEDASH),  $sjis_WAVEDASH, 'unijp: utf8 => sjis');
  is(encode('unijp-sjis', $uni_FULLTILDE), $sjis_WAVEDASH, 'unijp: utf8 => sjis');
  is(decode('unijp-sjis', $sjis_WAVEDASH), $uni_FULLTILDE, 'unijp: sjis => utf8');
  
  # Unicode::Japanese (euc-jp)
  is(encode('unijp-euc', $uni_WAVEDASH),  $euc_WAVEDASH, 'unijp: utf8 => euc');
  is(encode('unijp-euc', $uni_FULLTILDE), $euc_WAVEDASH, 'unijp: utf8 => euc');
  is(decode('unijp-euc', $euc_WAVEDASH),  $uni_FULLTILDE, 'unijp: euc => utf8');
  
  # Unicode::Japanese (jis)
  is(encode('unijp-jis', $uni_WAVEDASH),  $jis_WAVEDASH,  'unijp: utf8 => jis');
  is(encode('unijp-jis', $uni_FULLTILDE), $jis_WAVEDASH,  'unijp: utf8 => jis');
  is(decode('unijp-jis', $jis_WAVEDASH),  $uni_FULLTILDE, 'unijp: jis => utf8');
  
  
  # contrast: Encode::CP932
  is(encode('CP932', $uni_WAVEDASH),  '?',             'cp932: utf8 => sjis');
  is(encode('CP932', $uni_FULLTILDE), $sjis_WAVEDASH,  'cp932: utf8 => sjis');
  is(decode('CP932', $sjis_WAVEDASH), $uni_FULLTILDE,  'cp932: sjis => utf8');
  
  # contrast: Encode::Shift_JIS
  is(encode('Shift_JIS', $uni_WAVEDASH),  $sjis_WAVEDASH, 'Shift_JIS: utf8 => sjis');
  is(encode('Shift_JIS', $uni_FULLTILDE), '?',            'Shift_JIS: utf8 => sjis');
  is(decode('Shift_JIS', $sjis_WAVEDASH), $uni_WAVEDASH,  'Shift_JIS: sjis => utf8');
  
  # contrast: Encode::EUCJP
  is(encode('euc-jp', $uni_WAVEDASH),  $euc_WAVEDASH, 'euc-jp: utf8 => euc');
  is(encode('euc-jp', $uni_FULLTILDE), '?',           'euc-jp: utf8 => euc');
  is(decode('euc-jp', $euc_WAVEDASH),  $uni_WAVEDASH, 'euc-jp: euc => utf8');
  
  # contrast: Encode::Iso2022jp
  is(encode('iso-2022-jp', $uni_WAVEDASH),  $jis_WAVEDASH,  'iso-2022-jp: utf8 => jis');
  is(encode('iso-2022-jp', $uni_FULLTILDE), "\\x{ff5e}",    'iso-2022-jp: utf8 => jis');
  is(decode('iso-2022-jp', $jis_WAVEDASH),  $uni_WAVEDASH,  'iso-2022-jp: jis => utf8');
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
