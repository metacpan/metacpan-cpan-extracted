package Locale::CLDR::Transformations::Gurage_2013::Ethi::Sgw_ethi;
# This file auto generated from Data\common\transforms\sgw-Ethi-t-und-ethi.xml
#	on Sun 25 Feb 10:41:40 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.0');

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
					replace => q(𞟾),
					result  => q(ᎎ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟽),
					result  => q(ᎍ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟼),
					result  => q(ᎊ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟻),
					result  => q(ᎉ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ጞ),
					result  => q(ⷞ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ጝ),
					result  => q(ⷝ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ጜ),
					result  => q(ⷜ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ጛ),
					result  => q(ⷛ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ጚ),
					result  => q(ⷚ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ጙ),
					result  => q(ⷙ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ጘ),
					result  => q(ⷘ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟺),
					result  => q(ጕ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟹),
					result  => q(ጔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟸),
					result  => q(ጒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟦),
					result  => q(ⷖ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟥),
					result  => q(ⷕ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟤),
					result  => q(ⷔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟣),
					result  => q(ⷓ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟢),
					result  => q(ⷒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟡),
					result  => q(ⷑ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟠),
					result  => q(ⷐ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ኾ),
					result  => q(ⷎ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ኽ),
					result  => q(ⷍ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ኼ),
					result  => q(ⷌ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ኻ),
					result  => q(ⷋ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ኺ),
					result  => q(ⷊ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ኹ),
					result  => q(ⷉ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ኸ),
					result  => q(ⷈ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟫),
					result  => q(ዅ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟪),
					result  => q(ዄ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ሗ),
					result  => q(ዃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟩),
					result  => q(ዂ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟨),
					result  => q(ዀ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ሖ),
					result  => q(ኾ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ሕ),
					result  => q(ኽ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ሔ),
					result  => q(ኼ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ሓ),
					result  => q(ኻ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ሒ),
					result  => q(ኺ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ሑ),
					result  => q(ኹ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ሐ),
					result  => q(ኸ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟷),
					result  => q(ኵ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟶),
					result  => q(ኴ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟵),
					result  => q(ኲ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ኣ),
					result  => q(አ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(አ),
					result  => q(ኧ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ቖ),
					result  => q(ⷆ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ቕ),
					result  => q(ⷅ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ቔ),
					result  => q(ⷄ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ቓ),
					result  => q(ⷃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ቒ),
					result  => q(ⷂ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ቑ),
					result  => q(ⷁ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ቐ),
					result  => q(ⷀ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟴),
					result  => q(ᎆ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟳),
					result  => q(ᎅ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟲),
					result  => q(ቍ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟱),
					result  => q(ቌ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟰),
					result  => q(ቊ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟮),
					result  => q(ᎂ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𞟭),
					result  => q(ᎁ),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
