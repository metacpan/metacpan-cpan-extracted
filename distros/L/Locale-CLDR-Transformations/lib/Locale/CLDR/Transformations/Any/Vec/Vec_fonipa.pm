package Locale::CLDR::Transformations::Any::Vec::Vec_fonipa;
# This file auto generated from Data\common\transforms\vec-vec_FONIPA.xml
#	on Fri 17 Jan 12:03:31 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.46.0');

use v5.12.0;
use mro 'c3';
use utf8;
use feature 'unicode_strings';
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
				{
					from => q(Any),
					to => q(Lower),
				},
				{
					from => q(Any),
					to => q(NFC),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q(),
					replace => q(([abefjklmoptvw])),
					result  => q($1),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([áà]),
					result  => q(ˈa),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?:[aáà]|(?:[eéè]|[iíì])|[oóòuúù])),
					replace => q(c(?:(?:[eéè]|[iíì])|[\'’])),
					result  => q(t͡ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(cé[\'’]?),
					result  => q(t͡ʃˈe),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(cè[\'’]?),
					result  => q(t͡ʃˈɛ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ce[\'’]?),
					result  => q(t͡ʃe),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(c[íì][\'’]?),
					result  => q(t͡ʃˈi),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ci[\'’]?),
					result  => q(t͡ʃi),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([c\N{U+63.68}kq\N{U+71.75}]),
					result  => q(k),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(é),
					result  => q(ˈe),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(è),
					result  => q(ˈɛ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?:[aáà]|(?:[eéè]|[iíì])|[oóòuúù])),
					replace => q(gl(?:[eéè]|[iíì])),
					result  => q(ʎ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(gl),
					result  => q(ʎ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ġ),
					result  => q(d͡ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(gé[\'’]?),
					result  => q(d͡ʒˈe),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(gè[\'’]?),
					result  => q(d͡ʒˈɛ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(g[íì][\'’]?),
					result  => q(d͡ʒˈi),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?:[aáà]|(?:[eéè]|[iíì])|[oóòuúù])),
					replace => q(g(?:(?:[eéè]|[iíì])|[\'’])),
					result  => q(d͡ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?:[eéè]|[iíì])),
					replace => q(g),
					result  => q(d͡ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(gn),
					result  => q(ɲ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([g\N{U+67.68}]),
					result  => q(ɡ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([íì]),
					result  => q(ˈi),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?:[aáà]|(?:[eéè]|[iíì])|[oóòuúù])),
					replace => q(i),
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ł),
					result  => q(ɰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ṅ),
					result  => q(ŋ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ñ),
					result  => q(ɲ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(nj),
					result  => q(ɲ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ó),
					result  => q(ˈo),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ò),
					result  => q(ˈɔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(r),
					result  => q(ɾ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ṡxz]),
					result  => q(z),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([bdg]),
					replace => q(s),
					result  => q(z),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(s),
					result  => q(s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?:[aáà]|(?:[eéè]|[iíì])|[oóòuúù])),
					replace => q(u),
					result  => q(w),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([úù]),
					result  => q(ˈu),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(u),
					result  => q(u),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(y),
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([żđ\N{U+64.68}]),
					result  => q(d͡z),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(d),
					result  => q(d),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([\p{P}\p{Z}]+),
					result  => q(\'),
					revisit => 0,
				},
			],
		},
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(NULL),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q((?:[pbtdkɡfvɾsz]|(?:(?![\p{L}\p{M}\p{N}])(?s:.)))),
					replace => q(n),
					result  => q(ŋ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(ˈ?[ei]),
					replace => q(ɰ),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(eɰ),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(iɰ),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ɰ),
					result  => q(e̯),
					revisit => 0,
				},
			],
		},
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(NULL),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q(),
					replace => q(()ˈ),
					result  => q(ˈ$1),
					revisit => 0,
				},
			],
		},
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(NULL),
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
