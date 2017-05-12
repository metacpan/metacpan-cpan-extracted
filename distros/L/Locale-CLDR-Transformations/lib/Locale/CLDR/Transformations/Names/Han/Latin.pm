package Locale::CLDR::Transformations::Names::Han::Latin;
# This file auto generated from Data\common\transforms\Han-Latin-Names.xml
#	on Fri 29 Apr  6:48:41 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

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
					before  => q((?^u:\p{^script=Han})),
					after   => q(),
					replace => q((?^u:(\p{script=Han}))),
					result  => q(\uFDD1$1),
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
					after   => q((?^u: ?狐)),
					replace => q((?^u:令)),
					result  => q(líng),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u: ?俟)),
					replace => q((?^u:万)),
					result  => q(mò),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u: ?台)),
					replace => q((?^u:澹)),
					result  => q(tán),
					revisit => 0,
				},
				{
					before  => q((?^u:﷑)),
					after   => q((?^u: ?孙)),
					replace => q((?^u:长)),
					result  => q(zhǎng),
					revisit => 0,
				},
				{
					before  => q((?^u:﷑)),
					after   => q(),
					replace => q((?^u:秘)),
					result  => q(bì),
					revisit => 0,
				},
				{
					before  => q((?^u:﷑)),
					after   => q(),
					replace => q((?^u:卜)),
					result  => q(bǔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:长)),
					result  => q(cháng),
					revisit => 0,
				},
				{
					before  => q((?^u:﷑)),
					after   => q(),
					replace => q((?^u:种)),
					result  => q(chóng),
					revisit => 0,
				},
				{
					before  => q((?^u:﷑)),
					after   => q(),
					replace => q((?^u:重)),
					result  => q(chóng),
					revisit => 0,
				},
				{
					before  => q((?^u:﷑)),
					after   => q(),
					replace => q((?^u:刀)),
					result  => q(diāo),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:干)),
					result  => q(gān),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:葛)),
					result  => q(gě),
					revisit => 0,
				},
				{
					before  => q((?^u:﷑)),
					after   => q(),
					replace => q((?^u:盖)),
					result  => q(gě),
					revisit => 0,
				},
				{
					before  => q((?^u:﷑)),
					after   => q(),
					replace => q((?^u:过)),
					result  => q(guō),
					revisit => 0,
				},
				{
					before  => q((?^u:﷑)),
					after   => q(),
					replace => q((?^u:华)),
					result  => q(huà),
					revisit => 0,
				},
				{
					before  => q((?^u:﷑)),
					after   => q(),
					replace => q((?^u:纪)),
					result  => q(jǐ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:筠)),
					result  => q(jūn),
					revisit => 0,
				},
				{
					before  => q((?^u:﷑)),
					after   => q(),
					replace => q((?^u:牟)),
					result  => q(mù),
					revisit => 0,
				},
				{
					before  => q((?^u:﷑)),
					after   => q(),
					replace => q((?^u:区)),
					result  => q(ōu),
					revisit => 0,
				},
				{
					before  => q((?^u:﷑)),
					after   => q(),
					replace => q((?^u:繁)),
					result  => q(pó),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:仇)),
					result  => q(qiú),
					revisit => 0,
				},
				{
					before  => q((?^u:﷑)),
					after   => q(),
					replace => q((?^u:任)),
					result  => q(rén),
					revisit => 0,
				},
				{
					before  => q((?^u:﷑)),
					after   => q(),
					replace => q((?^u:单)),
					result  => q(shàn),
					revisit => 0,
				},
				{
					before  => q((?^u:﷑)),
					after   => q(),
					replace => q((?^u:召)),
					result  => q(shào),
					revisit => 0,
				},
				{
					before  => q((?^u:﷑)),
					after   => q(),
					replace => q((?^u:折)),
					result  => q(shé),
					revisit => 0,
				},
				{
					before  => q((?^u:﷑)),
					after   => q(),
					replace => q((?^u:舍)),
					result  => q(shè),
					revisit => 0,
				},
				{
					before  => q((?^u:﷑)),
					after   => q(),
					replace => q((?^u:沈)),
					result  => q(shěn),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:峙)),
					result  => q(shì),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:隗)),
					result  => q(wěi),
					revisit => 0,
				},
				{
					before  => q((?^u:﷑)),
					after   => q(),
					replace => q((?^u:解)),
					result  => q(xiè),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:莘)),
					result  => q(xīn),
					revisit => 0,
				},
				{
					before  => q((?^u:﷑)),
					after   => q(),
					replace => q((?^u:燕)),
					result  => q(yān),
					revisit => 0,
				},
				{
					before  => q((?^u:﷑)),
					after   => q(),
					replace => q((?^u:尉)),
					result  => q(yù),
					revisit => 0,
				},
				{
					before  => q((?^u:﷑)),
					after   => q(),
					replace => q((?^u:乐)),
					result  => q(yuè),
					revisit => 0,
				},
				{
					before  => q((?^u:﷑)),
					after   => q(),
					replace => q((?^u:员)),
					result  => q(yùn),
					revisit => 0,
				},
				{
					before  => q((?^u:﷑)),
					after   => q(),
					replace => q((?^u:查)),
					result  => q(zhā),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:翟)),
					result  => q(zhái),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:曾)),
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
					before  => q((?^u:[^$])),
					after   => q(),
					replace => q((?^u:﷑)),
					result  => q(\u0020),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:﷑)),
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
