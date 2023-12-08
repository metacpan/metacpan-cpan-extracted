package Locale::CLDR::Transformations::Bgn_1981::Ka::Ka_latn;
# This file auto generated from Data\common\transforms\Georgian-Latin-BGN_1981.xml
#	on Tue  5 Dec 12:59:00 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.4');

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
		qr/(?^umi:\G[აბგდევზთიკლმნოპჟრსტუფქღყშჩცძწჭხჯჰ])/,
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(NFD),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q(),
					replace => q(ა),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ბ),
					result  => q(b),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(გ),
					result  => q(g),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(დ),
					result  => q(d),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ე),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ვ),
					result  => q(v),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ზ),
					result  => q(z),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(თ),
					result  => q(t’),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ი),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(კ),
					result  => q(k),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ლ),
					result  => q(l),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(მ),
					result  => q(m),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ნ),
					result  => q(n),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ო),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(პ),
					result  => q(p),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ჟ),
					result  => q(zh),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(რ),
					result  => q(r),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ს),
					result  => q(s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ტ),
					result  => q(t),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(უ),
					result  => q(u),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ფ),
					result  => q(p’),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ქ),
					result  => q(k’),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ღ),
					result  => q(gh),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ყ),
					result  => q(q),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(შ),
					result  => q(sh),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ჩ),
					result  => q(ch’),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ც),
					result  => q(ts’),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ძ),
					result  => q(dz),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(წ),
					result  => q(ts),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ჭ),
					result  => q(ch),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ხ),
					result  => q(kh),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ჯ),
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ჰ),
					result  => q(h),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
