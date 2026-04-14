package Enum::Declare::Common::Locale;

use 5.014;
use strict;
use warnings;

use Enum::Declare;

enum Lang :Str :Type :Export {
	# ── English ──
	EN = "en",
	EN_US = "en_US",
	EN_GB = "en_GB",
	EN_AU = "en_AU",
	EN_CA = "en_CA",
	EN_NZ = "en_NZ",
	EN_IE = "en_IE",
	EN_ZA = "en_ZA",
	EN_IN = "en_IN",
	EN_SG = "en_SG",

	# ── Western Europe ──
	FR = "fr",
	FR_FR = "fr_FR",
	FR_CA = "fr_CA",
	FR_BE = "fr_BE",
	FR_CH = "fr_CH",
	DE = "de",
	DE_DE = "de_DE",
	DE_AT = "de_AT",
	DE_CH = "de_CH",
	ES = "es",
	ES_ES = "es_ES",
	ES_MX = "es_MX",
	ES_AR = "es_AR",
	ES_CO = "es_CO",
	ES_CL = "es_CL",
	ES_PE = "es_PE",
	PT = "pt",
	PT_BR = "pt_BR",
	PT_PT = "pt_PT",
	IT = "it",
	IT_IT = "it_IT",
	NL = "nl",
	NL_NL = "nl_NL",
	NL_BE = "nl_BE",
	CA = "ca",

	# ── Nordic ──
	SV = "sv",
	SV_SE = "sv_SE",
	DA = "da",
	DA_DK = "da_DK",
	NO = "no",
	NB = "nb",
	NB_NO = "nb_NO",
	NN = "nn",
	NN_NO = "nn_NO",
	FI = "fi",
	FI_FI = "fi_FI",
	IS = "is",
	IS_IS = "is_IS",

	# ── Eastern Europe ──
	PL = "pl",
	PL_PL = "pl_PL",
	CS = "cs",
	CS_CZ = "cs_CZ",
	SK = "sk",
	SK_SK = "sk_SK",
	HU = "hu",
	HU_HU = "hu_HU",
	RO = "ro",
	RO_RO = "ro_RO",
	BG = "bg",
	BG_BG = "bg_BG",
	HR = "hr",
	HR_HR = "hr_HR",
	SR = "sr",
	SR_RS = "sr_RS",
	SL = "sl",
	SL_SI = "sl_SI",
	UK = "uk",
	UK_UA = "uk_UA",
	RU = "ru",
	RU_RU = "ru_RU",
	BE = "be",
	BE_BY = "be_BY",
	LT = "lt",
	LT_LT = "lt_LT",
	LV = "lv",
	LV_LV = "lv_LV",
	ET = "et",
	ET_EE = "et_EE",

	# ── Greek / Turkish / Other European ──
	EL = "el",
	EL_GR = "el_GR",
	TR = "tr",
	TR_TR = "tr_TR",
	SQ = "sq",
	SQ_AL = "sq_AL",
	MK = "mk",
	MK_MK = "mk_MK",
	BS = "bs",
	BS_BA = "bs_BA",
	MT = "mt",
	MT_MT = "mt_MT",
	GA = "ga",
	GA_IE = "ga_IE",
	CY = "cy",
	CY_GB = "cy_GB",
	EU = "eu",
	GL = "gl",

	# ── East Asia ──
	ZH = "zh",
	ZH_CN = "zh_CN",
	ZH_TW = "zh_TW",
	ZH_HK = "zh_HK",
	JA = "ja",
	JA_JP = "ja_JP",
	KO = "ko",
	KO_KR = "ko_KR",
	MN = "mn",

	# ── Southeast Asia ──
	VI = "vi",
	VI_VN = "vi_VN",
	TH = "th",
	TH_TH = "th_TH",
	ID = "id",
	ID_ID = "id_ID",
	MS = "ms",
	MS_MY = "ms_MY",
	TL = "tl",
	TL_PH = "tl_PH",
	KM = "km",
	LO = "lo",
	MY_MM = "my_MM",

	# ── South Asia ──
	HI = "hi",
	HI_IN = "hi_IN",
	BN = "bn",
	BN_BD = "bn_BD",
	BN_IN = "bn_IN",
	TA = "ta",
	TA_IN = "ta_IN",
	TE = "te",
	TE_IN = "te_IN",
	ML = "ml",
	KN = "kn",
	GU = "gu",
	MR = "mr",
	PA = "pa",
	SI = "si",
	NE = "ne",
	UR = "ur",
	UR_PK = "ur_PK",

	# ── Middle East / Central Asia ──
	AR = "ar",
	AR_SA = "ar_SA",
	AR_EG = "ar_EG",
	AR_AE = "ar_AE",
	AR_MA = "ar_MA",
	FA = "fa",
	FA_IR = "fa_IR",
	HE = "he",
	HE_IL = "he_IL",
	KA = "ka",
	KA_GE = "ka_GE",
	HY = "hy",
	HY_AM = "hy_AM",
	AZ = "az",
	AZ_AZ = "az_AZ",
	KK = "kk",
	UZ = "uz",
	KY = "ky",
	TK = "tk",
	TG = "tg",

	# ── Africa ──
	SW = "sw",
	SW_KE = "sw_KE",
	SW_TZ = "sw_TZ",
	AM = "am",
	AM_ET = "am_ET",
	HA = "ha",
	YO = "yo",
	IG = "ig",
	ZU = "zu",
	AF = "af",
	AF_ZA = "af_ZA",
	RW = "rw",
	MG = "mg",
	SO = "so"
};

1;

=head1 NAME

Enum::Declare::Common::Locale - Language and locale tag constants

=head1 SYNOPSIS

    use Enum::Declare::Common::Locale;

    say EN_US;  # "en_US"
    say FR_FR;  # "fr_FR"
    say JA_JP;  # "ja_JP"

    my $meta = Lang();
    ok($meta->valid('en_US'));

=head1 ENUMS

=head2 Lang :Str :Export

Over 180 locale tags covering English, Western Europe, Nordic, Eastern
Europe, Greek/Turkish, East Asia, Southeast Asia, South Asia, Middle
East/Central Asia, and Africa. Constants are uppercase (e.g. C<EN_US>,
C<NO>, C<IS>).

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 LNATION. Artistic License 2.0.

=cut
