package Enum::Declare::Common::TimezoneOffset;

use 5.014;
use strict;
use warnings;

use Enum::Declare;

# ── UTC offsets in seconds ──

enum Offset :Type :Export {
	# ── UTC / GMT ──
	UTC   =      0,
	GMT   =      0,

	# ── North America ──
	EST   = -18000,
	EDT   = -14400,
	CST   = -21600,
	CDT   = -18000,
	MST   = -25200,
	MDT   = -21600,
	PST   = -28800,
	PDT   = -25200,
	AKST  = -32400,
	AKDT  = -28800,
	HST   = -36000,
	AST   = -14400,
	ADT   = -10800,
	NST   = -12600,
	NDT   =  -9000,

	# ── Europe ──
	CET   =   3600,
	CEST  =   7200,
	EET   =   7200,
	EEST  =  10800,
	WET   =      0,
	WEST  =   3600,
	BST   =   3600,
	IST_IE =  3600,
	MSK   =  10800,
	AZOT  =  -3600,

	# ── South America ──
	BRT   = -10800,
	BRST  =  -7200,
	ART   = -10800,
	CLT   = -14400,
	CLST  = -10800,
	COT   = -18000,
	PET   = -18000,
	VET   = -16200,
	ECT   = -18000,
	BOT   = -14400,
	PYT   = -14400,
	PYST  = -10800,
	UYT   = -10800,
	GFT   = -10800,
	SRT   = -10800,
	FNT   =  -7200,

	# ── Africa ──
	SAST  =   7200,
	EAT   =  10800,
	WAT   =   3600,
	CAT   =   7200,
	WAST  =   7200,
	MUT   =  14400,
	SCT   =  14400,
	RET   =  14400,
	CVT   =  -3600,

	# ── Middle East ──
	IRST  =  12600,
	IRDT  =  16200,
	GST   =  14400,
	AFT   =  16200,
	IST   =  19800,
	PKT   =  18000,
	NPT   =  20700,

	# ── South / Southeast Asia ──
	BDT   =  21600,
	MMT   =  23400,
	ICT   =  25200,
	WIB   =  25200,
	WITA  =  28800,
	WIT   =  32400,
	MYT   =  28800,
	PHT   =  28800,
	SGT   =  28800,
	HKT   =  28800,
	TLT   =  32400,

	# ── East Asia ──
	JST   =  32400,
	KST   =  32400,
	CST_CN = 28800,
	UZT   =  18000,
	KGT   =  21600,
	TKT   =  18000,

	# ── Russia ──
	SAMT  =  14400,
	YEKT  =  18000,
	OMST  =  21600,
	KRAT  =  25200,
	IRKT  =  28800,
	YAKT  =  32400,
	VLAT  =  36000,
	MAGT  =  39600,
	PETT  =  43200,

	# ── Australia ──
	AWST  =  28800,
	AWDT  =  32400,
	ACST  =  34200,
	ACDT  =  37800,
	AEST  =  36000,
	AEDT  =  39600,
	LHST  =  37800,

	# ── Pacific ──
	NZST  =  43200,
	NZDT  =  46800,
	FJT   =  43200,
	FJST  =  46800,
	TOT   =  46800,
	SST   = -39600,
	CHST  =  36000,
	PONT  =  39600,
	NCT   =  39600,
	CKT   = -36000,
	LINT  =  50400,
	WST_P =  46800,

	# ── Atlantic / Indian ──
	IOT   =  21600,
	MVT   =  18000,
	TFT   =  18000
};

1;

=head1 NAME

Enum::Declare::Common::TimezoneOffset - UTC offsets in seconds for arithmetic

=head1 SYNOPSIS

    use Enum::Declare::Common::TimezoneOffset;

    say EST;  # -18000
    say JST;  #  32400

    # Convert UTC epoch to local time
    my $local = $utc_epoch + EST;

    # Compare offsets
    ok(JST > EST);  # true

=head1 ENUMS

=head2 Offset :Export

Approximately 107 timezone abbreviation constants with UTC offset values
in seconds. Matches L<Enum::Declare::Common::Timezone> entries.

Disambiguated names: C<IST_IE> (Irish), C<WST_P> (Pacific Samoa).

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 LNATION. Artistic License 2.0.

=cut
