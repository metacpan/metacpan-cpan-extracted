use Test::More no_plan;
use strict;
use warnings;

# Date: Thu, 26 Jul 2007 17:16:01 +0200
# From: fcharette@ankabut.net
# To: ehs@pobox.com
# Subject: [MARC::Charset] error with ZWNJ in strings encoded for Arabic
# 
# Dear Ed Summers,
#
# While converting records from the LoC from MARC-8 to UTF-8 using your
# MARC::Charset module, I encounter the following error:
#
# no mapping found for [0x8E] at position 16 in agQSJ fSNg�gGi NWi cJGHNGfî
# Yehei GUagGf / g0=BASIC_ARABIC g1=EXTENDED_ARABIC at
# /usr/lib/perl5/site_perl/5.8.7/MARC/Charset.pm line 209.
# no mapping found for [0x8E] at position 42 in hRGQJ aQgfÞ h gfQ, GOGQg cd
# cJGHNGfg�gG, g0=BASIC_ARABIC g1=EXTENDED_ARABIC at
# /usr/lib/perl5/site_perl/5.8.7/MARC/Charset.pm line 209.
#
# As you see, the problem is with byte 0x8E which corresponds to Unicode U+200C
# ZEROWIDTH NON-JOINER.
#
# I found out by looking at the database codetable.xml that this "character" is
# only included in (in XPath notation): //codeTable[@name="Basic and Extended
# Latin"]/characterSet[@name="Extended Latin"].
# But both U+200C and U+200D are occasionally needed for the Arabic script,
# especially in Farsi (see for example LCCN 2006552991, which occasioned the
# above two errors).
#
# --
#
# So two new rules were added to the code tables from LC and these errors 
# went away. Hopefully the LC tables will be updated appropriately.

use MARC::Charset qw(marc8_to_utf8);

open my $FARSI, '<', 't/farsi.marc';
my @lines = <$FARSI>;

foreach my $line (@lines) {
  ok marc8_to_utf8($line);
}

