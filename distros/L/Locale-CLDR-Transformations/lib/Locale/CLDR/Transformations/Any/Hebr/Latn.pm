package Locale::CLDR::Transformations::Any::Hebr::Latn;
# This file auto generated from Data\common\transforms\Hebrew-Latin.xml
#	on Fri 29 Apr  6:48:42 pm GMT

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
		qr/(?^umi:\G(?^u:(?[[\p{Hebrew} + \p{^ccc=0}] + [ְ-ֹֻ-ּׁ-ׂℵ-ℸֿ̄]-[ֽ]])))/,
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(nfkd),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ח)),
					result  => q(ẖ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:צ)),
					result  => q(ẕ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ץ)),
					result  => q(ẕ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ש)),
					result  => q(ş),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ת)),
					result  => q(ţ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:א)),
					result  => q(ʼ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ב)),
					result  => q(b),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ג)),
					result  => q(g),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ד)),
					result  => q(d),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ה)),
					result  => q(h),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ו)),
					result  => q(w),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ז)),
					result  => q(z),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ט)),
					result  => q(t),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:י)),
					result  => q(y),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:כ)),
					result  => q(k),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ך)),
					result  => q(k),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ל)),
					result  => q(l),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:מ)),
					result  => q(m),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ם)),
					result  => q(m),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:נ)),
					result  => q(n),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ן)),
					result  => q(n),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ס)),
					result  => q(s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ע)),
					result  => q(ʻ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:פ)),
					result  => q(p),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ף)),
					result  => q(p),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ק)),
					result  => q(q),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ר)),
					result  => q(r),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:װ)),
					result  => q(),
					revisit => 2,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ױ)),
					result  => q(),
					revisit => 2,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ײ)),
					result  => q(),
					revisit => 2,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ּ)),
					result  => q(̇),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ׁ)),
					result  => q(̌),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ׂ)),
					result  => q(̂),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:‎ֲ‎)),
					result  => q(à),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:‎ָ‎)),
					result  => q(á),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:‎ֱ‎)),
					result  => q(è),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:‎ֵ‎)),
					result  => q(é),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:‎ְ‎)),
					result  => q(ĕ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:‎ֹ‎)),
					result  => q(ò),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ִ)),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ֻ)),
					result  => q(u),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ַ)),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ֶ)),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ֳ)),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ֿ)),
					result  => q(̄),
					revisit => 0,
				},
			],
		},
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(nfc),
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
