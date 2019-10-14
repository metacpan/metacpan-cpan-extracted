#!/usr/bin/perl -w

package MPEG::Audio::Frame; # it doesn't export, so we enter it's namespace

# the tables are not verified since
# a. they're lexical, so we can't mess with them
# b. I didn't write them, the libmad guys did

use strict;

use Test::More tests => 43;

BEGIN { use_ok("MPEG::Audio::Frame") }

is(M_SYNC ^ M_VERSION ^ M_LAYER ^ M_CRC, 0xff, "first byte masks");
is(M_BITRATE ^ M_SAMPLE ^ M_PAD ^ M_PRIVATE, 0xff, "second byte masks");
is(M_CHANMODE ^ M_MODEXT ^ M_COPY ^ M_HOME ^ M_EMPH, 0xff, "third byte masks");

is(M_SYNC, 0xe0, "M_SYNC") or diag "M_SYNC should be 11100000 but is " . unpack("B*", M_SYNC);
is(M_CRC, 0x01, "M_CRC") or diag "M_CRC should be 00000001 but is " . unpack("B*", M_CRC);
is(M_BITRATE, 0xf0, "M_BITRATE") or diag "M_BITRATE should be 11110000 but is " . unpack("B*", M_BITRATE);
is(M_PRIVATE, 0x01, "M_PRIVATE") or diag "M_PRIVATE should be 00000001 but is " . unpack("B*", M_PRIVATE);
is(M_CHANMODE, 0xc0, "M_CHANMODE") or diag "M_CHANMODE should be 11000000 but is " . unpack("B*", M_CHANMODE);
is(M_EMPH, 0x03, "M_EMPH") or diag "M_EMPH should be 00000011 but is " . unpack("B*", M_EMPH);

is(B_SYNC, 1, "B_SYNC");
is(B_CRC, 1, "B_CRC");
is(B_BITRATE, 2, "B_BITRATE");
is(B_PRIVATE, 2, "B_PRIVATE");
is(B_CHANMODE, 3, "B_CHANMODE");
is(B_HOME, 3, "B_HOME");
is(B_EMPH, 3, "B_EMPH");

my $i = 0;
is(SYNC, $i++, "SYNC");
is(VERSION, $i++, "VERSION");
is(LAYER, $i++, "LAYER");
is(CRC, $i++, "CRC");
is(BITRATE, $i++, "BITRATE");
is(SAMPLE, $i++, "SAMPLE");
is(PAD, $i++, "PAD");
is(PRIVATE, $i++, "PRIVATE");
is(CHANMODE, $i++, "CHANMODE");
is(MODEXT, $i++, "MODEXT");
is(COPY, $i++, "COPY");
is(HOME, $i++, "HOME");
is(EMPH, $i++, "EMPH");

ok((M_SYNC >> R_SYNC) &1, "R_SYNC");
ok((M_VERSION >> R_VERSION) & 1, "R_VERSION");
ok((M_LAYER >> R_LAYER) & 1, "R_LAYER");
ok((M_CRC >> R_CRC) & 1, "R_CRC");
ok((M_BITRATE >> R_BITRATE) & 1, "R_BITRATE");
ok((M_SAMPLE >> R_SAMPLE) & 1, "R_SAMPLE");
ok((M_PAD >> R_PAD) & 1, "R_PAD");
ok((M_PRIVATE >> R_PRIVATE) & 1, "R_PRIVATE");
ok((M_CHANMODE >> R_CHANMODE) & 1, "R_CHANMODE");
ok((M_MODEXT >> R_MODEXT) & 1, "R_MODEXT");
ok((M_COPY >> R_COPY) & 1, "R_COPY");
ok((M_HOME >> R_HOME) & 1, "R_HOME");
ok((M_EMPH >> R_EMPH) & 1, "R_EMPH");

