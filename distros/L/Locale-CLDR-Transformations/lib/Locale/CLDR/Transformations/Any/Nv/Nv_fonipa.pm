package Locale::CLDR::Transformations::Any::Nv::Nv_fonipa;
# This file auto generated from Data\common\transforms\nv-nv_FONIPA.xml
#	on Sun  7 Oct 10:18:24 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.1');

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
					replace => q(ą́ą́),
					result  => q(ɑ̃́ː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(áá),
					result  => q(ɑ́ː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ąą),
					result  => q(ɑ̃ː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(aa),
					result  => q(ɑː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ą́),
					result  => q(ɑ̃́),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(á),
					result  => q(ɑ́),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ą),
					result  => q(ɑ̃),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(a),
					result  => q(ɑ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ę́ę́),
					result  => q(ẽ́ː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(éé),
					result  => q(éː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ęę),
					result  => q(ẽː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ee),
					result  => q(eː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ę́),
					result  => q(ẽ́),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(é),
					result  => q(é),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ę),
					result  => q(ẽ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(e),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(į́į́),
					result  => q(ɪ̃́ː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(íí),
					result  => q(ɪ́ː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(įį),
					result  => q(ɪ̃ː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ii),
					result  => q(ɪː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(į́),
					result  => q(ɪ̃́),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(í),
					result  => q(ɪ́),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(į),
					result  => q(ɪ̃),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(i),
					result  => q(ɪ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ǫ́ǫ́),
					result  => q(ṍː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(óó),
					result  => q(óː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ǫǫ),
					result  => q(õː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(oo),
					result  => q(oː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ǫ́),
					result  => q(ṍ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ó),
					result  => q(ó),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ǫ),
					result  => q(õ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(o),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([’ ʼ \']),
					result  => q(ʔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(b),
					result  => q(p),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ch[’ ʼ \']),
					result  => q(t͡ʃʼ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ch),
					result  => q(t͡ʃʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(dl),
					result  => q(tˡ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(dz),
					result  => q(t͡s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(d),
					result  => q(t),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(gh),
					result  => q(ɣ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(g),
					result  => q(k),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(hw),
					result  => q(xʷ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(h),
					result  => q(h),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(j),
					result  => q(t͡ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(k[’ ʼ \']),
					result  => q(kʼ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(kw),
					result  => q(k͡xʷ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(k),
					result  => q(k͡x),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(l),
					result  => q(l),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ł),
					result  => q(ɬ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(m),
					result  => q(m),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(n),
					result  => q(n),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(sh),
					result  => q(ʃ),
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
					after   => q(),
					replace => q(tł[’ ʼ \']),
					result  => q(t͡ɬʼ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(tł),
					result  => q(t͡ɬʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ts[’ ʼ \']),
					result  => q(t͡sʼ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ts),
					result  => q(t͡sʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(t[’ ʼ \']),
					result  => q(tʼ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(t),
					result  => q(t͡x),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(w),
					result  => q(w),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(x),
					result  => q(x),
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
					replace => q(zh),
					result  => q(ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(z),
					result  => q(z),
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
					after   => q([\N{U+1E4D}\N{U+F3}\N{U+F5}\N{U+6F}]),
					replace => q(ɣ),
					result  => q(ɣʷ),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
