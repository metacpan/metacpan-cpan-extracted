package Locale::CLDR::Transformations::Any::Blt::Blt_fonipa;
# This file auto generated from Data\common\transforms\blt-fonipa-t-blt.xml
#	on Thu 29 Feb  5:43:51 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.1');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

BEGIN {
	die "Transliteration requires Perl 5.18 or above"
		unless $^V ge v5.18.0;
}

no warnings 'experimental::regex_sets';
has 'transforms' => (
	is => 'ro',
	isa => ArrayRef,
	init_arg => undef,
	default => sub { [
		qr/(?^um:\G.)/,
		{
			type => 'transform',
			data => [
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q(),
					replace => q(([ꪵ ꪶ ꪹ ꪻ ꪼ])((?:[ꪀꪂꪄꪆꪈꪊꪌꪎꪐꪒꪔꪖꪘꪚꪜꪞꪠꪢꪤꪦꪨꪪꪬꪮ]|[ꪁꪃꪅꪇꪉꪋꪍꪏꪑꪓꪕꪗꪙꪛꪝꪟꪡꪣꪥꪧꪩꪫꪭꪯ])[ꪫ]?)),
					result  => q($2$1),
					revisit => 0,
				},
			],
		},
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(null),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q([^ \p{L} \p{M} \p{N}]),
					after   => q([^ \p{L} \p{M} \p{N}]),
					replace => q(ꪽ),
					result  => q(nan˧˩),
					revisit => 0,
				},
				{
					before  => q([ꪀ ꪂ ꪄ ꪆ ꪈ ꪊ ꪌ ꪎ ꪐ ꪒ ꪔ ꪖ ꪘ ꪚ ꪜ ꪞ ꪠ ꪢ ꪤ ꪦ ꪨ ꪪ ꪬ ꪮ][ꪫ]?(?:[ꪵꪶꪹꪻꪼ]|[ꪴꪰꪲꪳꪷꪸꪾ]|[\{ꪹꪸ\}\{ꪹꪷ\}\{ꪹꪱ\}])),
					after   => q(),
					replace => q(([ꪜ ꪝ ꪞ ꪟ ꪔ ꪕ ꪖ ꪗ ꪀ ꪁ ꪂ ꪃ ꪮ ꪯ])),
					result  => q($1˧˥),
					revisit => 0,
				},
				{
					before  => q([ꪀ ꪂ ꪄ ꪆ ꪈ ꪊ ꪌ ꪎ ꪐ ꪒ ꪔ ꪖ ꪘ ꪚ ꪜ ꪞ ꪠ ꪢ ꪤ ꪦ ꪨ ꪪ ꪬ ꪮ][ꪫ]?),
					after   => q(),
					replace => q(([ꪱ ꪮ ꪺ ꪽ][ꪜ ꪝ ꪞ ꪟ ꪔ ꪕ ꪖ ꪗ ꪀ ꪁ ꪂ ꪃ ꪮ ꪯ])),
					result  => q($1˧˥),
					revisit => 0,
				},
				{
					before  => q([ꪁ ꪃ ꪅ ꪇ ꪉ ꪋ ꪍ ꪏ ꪑ ꪓ ꪕ ꪗ ꪙ ꪛ ꪝ ꪟ ꪡ ꪣ ꪥ ꪧ ꪩ ꪫ ꪭ ꪯ][ꪫ]?(?:[ꪵꪶꪹꪻꪼ]|[ꪴꪰꪲꪳꪷꪸꪾ]|[\{ꪹꪸ\}\{ꪹꪷ\}\{ꪹꪱ\}])),
					after   => q(),
					replace => q(([ꪜ ꪝ ꪞ ꪟ ꪔ ꪕ ꪖ ꪗ ꪀ ꪁ ꪂ ꪃ ꪮ ꪯ])),
					result  => q($1˦),
					revisit => 0,
				},
				{
					before  => q([ꪁ ꪃ ꪅ ꪇ ꪉ ꪋ ꪍ ꪏ ꪑ ꪓ ꪕ ꪗ ꪙ ꪛ ꪝ ꪟ ꪡ ꪣ ꪥ ꪧ ꪩ ꪫ ꪭ ꪯ][ꪫ]?),
					after   => q(),
					replace => q(([ꪱ ꪮ ꪺ ꪽ][ꪜ ꪝ ꪞ ꪟ ꪔ ꪕ ꪖ ꪗ ꪀ ꪁ ꪂ ꪃ ꪮ ꪯ])),
					result  => q($1˦),
					revisit => 0,
				},
				{
					before  => q([ꪀ ꪂ ꪄ ꪆ ꪈ ꪊ ꪌ ꪎ ꪐ ꪒ ꪔ ꪖ ꪘ ꪚ ꪜ ꪞ ꪠ ꪢ ꪤ ꪦ ꪨ ꪪ ꪬ ꪮ][ꪫ]?),
					after   => q(),
					replace => q(꪿([ꪱ ꪮ ꪺ ꪽ](?:[ꪀꪂꪄꪆꪈꪊꪌꪎꪐꪒꪔꪖꪘꪚꪜꪞꪠꪢꪤꪦꪨꪪꪬꪮ]|[ꪁꪃꪅꪇꪉꪋꪍꪏꪑꪓꪕꪗꪙꪛꪝꪟꪡꪣꪥꪧꪩꪫꪭꪯ])?)),
					result  => q($1˧˥),
					revisit => 0,
				},
				{
					before  => q([ꪀ ꪂ ꪄ ꪆ ꪈ ꪊ ꪌ ꪎ ꪐ ꪒ ꪔ ꪖ ꪘ ꪚ ꪜ ꪞ ꪠ ꪢ ꪤ ꪦ ꪨ ꪪ ꪬ ꪮ][ꪫ]?),
					after   => q(),
					replace => q(꫁([ꪱ ꪮ ꪺ ꪽ](?:[ꪀꪂꪄꪆꪈꪊꪌꪎꪐꪒꪔꪖꪘꪚꪜꪞꪠꪢꪤꪦꪨꪪꪬꪮ]|[ꪁꪃꪅꪇꪉꪋꪍꪏꪑꪓꪕꪗꪙꪛꪝꪟꪡꪣꪥꪧꪩꪫꪭꪯ])?)),
					result  => q($1˨˩),
					revisit => 0,
				},
				{
					before  => q([ꪁ ꪃ ꪅ ꪇ ꪉ ꪋ ꪍ ꪏ ꪑ ꪓ ꪕ ꪗ ꪙ ꪛ ꪝ ꪟ ꪡ ꪣ ꪥ ꪧ ꪩ ꪫ ꪭ ꪯ][ꪫ]?),
					after   => q(),
					replace => q(꪿([ꪱ ꪮ ꪺ ꪽ](?:[ꪀꪂꪄꪆꪈꪊꪌꪎꪐꪒꪔꪖꪘꪚꪜꪞꪠꪢꪤꪦꪨꪪꪬꪮ]|[ꪁꪃꪅꪇꪉꪋꪍꪏꪑꪓꪕꪗꪙꪛꪝꪟꪡꪣꪥꪧꪩꪫꪭꪯ])?)),
					result  => q($1˦),
					revisit => 0,
				},
				{
					before  => q([ꪁ ꪃ ꪅ ꪇ ꪉ ꪋ ꪍ ꪏ ꪑ ꪓ ꪕ ꪗ ꪙ ꪛ ꪝ ꪟ ꪡ ꪣ ꪥ ꪧ ꪩ ꪫ ꪭ ꪯ][ꪫ]?),
					after   => q(),
					replace => q(꫁([ꪱ ꪮ ꪺ ꪽ](?:[ꪀꪂꪄꪆꪈꪊꪌꪎꪐꪒꪔꪖꪘꪚꪜꪞꪠꪢꪤꪦꪨꪪꪬꪮ]|[ꪁꪃꪅꪇꪉꪋꪍꪏꪑꪓꪕꪗꪙꪛꪝꪟꪡꪣꪥꪧꪩꪫꪭꪯ])?)),
					result  => q($1˧˩),
					revisit => 0,
				},
				{
					before  => q([ꪀ ꪂ ꪄ ꪆ ꪈ ꪊ ꪌ ꪎ ꪐ ꪒ ꪔ ꪖ ꪘ ꪚ ꪜ ꪞ ꪠ ꪢ ꪤ ꪦ ꪨ ꪪ ꪬ ꪮ][ꪫ]?(?:[ꪵꪶꪹꪻꪼ]|[ꪴꪰꪲꪳꪷꪸꪾ]|[\{ꪹꪸ\}\{ꪹꪷ\}\{ꪹꪱ\}])),
					after   => q(),
					replace => q(꪿((?:[ꪀꪂꪄꪆꪈꪊꪌꪎꪐꪒꪔꪖꪘꪚꪜꪞꪠꪢꪤꪦꪨꪪꪬꪮ]|[ꪁꪃꪅꪇꪉꪋꪍꪏꪑꪓꪕꪗꪙꪛꪝꪟꪡꪣꪥꪧꪩꪫꪭꪯ])?)),
					result  => q($1˧˥),
					revisit => 0,
				},
				{
					before  => q([ꪀ ꪂ ꪄ ꪆ ꪈ ꪊ ꪌ ꪎ ꪐ ꪒ ꪔ ꪖ ꪘ ꪚ ꪜ ꪞ ꪠ ꪢ ꪤ ꪦ ꪨ ꪪ ꪬ ꪮ][ꪫ]?(?:[ꪵꪶꪹꪻꪼ]|[ꪴꪰꪲꪳꪷꪸꪾ]|[\{ꪹꪸ\}\{ꪹꪷ\}\{ꪹꪱ\}])),
					after   => q(),
					replace => q(꫁((?:[ꪀꪂꪄꪆꪈꪊꪌꪎꪐꪒꪔꪖꪘꪚꪜꪞꪠꪢꪤꪦꪨꪪꪬꪮ]|[ꪁꪃꪅꪇꪉꪋꪍꪏꪑꪓꪕꪗꪙꪛꪝꪟꪡꪣꪥꪧꪩꪫꪭꪯ])?)),
					result  => q($1˨˩),
					revisit => 0,
				},
				{
					before  => q([ꪁ ꪃ ꪅ ꪇ ꪉ ꪋ ꪍ ꪏ ꪑ ꪓ ꪕ ꪗ ꪙ ꪛ ꪝ ꪟ ꪡ ꪣ ꪥ ꪧ ꪩ ꪫ ꪭ ꪯ][ꪫ]?(?:[ꪵꪶꪹꪻꪼ]|[ꪴꪰꪲꪳꪷꪸꪾ]|[\{ꪹꪸ\}\{ꪹꪷ\}\{ꪹꪱ\}])),
					after   => q(),
					replace => q(꪿((?:[ꪀꪂꪄꪆꪈꪊꪌꪎꪐꪒꪔꪖꪘꪚꪜꪞꪠꪢꪤꪦꪨꪪꪬꪮ]|[ꪁꪃꪅꪇꪉꪋꪍꪏꪑꪓꪕꪗꪙꪛꪝꪟꪡꪣꪥꪧꪩꪫꪭꪯ])?)),
					result  => q($1˦),
					revisit => 0,
				},
				{
					before  => q([ꪁ ꪃ ꪅ ꪇ ꪉ ꪋ ꪍ ꪏ ꪑ ꪓ ꪕ ꪗ ꪙ ꪛ ꪝ ꪟ ꪡ ꪣ ꪥ ꪧ ꪩ ꪫ ꪭ ꪯ][ꪫ]?(?:[ꪵꪶꪹꪻꪼ]|[ꪴꪰꪲꪳꪷꪸꪾ]|[\{ꪹꪸ\}\{ꪹꪷ\}\{ꪹꪱ\}])),
					after   => q(),
					replace => q(꫁((?:[ꪀꪂꪄꪆꪈꪊꪌꪎꪐꪒꪔꪖꪘꪚꪜꪞꪠꪢꪤꪦꪨꪪꪬꪮ]|[ꪁꪃꪅꪇꪉꪋꪍꪏꪑꪓꪕꪗꪙꪛꪝꪟꪡꪣꪥꪧꪩꪫꪭꪯ])?)),
					result  => q($1˧˩),
					revisit => 0,
				},
			],
		},
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(null),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q([^[˥ ˦ ˧ ˨ ˩]]),
					replace => q(([ꪀ ꪂ ꪄ ꪆ ꪈ ꪊ ꪌ ꪎ ꪐ ꪒ ꪔ ꪖ ꪘ ꪚ ꪜ ꪞ ꪠ ꪢ ꪤ ꪦ ꪨ ꪪ ꪬ ꪮ][ꪫ]?(?:(?:[ꪵꪶꪹꪻꪼ]|[ꪴꪰꪲꪳꪷꪸꪾ]|[\{ꪹꪸ\}\{ꪹꪷ\}\{ꪹꪱ\}])|[ꪱꪮꪺꪽ])(?:[ꪀꪂꪄꪆꪈꪊꪌꪎꪐꪒꪔꪖꪘꪚꪜꪞꪠꪢꪤꪦꪨꪪꪬꪮ]|[ꪁꪃꪅꪇꪉꪋꪍꪏꪑꪓꪕꪗꪙꪛꪝꪟꪡꪣꪥꪧꪩꪫꪭꪯ])?)),
					result  => q($1˨),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([^[˥ ˦ ˧ ˨ ˩]]),
					replace => q(([ꪁ ꪃ ꪅ ꪇ ꪉ ꪋ ꪍ ꪏ ꪑ ꪓ ꪕ ꪗ ꪙ ꪛ ꪝ ꪟ ꪡ ꪣ ꪥ ꪧ ꪩ ꪫ ꪭ ꪯ][ꪫ]?(?:(?:[ꪵꪶꪹꪻꪼ]|[ꪴꪰꪲꪳꪷꪸꪾ]|[\{ꪹꪸ\}\{ꪹꪷ\}\{ꪹꪱ\}])|[ꪱꪮꪺꪽ])(?:[ꪀꪂꪄꪆꪈꪊꪌꪎꪐꪒꪔꪖꪘꪚꪜꪞꪠꪢꪤꪦꪨꪪꪬꪮ]|[ꪁꪃꪅꪇꪉꪋꪍꪏꪑꪓꪕꪗꪙꪛꪝꪟꪡꪣꪥꪧꪩꪫꪭꪯ])?)),
					result  => q($1˥),
					revisit => 0,
				},
			],
		},
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(null),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q((?:[ꪀꪂꪄꪆꪈꪊꪌꪎꪐꪒꪔꪖꪘꪚꪜꪞꪠꪢꪤꪦꪨꪪꪬꪮ]|[ꪁꪃꪅꪇꪉꪋꪍꪏꪑꪓꪕꪗꪙꪛꪝꪟꪡꪣꪥꪧꪩꪫꪭꪯ])[ꪫ]?(?:(?:[ꪵꪶꪹꪻꪼ]|[ꪴꪰꪲꪳꪷꪸꪾ]|[\{ꪹꪸ\}\{ꪹꪷ\}\{ꪹꪱ\}])|[ꪱꪮꪺꪽ])),
					after   => q(),
					replace => q(ꪒ),
					result  => q(ꪔ),
					revisit => 0,
				},
			],
		},
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(null),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q((?:[ꪀꪂꪄꪆꪈꪊꪌꪎꪐꪒꪔꪖꪘꪚꪜꪞꪠꪢꪤꪦꪨꪪꪬꪮ]|[ꪁꪃꪅꪇꪉꪋꪍꪏꪑꪓꪕꪗꪙꪛꪝꪟꪡꪣꪥꪧꪩꪫꪭꪯ])),
					after   => q((?:(?:[ꪵꪶꪹꪻꪼ]|[ꪴꪰꪲꪳꪷꪸꪾ]|[\{ꪹꪸ\}\{ꪹꪷ\}\{ꪹꪱ\}])|[ꪱꪮꪺꪽ])),
					replace => q([ꪫ]),
					result  => q(ʷ),
					revisit => 0,
				},
			],
		},
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(null),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q(),
					replace => q([ꪀꪁ]),
					result  => q(k),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ꪂꪃ]),
					result  => q(kʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ꪄꪅ]),
					result  => q(x),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ꪆꪇ]),
					result  => q(ɡ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ꪈꪉ]),
					result  => q(ŋ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ꪊꪋ]),
					result  => q(t͡ɕ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ꪌꪍ]),
					result  => q(t͡ɕʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ꪎꪏ]),
					result  => q(s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ꪐꪑ]),
					result  => q(ɲ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ꪒꪓ]),
					result  => q(d),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ꪔꪕ]),
					result  => q(t),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ꪖꪗ]),
					result  => q(tʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ꪘꪙ]),
					result  => q(n),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ꪚꪛ]),
					result  => q(b),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ꪜꪝ]),
					result  => q(p),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ꪞꪟ]),
					result  => q(pʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ꪠꪡ]),
					result  => q(f),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ꪢꪣ]),
					result  => q(m),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ꪤꪥ]),
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ꪦꪧ]),
					result  => q(r),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ꪨꪩ]),
					result  => q(l),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([˥ ˦ ˧ ˨ ˩]),
					replace => q([ꪪꪫ]),
					result  => q(w),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ꪪꪫ]),
					result  => q(v),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ꪬꪭ]),
					result  => q(h),
					revisit => 0,
				},
				{
					before  => q(ʔ),
					after   => q(),
					replace => q([ꪮꪯ]),
					result  => q(ɔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ꪮꪯ]),
					result  => q(ʔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ꪹꪸ),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ꪹꪷ),
					result  => q(ə),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ꪹꪱ),
					result  => q(aːw),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ꪰ),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ꪱ),
					result  => q(aː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ꪲ),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ꪳ),
					result  => q(ɨ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ꪴ),
					result  => q(u),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ꪵ),
					result  => q(ɛ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ꪶ),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ꪷ),
					result  => q(ɔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ꪮ),
					result  => q(ɔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ꪺ),
					result  => q(uə̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ꪽ),
					result  => q(an),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ꪹ),
					result  => q(ɨə̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ꪸ),
					result  => q(iə̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ꪻ),
					result  => q(əw),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ꪼ),
					result  => q(ai̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ꪾ),
					result  => q(am),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ꫛ),
					result  => q(kon˥),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ꫜ),
					result  => q(nɨŋ˦),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
