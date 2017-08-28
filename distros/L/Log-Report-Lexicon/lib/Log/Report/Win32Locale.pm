# Copyrights 2007-2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package Log::Report::Win32Locale;
use vars '$VERSION';
$VERSION = '1.09';

use base 'Exporter';

use Log::Report 'log-report-lexicon';

our @EXPORT = qw/codepage_to_iso iso_to_codepage
  iso_locale charset_encoding
  ms_codepage_id ms_install_codepage_id ms_locale/;
 
use Win32::TieRegistry;

my %codepage2iso;
my %localewin2iso;
my %charsetwin;
while(<DATA>)
{  my ($codepage, $iso, $localewin, $charsetwin, $name) = split /\,\s*/, $_, 5;
   defined $name or die "Missing field in '$_'";
   $codepage2iso{hex $codepage} = $iso;
   $localewin2iso{$localewin}   = $iso;
   $charsetwin{$localewin}      = $charsetwin;
}
my %iso2codepage = reverse %codepage2iso;
close DATA;


sub codepage_to_iso($)
{   my $cp = shift;
    defined $cp ? $codepage2iso{$cp =~ m/^0x/i ? hex($cp) : $cp} : ();
}
 

sub iso_to_codepage($)
{   my $iso = shift;
    return $iso2codepage{$iso}
        if $iso2codepage{$iso};

    my ($lang) = split $iso, /\_/;
    $iso2codepage{$lang};
}


sub iso_locale(;$)
{   my $locale = shift;
    if(defined $locale)
    {   my $iso = $localewin2iso{$locale} || $codepage2iso{$locale};
        return $iso if $iso;
    }

       codepage_to_iso(ms_codepage_id())
    || codepage_to_iso(ms_locale());
}

# the following functions are rewrites of Win32::Codepage version 1.00
# Copyright 2005 Clotho Advanced Media, Inc.  Under perl license.
# Win32 does not nicely export the functions.

my $nls = 'HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Control/Nls';
my $del = {Access => Win32::TieRegistry::KEY_READ(), Delimiter => '/'};
my $codepages = Win32::TieRegistry->new("$nls/CodePage", $del);
my $languages = Win32::TieRegistry->new("$nls/Language", $del);


sub charset_encoding
{   my $charset = $codepages->GetValue("ACP") || $codepages->GetValue("OEMCP");
    $charset && $charset =~ m/^[0-9a-fA-F]+$/ ? "cp".lc($charset) : undef;
}


sub ms_codepage_id
{   my $id = $languages->GetValue("Default");
    $id && $id =~ m/^[0-9a-fA-F]+$/ ? hex($id) : undef;
}


sub ms_install_codepage_id
{   my $id = $languages->GetValue("InstallLanguage");
    $id && $id =~ m/^[0-9a-fA-F]+$/ ? hex($id) : undef;
}
 
# the following functions are rewrites of Win32::Locale version 0.04
# Copyright (c) 2001,2003 Sean M. Burke,  Under perl license.
# The module seems unmaintained, and treating the 'region' in the ISO
# code as lower-case is a mistake.

my $i18n = Win32::TieRegistry->new
  ("HKEY_CURRENT_USER/Control Panel/International", $del);


sub ms_locale
{   my $locale = $i18n->GetValue("Locale");
    $locale =~ m/^[0-9a-fA-F]+$/ ? hex($locale) : undef;
}

1;

# taken from http://www.microsoft.com/globaldev/nlsweb on 2007/10/22
# merged with http://docs.moodle.org/en/Table_of_locales
# columns: codepage,ISO,localewin,localewincharset,language name

