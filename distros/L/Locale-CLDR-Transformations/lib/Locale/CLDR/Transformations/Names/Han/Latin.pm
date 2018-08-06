package Locale::CLDR::Transformations::Names::Han::Latin;
# This file auto generated from Data\common\transforms\Han-Latin-Names.xml
#	on Sun  5 Aug  5:49:15 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.0');

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
					before  => q(\p{^script=Han}),
					after   => q(),
					replace => q(([:script=Han:])),
					result  => q(﷑$1),
					revisit => 0,
				},
			],
		},
		{
			type => 'transform',
			data => [
				{
					from => q(Han),
					to => q(Spacedhan),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q( ?狐),
					replace => q(令),
					result  => q(líng),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q( ?俟),
					replace => q(万),
					result  => q(mò),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q( ?台),
					replace => q(澹),
					result  => q(tán),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q( ?孙),
					replace => q(长),
					result  => q(zhǎng),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q(),
					replace => q(秘),
					result  => q(bì),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q(),
					replace => q(卜),
					result  => q(bǔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(长),
					result  => q(cháng),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q(),
					replace => q(种),
					result  => q(chóng),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q(),
					replace => q(重),
					result  => q(chóng),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q(),
					replace => q(刀),
					result  => q(diāo),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(干),
					result  => q(gān),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(葛),
					result  => q(gě),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q(),
					replace => q(盖),
					result  => q(gě),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q(),
					replace => q(过),
					result  => q(guō),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q(),
					replace => q(华),
					result  => q(huà),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q(),
					replace => q(纪),
					result  => q(jǐ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(筠),
					result  => q(jūn),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(靓),
					result  => q(liàng),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q(),
					replace => q(牟),
					result  => q(mù),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q(),
					replace => q(粘),
					result  => q(nián),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q(),
					replace => q(区),
					result  => q(ōu),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q(),
					replace => q(繁),
					result  => q(pó),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(仇),
					result  => q(qiú),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q(),
					replace => q(任),
					result  => q(rén),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q(),
					replace => q(单),
					result  => q(shàn),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q(),
					replace => q(召),
					result  => q(shào),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q(),
					replace => q(折),
					result  => q(shé),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q(),
					replace => q(舍),
					result  => q(shè),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q(),
					replace => q(沈),
					result  => q(shěn),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(峙),
					result  => q(shì),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(隗),
					result  => q(wěi),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q(),
					replace => q(解),
					result  => q(xiè),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(莘),
					result  => q(xīn),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q(),
					replace => q(燕),
					result  => q(yān),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q(),
					replace => q(尉),
					result  => q(yù),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q(),
					replace => q(乐),
					result  => q(yuè),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q(),
					replace => q(员),
					result  => q(yùn),
					revisit => 0,
				},
				{
					before  => q(﷑),
					after   => q(),
					replace => q(查),
					result  => q(zhā),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(翟),
					result  => q(zhái),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(曾),
					result  => q(zēng),
					revisit => 0,
				},
			],
		},
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(Null),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q([^$]),
					after   => q(),
					replace => q(﷑),
					result  => q(\u0020),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(﷑),
					result  => q(),
					revisit => 0,
				},
			],
		},
		{
			type => 'transform',
			data => [
				{
					from => q(Han),
					to => q(Latin),
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
