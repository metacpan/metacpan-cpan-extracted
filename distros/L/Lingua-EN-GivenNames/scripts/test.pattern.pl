#!/usr/bin/env perl

use feature qw/say unicode_strings/;
use open qw(:std :utf8);
use strict;
use warnings;
use warnings qw(FATAL utf8);

# -----------------------------------------------

#my($s) = join(' ', @ARGV);

my($s) = 'female. BEVIN: Anglicized form of Irish Gaelic Béibhinn, meaning "fair lady."';

say $s;

	my($sub_pattern) = <<'EOS';
Anglicized|Breton|Contracted|Diminutive|Elaborated|
English\s+?and\s+?(?:French|German|Latin|Scottish)|
(?:(?:American|British)\s+?)?English|
Feminine|French|Irish\s+?Gaelic|
Latin|Latvian|Medieval\s+?English|Modern|
Old\s+?English|Pet|Polish|
Scottish(?:\s+Anglicized)?|Short|Slovak|Spanish|Unisex|
(?:V|v)ariant
EOS
	my($sub_pattern_1) = '.+'; # This is faked, since original sub_pattern_1 has been lost. See git!
	my($sub_pattern_2) = <<'EOS';
(?:(?:adopted|contracted|diminutive|elaborated|feminine|pet|short|unisex|variant)?\s*?
EOS
	# Note for 2 => Name: Beware 'NAME (Text):'. Also, text can contain ':'.
if ($s =~	/
			(.+?)\.\s            # 1 => Sex.
			(.+?):\s*            # 2 => Name.
			($sub_pattern_1)\s+? # 3 => Kind.
			($sub_pattern_2)     # 4 => Form.
			(?:equivalent|form|spelling|use)\s+?)
			(?:of\s+?)?(.+?)\s+?(.+?)\s*?(?:,\s*?)?           # 5 => Source, 6 => Original.
			(?:possibly\s+?)?meaning\s*?(?:simply\s*)?"(.+?)" # 7 => Meaning.
			/x,
	)
{
	say "Sex: <$1>. Name: <$2>. Kind: <$3>. Form: <$4>. Source: <$5>. Original: <$6>. Meaning: <$7>.";
}
else
{
	say "Did not match";
}