# use a wide terminal and tabstop=8
# After changes, sort with :.,$!sort -t, -k2,2
__DATA__
0x0036,	af,	,				,		Afrikaans
0x0436,	af_ZA,	Afrikaans_South Africa.1252,	WINDOWS-1252,	Afrikaans (South Africa)
0x045E,	am_ET,	,				,		Amharic (Ethiopia)
0x0001,	ar,	,				,		Arabic
0x3801,	ar_AE,	,				,		Arabic (U.A.E.)
0x3C01,	ar_BH,	,				,		Arabic (Bahrain)
0x1401,	ar_DZ,	,				,		Arabic (Algeria)
0x0C01,	ar_EG,	,				,		Arabic (Egypt)
0x0801,	ar_IQ,	,				,		Arabic (Iraq)
0x2C01,	ar_JO,	,				,		Arabic (Jordan)
0x3401,	ar_KW,	,				,		Arabic (Kuwait)
0x3001,	ar_LB,	,				,		Arabic (Lebanon)
0x1001,	ar_LY,	,				,		Arabic (Libya)
0x1801,	ar_MA,	,				,		Arabic (Morocco)
0x047A,	arn_CL,	,				,		Mapudungun (Chile)
0x2001,	ar_OM,	,				,		Arabic (Oman)
0x4001,	ar_QA,	,				,		Arabic (Qatar)
0x0401,	ar_SA,	Arabic_Saudi Arabia.1256,	WINDOWS-1256,	Arabic (Saudi Arabia)
0x2801,	ar_SY,	,				,		Arabic (Syria)
0x1C01,	ar_TN,	,				,		Arabic (Tunisia)
0x2401,	ar_YE,	,				,		Arabic (Yemen)
0x044D,	as_IN,	,				,		Assamese (India)
0x002C,	az,	,				,		Azeri
0x082C,	az_Cyrl_AZ,	,			,		Azeri (Cyrillic, Azerbaijan)
0x042C,	az_Latn_AZ,	,			,		Azeri (Latin, Azerbaijan)
0x046D,	ba_RU,	,				,		Bashkir (Russia)
0x0023,	be,	,				,		Belarusian
0x0423,	be_BY,	Belarusian_Belarus.1251,	WINDOWS-1251,	Belarusian (Belarus)
0x0002,	bg,	Bulgarian_Bulgaria.1251,	WINDOWS-1251,	Bulgarian
0x0402,	bg_BG,	,				,		Bulgarian (Bulgaria)
0x0845,	bn_BD,	,				,		Bengali (Bangladesh)
0x0445,	bn_IN,	Bengali (India),		,		Bengali (India)
0x0451,	bo_CN,	,				,		Tibetan (PRC)
0x047E,	br_FR,	,				,		Breton (France)
0x201A,	bs_Cyrl_BA,	,			,		Bosnian (Cyrillic, Bosnia and Herzegovina)
0x141A,	bs_Latn_BA,	Serbian (Latin),	WINDOWS-1250,	Bosnian (Latin, Bosnia and Herzegovina)
0x0003,	ca,	,				,		Catalan
0x0403,	ca_ES,	Catalan_Spain.1252,		WINDOWS-1252,	Catalan (Catalan)
0x0483,	co_FR,	,				,		Corsican (France)
0x0005,	cs,	,				,		Czech
0x0405,	cs_CZ,	Czech_Czech Republic.1250, 	WINDOWS-1250,	Czech (Czech Republic)
0x0452,	cy_GB,	,				,		Welsh (United Kingdom)
0x0006,	da,	,				,		Danish
0x0406,	da_DK,	Danish_Denmark.1252,	 	WINDOWS-1252,	Danish (Denmark)
0x0007,	de,	,				,		German
0x0C07,	de_AT,	,				,		German (Austria)
0x0807,	de_CH,	,				,		German (Switzerland)
0x0407,	de_DE,	German_Germany.1252,	 	WINDOWS-1252,	German (Germany)
0x1407,	de_LI,	,				,		German (Liechtenstein)
0x1007,	de_LU,	,				,		German (Luxembourg)
0x0065,	div,	,				,		Divehi
0x0465,	div_MV,	,				,		Divehi (Maldives)
0x0008,	el,	,				,		Greek
0x0408,	el_GR,	Greek_Greece.1253,	 	WINDOWS-1253,	Greek (Greece)
0x0009,	en,	,				,		English
0x2409,	en_029,	,				,		English (Caribbean)
0x0C09,	en_AU,	English_Australia.1252,		,		English (Australia)
0x2809,	en_BZ,	,				,		English (Belize)
0x1009,	en_CA,	,				,		English (Canada)
0x0809,	en_GB,	,				,		English (United Kingdom)
0x1809,	en_IE,	,				,		English (Ireland)
0x4009,	en_IN,	,				,		English (India)
0x2009,	en_JM,	,				,		English (Jamaica)
0x4409,	en_MY,	,				,		English (Malaysia)
0x1409,	en_NZ,	,				,		English (New Zealand)
0x3409,	en_PH,	,				,		English (Republic of the Philippines)
0x4809,	en_SG,	,				,		English (Singapore)
0x2C09,	en_TT,	,				,		English (Trinidad and Tobago)
0x0409,	en_US,	,				,		English (United States)
0x1C09,	en_ZA,	,				,		English (South Africa)
0x3009,	en_ZW,	,				,		English (Zimbabwe)
0x000A,	es,	,				,		Spanish
0x2C0A,	es_AR,	,				,		Spanish (Argentina)
0x400A,	es_BO,	,				,		Spanish (Bolivia)
0x340A,	es_CL,	,				,		Spanish (Chile)
0x240A,	es_CO,	,				,		Spanish (Colombia)
0x140A,	es_CR,	,				,		Spanish (Costa Rica)
0x1C0A,	es_DO,	,				,		Spanish (Dominican Republic)
0x300A,	es_EC,	,				,		Spanish (Ecuador)
0x0C0A,	es_ES,	Spanish_Spain.1252,	 	WINDOWS-1252,	Spanish (Spain)
0x100A,	es_GT,	,				,		Spanish (Guatemala)
0x480A,	es_HN,	,				,		Spanish (Honduras)
0x080A,	es_MX,	,				,		Spanish (Mexico)
0x4C0A,	es_NI,	,				,		Spanish (Nicaragua)
0x180A,	es_PA,	,				,		Spanish (Panama)
0x280A,	es_PE,	,				,		Spanish (Peru)
0x500A,	es_PR,	,				,		Spanish (Puerto Rico)
0x3C0A,	es_PY,	,				,		Spanish (Paraguay)
0x440A,	es_SV,	,				,		Spanish (El Salvador)
0x540A,	es_US,	,				,		Spanish (United States)
0x380A,	es_UY,	,				,		Spanish (Uruguay)
0x200A,	es_VE,	,				,		Spanish (Venezuela)
0x0025,	et,	,				,		Estonian
0x0425,	et_EE,	Estonian_Estonia.1257,	 	WINDOWS-1257,	Estonian (Estonia)
0x002D,	eu,	,				,		Basque
0x042D,	eu_ES,	Basque_Spain.1252,		WINDOWS-1252,	Basque (Basque)
0x0029,	fa,	,				,		Persian
0x0429,	fa_IR,	,				,		Persian
,	fa_IR, 	Farsi_Iran.1256,	 	WINDOWS-1256,	Farsi (Iran)
0x000B,	fi,	,				,		Finnish
0x040B,	fi_FI,	Finnish_Finland.1252,	 	WINDOWS-1252,	Finnish (Finland)
0x0464,	fil_PH,	Filipino_Philippines.1252, 	WINDOWS-1252,	Filipino (Philippines)
0x0038,	fo,	,				,		Faroese
0x0438,	fo_FO,	,				,		Faroese (Faroe Islands)
0x000C,	fr,	,				,		French
0x080C,	fr_BE,	,				,		French (Belgium)
0x0C0C,	fr_CA,	,				,		French (Canada)
0x100C,	fr_CH,	,				,		French (Switzerland)
0x040C,	fr_FR,	French_France.1252,	 	WINDOWS-1252,	French (France)
0x140C,	fr_LU,	,				,		French (Luxembourg)
0x180C,	fr_MC,	,				,		French (Principality of Monaco)
0x0462,	fy_NL,	,				,		Frisian (Netherlands)
,	ga,	,				WINDOWS-1252, 	Gaelic; Scottish Gaelic
0x083C,	ga_IE,	,				,		Irish (Ireland)
0x0056,	gl,	,				,		Galician
0x0456,	gl_ES,	,				,		Galician (Galician)
,	gl_ES, 	Galician_Spain.1252,	 	WINDOWS-1252, Gallego
0x0484,	gsw_FR,	,				,		Alsatian (France)
0x0047,	gu,	,				,		Gujarati
0x0447,	gu_IN,	Gujarati_India.0, 		,		Gujarati (India)
0x0468,	ha_Latn_NG,	,			,		Hausa (Latin, Nigeria)
0x000D,	he,	,				,		Hebrew
0x040D,	he_IL,	Hebrew_Israel.1255,	 	WINDOWS-1255,	Hebrew (Israel)
0x0039,	hi,	Hindi.65001,			,		Hindi
0x0439,	hi_IN,	,				,		Hindi (India)
0x001A,	hr,	,				,		Croatian
0x101A,	hr_BA,	,				,		Croatian (Latin, Bosnia and Herzegovina)
0x041A,	hr_HR,	Croatian_Croatia.1250,	 	WINDOWS-1250,	Croatian (Croatia)
0x000E,	hu,	,				,		Hungarian
0x040E,	hu_HU,	Hungarian_Hungary.1250, 	WINDOWS-1250,	Hungarian (Hungary)
0x002B,	hy,	,				,		Armenian
0x042B,	hy_AM,	,				,		Armenian (Armenia)
0x0021,	id,	,				,		Indonesian
0x0421,	id_ID,	Indonesian_indonesia.1252, 	WINDOWS-1252,	Indonesian (Indonesia)
0x0470,	ig_NG,	,				,		Igbo (Nigeria)
0x0478,	ii_CN,	,				,		Yi (PRC)
0x000F,	is,	,				,		Icelandic
0x040F,	is_IS,	Icelandic_Iceland.1252,		WINDOWS-1252,	Icelandic (Iceland)
0x0010,	it,	,				,		Italian
0x0810,	it_CH,	,				,		Italian (Switzerland)
0x0410,	it_IT,	Italian_Italy.1252,	 	WINDOWS-1252,	Italian (Italy)
0x045D,	iu_Cans_CA,	,			,		Inuktitut (Syllabics, Canada)
0x085D,	iu_Latn_CA,	,			,		Inuktitut (Latin, Canada)
0x0011,	ja,	,				,		Japanese
0x0411,	ja_JP,	Japanese_Japan.932,	 	CP932,		Japanese (Japan)
0x0037,	ka,	,				,		Georgian
0x0437,	ka_GE,	,				,		Georgian (Georgia)
,	ka_GE, 	Georgian_Georgia.65001,		,		Georgian
0x003F,	kk,	,				,		Kazakh
0x043F,	kk_KZ,	,				,		Kazakh (Kazakhstan)
0x046F,	kl_GL,	,				,		Greenlandic (Greenland)
, 	km, 	Khmer.65001,			,		Khmer
0x0453,	km_KH,	,				,		Khmer (Cambodia)
0x004B,	kn,	,				,		Kannada
0x044B,	kn_IN,	kn_IN.UTF-8,		 	Kannada.65001,	Kannada (India)
0x0012,	ko,	,				,		Korean
0x0057,	kok,	,				,		Konkani
0x0457,	kok_IN,	,				,		Konkani (India)
0x0412,	ko_KR,	Korean_Korea.949,	 	EUC-KR,		Korean (Korea)
0x0040,	ky,	,				,		Kyrgyz
0x0440,	ky_KG,	,				,		Kyrgyz (Kyrgyzstan)
0x046E,	lb_LU,	,				,		Luxembourgish (Luxembourg)
0x0454,	lo_LA,	Lao_Laos.UTF-8,			WINDOWS-1257,	Lao (Lao P.D.R.)
0x0027,	lt,	,				,		Lithuanian
0x0427,	lt_LT,	Lithuanian_Lithuania.1257, 	WINDOWS-1257,	Lithuanian (Lithuania)
0x0026,	lv,	,				,		Latvian
0x0426,	lv_LV,	Latvian_Latvia.1257,	 	WINDOWS-1257,	Latvian (Latvia)
0x0481,	mi_NZ,	Maori.1252,		 	WINDOWS-1252,	Maori (New Zealand)
0x002F,	mk,	,				,		Macedonian
0x042F,	mk_MK,	,				,		Macedonian (Former Yugoslav Republic of Macedonia)
0x044C,	ml_IN,	Malayalam_India.x-iscii-ma, 	x-iscii-ma,	Malayalam (India)
0x0050,	mn,	,				,		Mongolian
0x0450,	mn_MN,	Cyrillic_Mongolian.1251, 	,		Mongolian (Cyrillic, Mongolia)
0x0850,	mn_Mong_CN,	,			,		Mongolian (Traditional Mongolian, PRC)
0x047C,	moh_CA,	,				,		Mohawk (Mohawk)
0x004E,	mr,	,				,		Marathi
0x044E,	mr_IN,	,				,		Marathi (India)
0x003E,	ms,	,				,		Malay
0x083E,	ms_BN,	,				,		Malay (Brunei Darussalam)
0x043E,	ms_MY,	,				,		Malay (Malaysia)
0x043A,	mt_MT,	,				,		Maltese (Malta)
0x0461,	ne_NP,	,				,		Nepali (Nepal)
0x0013,	nl,	,				,		Dutch
0x0813,	nl_BE,	,				,		Dutch (Belgium)
0x0413,	nl_NL,	Dutch_Netherlands.1252,	 	WINDOWS-1252,	Dutch (Netherlands)
0x0814,	nn_NO,	Norwegian-Nynorsk_Norway.1252, 	WINDOWS-1252,	Norwegian, Nynorsk (Norway)
0x0014,	no,	,				,		Norwegian
0x0414,	no_NO,	Norwegian_Norway.1252,	 	WINDOWS-1252,	Norwegian, Bokmål (Norway)
0x046C,	nso_ZA,	,				,		Sesotho sa Leboa (South Africa)
0x0482,	oc_FR,	,				,		Occitan (France)
0x0448,	or_IN,	,				,		Oriya (India)
0x0046,	pa,	,				,		Punjabi
0x0446,	pa_IN,	,				,		Punjabi (India)
0x0015,	pl,	,				,		Polish
0x0415,	pl_PL,	Polish_Poland.1250,	 	WINDOWS-1250,	Polish (Poland)
0x048C,	prs_AF,	,				,		Dari (Afghanistan)
0x0463,	ps_AF,	,				,		Pashto (Afghanistan)
0x0016,	pt,	,				,		Portuguese
0x0416,	pt_BR,	Portuguese_Brazil.1252,		WINDOWS-1252,	Portuguese (Brazil)
0x0816,	pt_PT,	Portuguese_Portugal.1252, 	WINDOWS-1252,	Portuguese (Portugal)
0x0486,	qut_GT,	,				,		K'iche (Guatemala)
0x046B,	quz_BO,	,				,		Quechua (Bolivia)
0x086B,	quz_EC,	,				,		Quechua (Ecuador)
0x0C6B,	quz_PE,	,				,		Quechua (Peru)
0x0417,	rm_CH,	,				,		Romansh (Switzerland)
0x0018,	ro,	,				,		Romanian
0x0418,	ro_RO,	Romanian_Romania.1250,	 	WINDOWS-1250,	Romanian (Romania)
0x0019,	ru,	,				,		Russian
0x0419,	ru_RU,	Russian_Russia.1251,	 	WINDOWS-1251,	Russian (Russia)
0x0487,	rw_RW,	,				,		Kinyarwanda (Rwanda)
0x004F,	sa,	,				,		Sanskrit
0x0485,	sah_RU,	,				,		Yakut (Russia)
0x044F,	sa_IN,	,				,		Sanskrit (India)
0x0C3B,	se_FI,	,				,		Sami, Northern (Finland)
0x043B,	se_NO,	,				,		Sami, Northern (Norway)
0x083B,	se_SE,	,				,		Sami, Northern (Sweden)
0x045B,	si_LK,	,				,		Sinhala (Sri Lanka)
0x001B,	sk,	,				,		Slovak
0x041B,	sk_SK,	Slovak_Slovakia.1250,	 	WINDOWS-1250,	Slovak (Slovakia)
0x0024,	sl,	,				,		Slovenian
0x0424,	sl_SI,	Slovenian_Slovenia.1250,	WINDOWS-1250,	Slovenian (Slovenia)
0x183B,	sma_NO,	,				,		Sami, Southern (Norway)
0x1C3B,	sma_SE,	,				,		Sami, Southern (Sweden)
0x103B,	smj_NO,	,				,		Sami, Lule (Norway)
0x143B,	smj_SE,	,				,		Sami, Lule (Sweden)
0x243B,	smn_FI,	,				,		Sami, Inari (Finland)
0x203B,	sms_FI,	,				,		Sami, Skolt (Finland)
,	so_SO,	,				,		Somali (Somalia)
0x001C,	sq,	,				,		Albanian
0x041C,	sq_AL,	Albanian_Albania.1250,		WINDOWS-1250,	Albanian (Albania)
0x7C1A,	sr,	,				,		Serbian
0x1C1A,	sr_Cyrl_BA,Serbian (Cyrillic)_Serbia and Montenegro.1251,WINDOWS-1251,Serbian (Cyrillic, Bosnia and Herzegovina)
0x0C1A,	sr_Cyrl_SP,	,			,		Serbian (Cyrillic, Serbia)
0x181A,	sr_Latn_BA,	,			,		Serbian (Latin, Bosnia and Herzegovina)
0x081A,	sr_Latn_SP,	,			,		Serbian (Latin, Serbia)
0x001D,	sv,	,				,		Swedish
0x081D,	sv_FI,	,				,		Swedish (Finland)
0x041D,	sv_SE,	Swedish_Sweden.1252,	 	WINDOWS-1252,	Swedish (Sweden)
0x0041,	sw,	,				,		Kiswahili
0x0441,	sw_KE,	,				,		Kiswahili (Kenya)
0x005A,	syr,	,				,		Syriac
0x045A,	syr_SY,	,				,		Syriac (Syria)
0x0049,	ta,	,				,		Tamil
0x0449,	ta_IN,	,				,		Tamil (India)
0x004A,	te,	,				,		Telugu
0x044A,	te_IN,	,				,		Telugu (India)
0x0428,	tg_Cyrl_TJ,	,			,		Tajik (Cyrillic, Tajikistan)
0x001E,	th,	,				,		Thai
0x041E,	th_TH,	Thai_Thailand.874,		WINDOWS-874,	Thai (Thailand)
0x0442,	tk_TM,	,				,		Turkmen (Turkmenistan)
0x085F,	tmz_Latn_DZ,	,			,		Tamazight (Latin, Algeria)
0x0432,	tn_ZA,	,				,		Setswana (South Africa)
0x001F,	tr,	,				,		Turkish
0x041F,	tr_TR,	Turkish_Turkey.1254,	 	WINDOWS-1254,	Turkish (Turkey)
0x0044,	tt,	,				,		Tatar
0x0444,	tt_RU,	,				,		Tatar (Russia)
0x0480,	ug_CN,	,				,		Uighur (PRC)
0x0022,	uk,	,				,		Ukrainian
0x0422,	uk_UA,	Ukrainian_Ukraine.1251,	 	WINDOWS-1251,	Ukrainian (Ukraine)
0x0020,	ur,	,				,		Urdu
0x0420,	ur_PK,	,				,		Urdu (Islamic Republic of Pakistan)
0x0043,	uz,	,				,		Uzbek
0x0843,	uz_Cyrl_UZ,	,			,		Uzbek (Cyrillic, Uzbekistan)
0x0443,	uz_Latn_UZ,	,			,		Uzbek (Latin, Uzbekistan)
0x002A,	vi,	,				,		Vietnamese
0x042A,	vi_VN,	Vietnamese_Viet Nam.1258, 	WINDOWS-1258,	Vietnamese (Vietnam)
0x082E,	wee_DE,	,				,		Lower Sorbian (Germany)
0x042E,	wen_DE,	,				,		Upper Sorbian (Germany)
0x0488,	wo_SN,	,				,		Wolof (Senegal)
0x0434,	xh_ZA,	,				,		isiXhosa (South Africa)
0x046A,	yo_NG,	,				,		Yoruba (Nigeria)
0x0804,	zh_CN,	Chinese_China.936,	 	CP936,		Chinese (People's Republic of China)
0x0004,	zh_Hans,,				,		Chinese (Simplified)
0x7C04,	zh_Hant,,				,		Chinese (Traditional)
0x0C04,	zh_HK,	,				,		Chinese (Hong Kong S.A.R.)
0x1404,	zh_MO,	,				,		Chinese (Macao S.A.R.)
0x1004,	zh_SG,	,				,		Chinese (Singapore)
0x0404,	zh_TW,	Chinese_Taiwan.950,	 	CP950,		Chinese (Taiwan)
0x0435,	zu_ZA,	,				,		siZulu (South Africa)
