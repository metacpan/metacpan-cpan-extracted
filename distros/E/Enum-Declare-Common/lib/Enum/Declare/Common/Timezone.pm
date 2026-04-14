package Enum::Declare::Common::Timezone;

use 5.014;
use strict;
use warnings;

use Enum::Declare;

enum Zone :Str :Type :Export {
	# ── UTC / GMT ──
	UTC   = "UTC",
	GMT   = "GMT",

	# ── North America ──
	EST   = "EST",
	EDT   = "EDT",
	CST   = "CST",
	CDT   = "CDT",
	MST   = "MST",
	MDT   = "MDT",
	PST   = "PST",
	PDT   = "PDT",
	AKST  = "AKST",
	AKDT  = "AKDT",
	HST   = "HST",
	AST   = "AST",
	ADT   = "ADT",
	NST   = "NST",
	NDT   = "NDT",

	# ── Europe ──
	CET   = "CET",
	CEST  = "CEST",
	EET   = "EET",
	EEST  = "EEST",
	WET   = "WET",
	WEST  = "WEST",
	BST   = "BST",
	IST_IE = "IST",
	MSK   = "MSK",
	AZOT  = "AZOT",

	# ── South America ──
	BRT   = "BRT",
	BRST  = "BRST",
	ART   = "ART",
	CLT   = "CLT",
	CLST  = "CLST",
	COT   = "COT",
	PET   = "PET",
	VET   = "VET",
	ECT   = "ECT",
	BOT   = "BOT",
	PYT   = "PYT",
	PYST  = "PYST",
	UYT   = "UYT",
	GFT   = "GFT",
	SRT   = "SRT",
	FNT   = "FNT",

	# ── Africa ──
	SAST  = "SAST",
	EAT   = "EAT",
	WAT   = "WAT",
	CAT   = "CAT",
	WAST  = "WAST",
	MUT   = "MUT",
	SCT   = "SCT",
	RET   = "RET",
	CVT   = "CVT",

	# ── Middle East ──
	IRST  = "IRST",
	IRDT  = "IRDT",
	GST   = "GST",
	AFT   = "AFT",
	IST   = "IST",
	PKT   = "PKT",
	NPT   = "NPT",

	# ── South / Southeast Asia ──
	BDT   = "BDT",
	MMT   = "MMT",
	ICT   = "ICT",
	WIB   = "WIB",
	WITA  = "WITA",
	WIT   = "WIT",
	MYT   = "MYT",
	PHT   = "PHT",
	SGT   = "SGT",
	HKT   = "HKT",
	TLT   = "TLT",

	# ── East Asia ──
	JST   = "JST",
	KST   = "KST",
	CST_CN = "CST",
	UZT   = "UZT",
	KGT   = "KGT",
	TKT   = "TKT",

	# ── Russia ──
	SAMT  = "SAMT",
	YEKT  = "YEKT",
	OMST  = "OMST",
	KRAT  = "KRAT",
	IRKT  = "IRKT",
	YAKT  = "YAKT",
	VLAT  = "VLAT",
	MAGT  = "MAGT",
	PETT  = "PETT",

	# ── Australia ──
	AWST  = "AWST",
	AWDT  = "AWDT",
	ACST  = "ACST",
	ACDT  = "ACDT",
	AEST  = "AEST",
	AEDT  = "AEDT",
	LHST  = "LHST",

	# ── Pacific ──
	NZST  = "NZST",
	NZDT  = "NZDT",
	FJT   = "FJT",
	FJST  = "FJST",
	TOT   = "TOT",
	SST   = "SST",
	CHST  = "CHST",
	PONT  = "PONT",
	NCT   = "NCT",
	CKT   = "CKT",
	LINT  = "LINT",
	WST   = "WST",

	# ── Atlantic / Indian ──
	IOT   = "IOT",
	MVT   = "MVT",
	TFT   = "TFT"
};

1;

=head1 NAME

Enum::Declare::Common::Timezone - Timezone abbreviation constants

=head1 SYNOPSIS

    use Enum::Declare::Common::Timezone;

    say UTC;   # "UTC"
    say EST;   # "EST"
    say JST;   # "JST"

    my $meta = Zone();
    ok($meta->valid('UTC'));

=head1 ENUMS

=head2 Zone :Str :Export

Approximately 107 timezone abbreviation constants organized by region:
UTC/GMT, North America, Europe, South America, Africa, Middle East,
South/Southeast Asia, East Asia, Russia, Australia, Pacific, and
Atlantic/Indian Ocean.

Disambiguated names: C<IST_IE> (Irish), C<CST_CN> (China).

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 LNATION. Artistic License 2.0.

=cut

1;
