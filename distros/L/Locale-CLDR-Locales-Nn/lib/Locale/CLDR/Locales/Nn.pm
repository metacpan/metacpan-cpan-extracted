=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Nn - Package for language Norwegian Nynorsk

=cut

package Locale::CLDR::Locales::Nn;
# This file auto generated from Data\common\main\nn.xml
#	on Thu 29 Feb  5:43:51 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.1');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::No');
has 'valid_algorithmic_formats' => (
    is => 'ro',
    isa => ArrayRef,
    init_arg => undef,
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-neuter','spellout-cardinal-masculine','spellout-cardinal-feminine','spellout-cardinal-reale' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'spellout-cardinal-feminine' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-reale=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-reale=),
				},
			},
		},
		'spellout-cardinal-masculine' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-reale=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-reale=),
				},
			},
		},
		'spellout-cardinal-neuter' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(null),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← komma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(eitt),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-cardinal-reale=),
				},
				'max' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-cardinal-reale=),
				},
			},
		},
		'spellout-cardinal-reale' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(null),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← komma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(éin),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(to),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tre),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(fire),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(fem),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(seks),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sju),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(åtte),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(ni),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(ti),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(elleve),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(tolv),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(tretten),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(fjorten),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(femten),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(seksten),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(sytten),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(atten),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(nitten),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(tjue[­→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(tretti[­→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(førti[­→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(femti[­→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(seksti[­→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sytti[­→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(åtti[­→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(nitti[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-neuter← hundre[ og →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-neuter← tusen[ og →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(éin million[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← millionar[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(éin milliard[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← milliardar[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(éin billion[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← billionar[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(éin billiard[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← biliardar[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
			},
		},
		'spellout-numbering' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-reale=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-reale=),
				},
			},
		},
		'spellout-numbering-year' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
				'1100' => {
					base_value => q(1100),
					divisor => q(100),
					rule => q(←← hundre[ og →→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(=%spellout-numbering=),
				},
				'max' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(=%spellout-numbering=),
				},
			},
		},
    } },
);

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'alt' => 'sør-altaj',
 				'ang' => 'gammalengelsk',
 				'asa' => 'asu (Tanzania)',
 				'bas' => 'basa',
 				'bss' => 'bakossi',
 				'car' => 'carib',
 				'chg' => 'tsjagataisk',
 				'ckb' => 'sorani',
 				'crj' => 'sørleg aust-cree',
 				'crl' => 'nordleg aust-cree',
 				'crs' => 'seselwa (fransk-kreolsk)',
 				'cu' => 'kyrkjeslavisk',
 				'cv' => 'tsjuvansk',
 				'den' => 'slavej',
 				'dsb' => 'lågsorbisk',
 				'ebu' => 'embu',
 				'egy' => 'gammalegyptisk',
 				'elx' => 'elamite',
 				'fil' => 'filippinsk',
 				'fro' => 'gammalfransk',
 				'frs' => 'austfrisisk',
 				'fur' => 'friulisk',
 				'gmh' => 'mellomhøgtysk',
 				'goh' => 'gammalhøgtysk',
 				'grc' => 'gammalgresk',
 				'gv' => 'manx',
 				'hax' => 'sørleg haida',
 				'hsb' => 'høgsorbisk',
 				'ikt' => 'vestleg kanadisk inuktitut',
 				'kl' => 'grønlandsk (kalaallisut)',
 				'krc' => 'karatsjaiisk-balkarsk',
 				'kum' => 'kumyk',
 				'lad' => 'ladino',
 				'lez' => 'lezghian',
 				'lrc' => 'nord-lurisk',
 				'lus' => 'lushai',
 				'luy' => 'olulujia',
 				'mfe' => 'morisyen',
 				'mg' => 'madagassisk',
 				'mul' => 'fleire språk',
 				'mzn' => 'mazanderani',
 				'nds' => 'lågtysk',
 				'nds_NL' => 'lågsaksisk',
 				'ne' => 'nepalsk',
 				'niu' => 'niuisk',
 				'nog' => 'nogai',
 				'non' => 'gammalnorsk',
 				'nqo' => 'n’ko',
 				'nso' => 'nordsotho',
 				'nwc' => 'klassisk newarisk',
 				'ojb' => 'nordvestleg ojibwa',
 				'ojw' => 'vestleg ojibwa',
 				'pcm' => 'nigeriansk pidgin',
 				'peo' => 'gammalpersisk',
 				'pro' => 'gammalprovençalsk',
 				'quc' => 'k’iche',
 				'ro_MD' => 'moldavisk',
 				'rup' => 'arumensk',
 				'sc' => 'sardinsk',
 				'sga' => 'gammalirsk',
 				'slh' => 'sørleg lushootseed',
 				'srn' => 'sranan tongo',
 				'st' => 'sørsotho',
 				'swb' => 'shimaore',
 				'syr' => 'syrisk',
 				'tce' => 'sørleg tutchone',
 				'tiv' => 'tivi',
 				'tkl' => 'tokelau',
 				'tn' => 'tswana',
 				'tog' => 'tonga (Nyasa)',
 				'ttm' => 'nordleg tutchone',
 				'tvl' => 'tuvalu',
 				'tyv' => 'tuvinisk',
 				'tzm' => 'sentral-tamazight',
 				'udm' => 'udmurt',
 				'war' => 'waray',
 				'xal' => 'kalmykisk',
 				'zap' => 'zapotec',
 				'zbl' => 'blissymbol',
 				'zgh' => 'standard marokkansk tamazight',
 				'zh_Hans' => 'forenkla kinesisk',
 				'zh_Hans@alt=long' => 'forenkla mandarinkinesisk',
 				'zxx' => 'utan språkleg innhald',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
		}
	},
);

has 'display_name_script' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		sub {
			my %scripts = (
			'Armi' => 'armisk',
 			'Bamu' => 'bamun',
 			'Cans' => 'felles kanadiske urspråksstavingar',
 			'Cyrs' => 'kyrillisk (kyrkjeslavisk variant)',
 			'Egyp' => 'egyptiske hieroglyfar',
 			'Geok' => 'khutsuri (asomtavruli og nuskhuri)',
 			'Gran' => 'gammaltamilsk',
 			'Hanb' => 'hanb',
 			'Hans' => 'forenkla',
 			'Hans@alt=stand-alone' => 'forenkla han',
 			'Hmng' => 'pahawk hmong',
 			'Hrkt' => 'japanske stavingsskrifter',
 			'Hung' => 'gammalungarsk',
 			'Ital' => 'gammalitalisk',
 			'Latf' => 'latinsk (frakturvariant)',
 			'Latg' => 'latinsk (gælisk variant)',
 			'Limb' => 'lumbu',
 			'Lisu' => 'Fraser',
 			'Maya' => 'maya-hieroglyfar',
 			'Perm' => 'gammalpermisk',
 			'Phlp' => 'salmepahlavi',
 			'Sarb' => 'gammalsydarabisk',
 			'Sgnw' => 'teiknskrift',
 			'Syrc' => 'syriakisk',
 			'Syre' => 'syriakisk (estrangelo-variant)',
 			'Syrj' => 'syriakisk (vestleg variant)',
 			'Syrn' => 'syriakisk (austleg variant)',
 			'Thaa' => 'thaana',
 			'Visp' => 'synleg tale',
 			'Xpeo' => 'gammalpersisk',
 			'Xsux' => 'sumero-akkadisk kileskrift',
 			'Zinh' => 'nedarva',
 			'Zsym' => 'symbol',
 			'Zxxx' => 'språk utan skrift',
 			'Zzzz' => 'ukjend skrift',

			);
			if ( @_ ) {
				return $scripts{$_[0]};
			}
			return \%scripts;
		}
	}
);

has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'001' => 'verda',
 			'013' => 'Sentral-Amerika',
 			'014' => 'Aust-Afrika',
 			'018' => 'Sørlege Afrika',
 			'021' => 'Nordlege Amerika',
 			'030' => 'Aust-Asia',
 			'035' => 'Søraust-Asia',
 			'151' => 'Aust-Europa',
 			'AE' => 'Dei sameinte arabiske emirata',
 			'AT' => 'Austerrike',
 			'CC' => 'Kokosøyane',
 			'CD' => 'Kongo-Kinshasa',
 			'CF' => 'Den sentralafrikanske republikken',
 			'CI' => 'Elfenbeinskysten',
 			'CK' => 'Cookøyane',
 			'DO' => 'Den dominikanske republikken',
 			'EU' => 'Den europeiske unionen',
 			'EZ' => 'eurosona',
 			'FK' => 'Falklandsøyane',
 			'FK@alt=variant' => 'Falklandsøyane (Islas Malvinas)',
 			'FO' => 'Færøyane',
 			'GS' => 'Sør-Georgia og Sør-Sandwichøyane',
 			'HM' => 'Heardøya og McDonaldøyane',
 			'IC' => 'Kanariøyane',
 			'IO@alt=chagos' => 'Chagosøyane',
 			'KM' => 'Komorane',
 			'KY' => 'Caymanøyane',
 			'LU' => 'Luxembourg',
 			'MH' => 'Marshalløyane',
 			'MP' => 'Nord-Marianane',
 			'MV' => 'Maldivane',
 			'NO' => 'Noreg',
 			'PH' => 'Filippinane',
 			'PN' => 'Pitcairn',
 			'SB' => 'Salomonøyane',
 			'SC' => 'Seychellane',
 			'SH' => 'Saint Helena',
 			'TC' => 'Turks- og Caicosøyane',
 			'TF' => 'Dei franske sørterritoria',
 			'TL' => 'Aust-Timor',
 			'TL@alt=variant' => 'Aust-Timor',
 			'UM' => 'USAs ytre småøyar',
 			'UN' => 'Sameinte nasjonar',
 			'UN@alt=short' => 'SN',
 			'VC' => 'St. Vincent og Grenadinane',
 			'VG' => 'Dei britiske Jomfruøyane',
 			'VI' => 'Dei amerikanske Jomfruøyane',
 			'XA' => 'pseudospråk – aksentar',
 			'XB' => 'pseudospråk – RTL',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1996' => 'tysk ortografi frå 1996',
 			'1606NICT' => 'nyare mellomfransk til 1606',
 			'AREVELA' => 'austarmensk',
 			'AREVMDA' => 'vestarmensk',
 			'BAKU1926' => 'samla tyrkisk-latinsk alfabet',
 			'FONIPA' => 'det internasjonale fonetiske alfabetet (IPA)',
 			'FONUPA' => 'det uralske fonetiske alfabetet (UPA)',
 			'LIPAW' => 'resian, lipovazdialekt',
 			'REVISED' => 'revidert rettskriving',
 			'SAAHO' => 'saaho-dialekt',
 			'SCOUSE' => 'scouse-dialekt',
 			'VALENCIA' => 'valensisk dialekt',
 			'WADEGILE' => 'wade-giles',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'colalternate' => 'ignorer sortering etter symbol',
 			'colcasefirst' => 'organisering av store og små bokstavar',
 			'colcaselevel' => 'sortering av store og små bokstavar',
 			'collation' => 'sorteringsrekkjefølgje',
 			'colnormalization' => 'normalisert sortering',
 			'colnumeric' => 'numerisk sortering',
 			'colstrength' => 'sorteringsstyrke',
 			'lb' => 'lineskiftstil',
 			'numbers' => 'tal',

		}
	},
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'cf' => {
 				'account' => q{valutaformat for rekneskapsføring},
 			},
 			'collation' => {
 				'big5han' => q{tradisjonell kinesisk sortering},
 				'ducet' => q{standard Unicode-sorteringsrekkjefølgje},
 				'gb2312han' => q{forenkla kinesisk sortering},
 				'pinyin' => q{pinyin-sortering},
 				'standard' => q{standard sorteringsrekkjefølgje},
 			},
 			'd0' => {
 				'fwidth' => q{full breidd},
 				'hwidth' => q{halv breidd},
 			},
 			'hc' => {
 				'h11' => q{12-timarssystem (0–11)},
 				'h12' => q{12-timarssystem (1–12)},
 				'h23' => q{24-timarssystem (0–23)},
 				'h24' => q{24-timarssystem (1–24)},
 			},
 			'lb' => {
 				'loose' => q{laus lineskiftstil},
 				'normal' => q{normal lineskiftstil},
 				'strict' => q{streng lineskiftstil},
 			},
 			'numbers' => {
 				'arab' => q{arabisk-indiske siffer},
 				'arabext' => q{utvida arabisk-indiske siffer},
 				'armn' => q{armenske tal},
 				'armnlow' => q{små armenske tal},
 				'beng' => q{bengalske siffer},
 				'deva' => q{devanagari-siffer},
 				'ethi' => q{etiopiske tal},
 				'fullwide' => q{siffer med full breidd},
 				'geor' => q{georgiske tal},
 				'grek' => q{greske tal},
 				'greklow' => q{små greske tal},
 				'gujr' => q{gujarati-siffer},
 				'guru' => q{gurmukhi-siffer},
 				'hanidec' => q{kinesiske desimaltal},
 				'hans' => q{forenkla kinesiske tal},
 				'hansfin' => q{forenkla kinesiske finanstal},
 				'hant' => q{tradisjonelle kinesiske tal},
 				'hantfin' => q{tradisjonelle kinesiske finanstal},
 				'hebr' => q{hebraiske tal},
 				'java' => q{javanesiske siffer},
 				'jpan' => q{japanske tal},
 				'jpanfin' => q{japanske finanstal},
 				'khmr' => q{khmer-siffer},
 				'knda' => q{kannada-siffer},
 				'laoo' => q{laotiske siffer},
 				'latn' => q{vestlege siffer},
 				'mlym' => q{malayalam-siffer},
 				'mtei' => q{meetei mayek-siffer},
 				'mymr' => q{burmesiske siffer},
 				'native' => q{språkspesifikke siffer},
 				'orya' => q{odia-siffer},
 				'roman' => q{romartal},
 				'romanlow' => q{små romartal},
 				'taml' => q{tamilske tal},
 				'tamldec' => q{tamilske siffer},
 				'telu' => q{telugu-siffer},
 				'thai' => q{thailandske siffer},
 				'tibt' => q{tibetanske siffer},
 				'vaii' => q{vai-siffer},
 			},

		}
	},
);

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'UK' => q{britisk},

		}
	},
);

has 'characters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> $^V ge v5.18.0
	? eval <<'EOT'
	sub {
		no warnings 'experimental::regex_sets';
		return {
			auxiliary => qr{[áǎ čç đ èê ńñ ŋ š ŧ ü ž ä ö]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'1' => q(feminine),
						'one' => q({0} g-kraft),
						'other' => q({0} g-krefter),
					},
					# Core Unit Identifier
					'g-force' => {
						'1' => q(feminine),
						'one' => q({0} g-kraft),
						'other' => q({0} g-krefter),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'one' => q({0} meter per sekund²),
						'other' => q({0} meter per sekund²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'one' => q({0} meter per sekund²),
						'other' => q({0} meter per sekund²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'one' => q({0} bogeminutt),
						'other' => q({0} bogeminutt),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'one' => q({0} bogeminutt),
						'other' => q({0} bogeminutt),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(bogesekund),
						'one' => q({0} bogesekund),
						'other' => q({0} bogesekund),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(bogesekund),
						'one' => q({0} bogesekund),
						'other' => q({0} bogesekund),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'one' => q({0} radian),
						'other' => q({0} radianar),
					},
					# Core Unit Identifier
					'radian' => {
						'one' => q({0} radian),
						'other' => q({0} radianar),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'1' => q(feminine),
						'name' => q(omdreiing),
						'one' => q({0} omdreiing),
						'other' => q({0} omdreiingar),
					},
					# Core Unit Identifier
					'revolution' => {
						'1' => q(feminine),
						'name' => q(omdreiing),
						'one' => q({0} omdreiing),
						'other' => q({0} omdreiingar),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(kvadrattommar),
						'one' => q({0} kvadrattomme),
						'other' => q({0} kvadrattommar),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(kvadrattommar),
						'one' => q({0} kvadrattomme),
						'other' => q({0} kvadrattommar),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'1' => q(feminine),
						'name' => q(engelske kvadratmil),
						'one' => q({0} engelsk kvadratmil),
						'other' => q({0} engelske kvadratmil),
						'per' => q({0} per engelske kvadratmil),
					},
					# Core Unit Identifier
					'square-mile' => {
						'1' => q(feminine),
						'name' => q(engelske kvadratmil),
						'one' => q({0} engelsk kvadratmil),
						'other' => q({0} engelske kvadratmil),
						'per' => q({0} per engelske kvadratmil),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(element),
						'one' => q({0} element),
						'other' => q({0} element),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(element),
						'one' => q({0} element),
						'other' => q({0} element),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'1' => q(neuter),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'1' => q(neuter),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(delar per million),
						'one' => q({0} milliondel),
						'other' => q({0} milliondelar),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(delar per million),
						'one' => q({0} milliondel),
						'other' => q({0} milliondelar),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'1' => q(feminine),
						'name' => q(engelske mil per gallon),
						'one' => q({0} engelsk mil per gallon),
						'other' => q({0} engelske mil per gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'1' => q(feminine),
						'name' => q(engelske mil per gallon),
						'one' => q({0} engelsk mil per gallon),
						'other' => q({0} engelske mil per gallon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'1' => q(feminine),
						'name' => q(engelske mil per britiske gallon),
						'one' => q({0} engelsk mil per britiske gallon),
						'other' => q({0} engelske mil per britiske gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'1' => q(feminine),
						'name' => q(engelske mil per britiske gallon),
						'one' => q({0} engelsk mil per britiske gallon),
						'other' => q({0} engelske mil per britiske gallon),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} aust),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} aust),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(hundreår),
						'one' => q({0} hundreår),
						'other' => q({0} hundreår),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(hundreår),
						'one' => q({0} hundreår),
						'other' => q({0} hundreår),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0} time),
						'other' => q({0} timar),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0} time),
						'other' => q({0} timar),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrosekund),
						'one' => q({0} mikrosekund),
						'other' => q({0} mikrosekund),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrosekund),
						'one' => q({0} mikrosekund),
						'other' => q({0} mikrosekund),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisekund),
						'one' => q({0} millisekund),
						'other' => q({0} millisekund),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisekund),
						'one' => q({0} millisekund),
						'other' => q({0} millisekund),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minutt),
						'one' => q({0} minutt),
						'other' => q({0} minutt),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minutt),
						'one' => q({0} minutt),
						'other' => q({0} minutt),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0} månad),
						'other' => q({0} månadar),
						'per' => q({0} per månad),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0} månad),
						'other' => q({0} månadar),
						'per' => q({0} per månad),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosekund),
						'one' => q({0} nanosekund),
						'other' => q({0} nanosekund),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosekund),
						'one' => q({0} nanosekund),
						'other' => q({0} nanosekund),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekund),
						'one' => q({0} sekund),
						'other' => q({0} sekund),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekund),
						'one' => q({0} sekund),
						'other' => q({0} sekund),
					},
					# Long Unit Identifier
					'duration-week' => {
						'1' => q(feminine),
						'one' => q({0} veke),
						'other' => q({0} veker),
						'per' => q({0} per veke),
					},
					# Core Unit Identifier
					'week' => {
						'1' => q(feminine),
						'one' => q({0} veke),
						'other' => q({0} veker),
						'per' => q({0} per veke),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'one' => q({0} ampere),
						'other' => q({0} ampere),
					},
					# Core Unit Identifier
					'ampere' => {
						'one' => q({0} ampere),
						'other' => q({0} ampere),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(British thermal units),
						'one' => q({0} British thermal unit),
						'other' => q({0} British thermal units),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(British thermal units),
						'one' => q({0} British thermal unit),
						'other' => q({0} British thermal units),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kaloriar),
						'one' => q({0} kalori),
						'other' => q({0} kaloriar),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kaloriar),
						'one' => q({0} kalori),
						'other' => q({0} kaloriar),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(kaloriar),
						'one' => q({0} kalori),
						'other' => q({0} kaloriar),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(kaloriar),
						'one' => q({0} kalori),
						'other' => q({0} kaloriar),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'one' => q({0} joule),
						'other' => q({0} joule),
					},
					# Core Unit Identifier
					'joule' => {
						'one' => q({0} joule),
						'other' => q({0} joule),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kilokaloriar),
						'one' => q({0} kilokalori),
						'other' => q({0} kilokaloriar),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kilokaloriar),
						'one' => q({0} kilokalori),
						'other' => q({0} kilokaloriar),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilowattimar),
						'one' => q({0} kilowattime),
						'other' => q({0} kilowattimar),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilowattimar),
						'one' => q({0} kilowattime),
						'other' => q({0} kilowattimar),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'one' => q({0} poundforce),
						'other' => q({0} poundforce),
					},
					# Core Unit Identifier
					'pound-force' => {
						'one' => q({0} poundforce),
						'other' => q({0} poundforce),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'one' => q({0} punkt),
						'other' => q({0} punkt),
					},
					# Core Unit Identifier
					'dot' => {
						'one' => q({0} punkt),
						'other' => q({0} punkt),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(punkt per centimeter),
						'one' => q({0} punkt per centimeter),
						'other' => q({0} punkt per centimeter),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(punkt per centimeter),
						'one' => q({0} punkt per centimeter),
						'other' => q({0} punkt per centimeter),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(punkt per tomme),
						'one' => q({0} punkt per tomme),
						'other' => q({0} punkt per tomme),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(punkt per tomme),
						'one' => q({0} punkt per tomme),
						'other' => q({0} punkt per tomme),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'one' => q({0} megapiksel),
						'other' => q({0} megapikslar),
					},
					# Core Unit Identifier
					'megapixel' => {
						'one' => q({0} megapiksel),
						'other' => q({0} megapikslar),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'one' => q({0} piksel),
						'other' => q({0} pikslar),
					},
					# Core Unit Identifier
					'pixel' => {
						'one' => q({0} piksel),
						'other' => q({0} pikslar),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(pikslar per centimeter),
						'one' => q({0} piksel per centimeter),
						'other' => q({0} pikslar per centimeter),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(pikslar per centimeter),
						'one' => q({0} piksel per centimeter),
						'other' => q({0} pikslar per centimeter),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pikslar per tomme),
						'one' => q({0} piksel per tomme),
						'other' => q({0} pikslar per tomme),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pikslar per tomme),
						'one' => q({0} piksel per tomme),
						'other' => q({0} pikslar per tomme),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(astronomiske einingar),
						'one' => q({0} astronomisk eining),
						'other' => q({0} astronomiske einingar),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(astronomiske einingar),
						'one' => q({0} astronomisk eining),
						'other' => q({0} astronomiske einingar),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'one' => q({0} jordradius),
						'other' => q({0} jordradius),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'one' => q({0} jordradius),
						'other' => q({0} jordradius),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'one' => q({0} famn),
						'other' => q({0} famner),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0} famn),
						'other' => q({0} famner),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(meter),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(meter),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q({0} engelsk mil),
						'other' => q({0} engelske mil),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0} engelsk mil),
						'other' => q({0} engelske mil),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'1' => q(feminine),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'1' => q(feminine),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(typografiske punkt),
						'one' => q({0} typografisk punkt),
						'other' => q({0} typografiske punkt),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(typografiske punkt),
						'one' => q({0} typografisk punkt),
						'other' => q({0} typografiske punkt),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(solradius),
						'one' => q({0} solradius),
						'other' => q({0} solradius),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(solradius),
						'one' => q({0} solradius),
						'other' => q({0} solradius),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0} engelsk yard),
						'other' => q({0} engelske yard),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0} engelsk yard),
						'other' => q({0} engelske yard),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'one' => q({0} solluminositet),
						'other' => q({0} solluminositetar),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'one' => q({0} solluminositet),
						'other' => q({0} solluminositetar),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(jordmassar),
						'one' => q({0} jordmasse),
						'other' => q({0} jordmassar),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(jordmassar),
						'one' => q({0} jordmasse),
						'other' => q({0} jordmassar),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'1' => q(feminine),
					},
					# Core Unit Identifier
					'ounce' => {
						'1' => q(feminine),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'one' => q({0} solmasse),
						'other' => q({0} solmassar),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'one' => q({0} solmasse),
						'other' => q({0} solmassar),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(engelske stones),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(engelske stones),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0} amerikansk tonn),
						'other' => q({0} amerikanske tonn),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0} amerikansk tonn),
						'other' => q({0} amerikanske tonn),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atmosfærar),
						'one' => q({0} atmosfære),
						'other' => q({0} atmosfærar),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atmosfærar),
						'one' => q({0} atmosfære),
						'other' => q({0} atmosfærar),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(tommar kvikksølv),
						'one' => q({0} tomme kvikksølv),
						'other' => q({0} tommar kvikksølv),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(tommar kvikksølv),
						'one' => q({0} tomme kvikksølv),
						'other' => q({0} tommar kvikksølv),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'1' => q(feminine),
						'name' => q(engelske mil per time),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'1' => q(feminine),
						'name' => q(engelske mil per time),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(pound-feet),
						'one' => q({0} pound-force-foot),
						'other' => q({0} pound-feet),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(pound-feet),
						'one' => q({0} pound-force-foot),
						'other' => q({0} pound-feet),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q({0} bushel),
						'other' => q({0} bushels),
					},
					# Core Unit Identifier
					'bushel' => {
						'one' => q({0} bushel),
						'other' => q({0} bushels),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(kubikktommar),
						'one' => q({0} kubikktomme),
						'other' => q({0} kubikktommar),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(kubikktommar),
						'one' => q({0} kubikktomme),
						'other' => q({0} kubikktommar),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'1' => q(feminine),
						'name' => q(engelske kubikkmil),
						'one' => q({0} kubikkmile),
						'other' => q({0} engelske kubikkmil),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'1' => q(feminine),
						'name' => q(engelske kubikkmil),
						'one' => q({0} kubikkmile),
						'other' => q({0} engelske kubikkmil),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'one' => q({0} kubikkyard),
						'other' => q({0} kubikkyard),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'one' => q({0} kubikkyard),
						'other' => q({0} kubikkyard),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'one' => q({0} kopp),
						'other' => q({0} koppar),
					},
					# Core Unit Identifier
					'cup' => {
						'one' => q({0} kopp),
						'other' => q({0} koppar),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(metriske koppar),
						'one' => q({0} metrisk kopp),
						'other' => q({0} metriske koppar),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(metriske koppar),
						'one' => q({0} metrisk kopp),
						'other' => q({0} metriske koppar),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'1' => q(feminine),
						'name' => q(dessertskei),
						'one' => q({0} dessertskei),
						'other' => q({0} dessertskeier),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'1' => q(feminine),
						'name' => q(dessertskei),
						'one' => q({0} dessertskei),
						'other' => q({0} dessertskeier),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'1' => q(feminine),
						'name' => q(britisk dessertskei),
						'one' => q({0} britisk dessertskei),
						'other' => q({0} britisk dessertskei),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'1' => q(feminine),
						'name' => q(britisk dessertskei),
						'one' => q({0} britisk dessertskei),
						'other' => q({0} britisk dessertskei),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'one' => q({0} drope),
						'other' => q({0} dropar),
					},
					# Core Unit Identifier
					'drop' => {
						'one' => q({0} drope),
						'other' => q({0} dropar),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'1' => q(feminine),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'1' => q(feminine),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'1' => q(feminine),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'1' => q(feminine),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'per' => q({0} per britiske gallon),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'per' => q({0} per britiske gallon),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'1' => q(feminine),
					},
					# Core Unit Identifier
					'pinch' => {
						'1' => q(feminine),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'1' => q(feminine),
						'name' => q(matskeier),
						'one' => q({0} matskei),
						'other' => q({0} matskeier),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'1' => q(feminine),
						'name' => q(matskeier),
						'one' => q({0} matskei),
						'other' => q({0} matskeier),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'1' => q(feminine),
						'name' => q(teskeier),
						'one' => q({0} teskei),
						'other' => q({0} teskeier),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'1' => q(feminine),
						'name' => q(teskeier),
						'one' => q({0} teskei),
						'other' => q({0} teskeier),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(bogemin),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(bogemin),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(bogesek),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(bogesek),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'per' => q({0}/mile²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'per' => q({0}/mile²),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100 km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(miles/gal),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(miles/gal),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(miles/brit. gal),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(miles/brit. gal),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'per' => q({0}/h),
					},
					# Core Unit Identifier
					'hour' => {
						'per' => q({0}/h),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(månad),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(månad),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(vk.),
						'one' => q({0}v),
						'other' => q({0}v),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(vk.),
						'one' => q({0}v),
						'other' => q({0}v),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'one' => q({0} unse),
						'other' => q({0} unser),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q({0} unse),
						'other' => q({0} unser),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stone),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stone),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'one' => q({0} dl),
						'other' => q({0}dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'one' => q({0} dl),
						'other' => q({0}dl),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'one' => q({0} dr),
						'other' => q({0} drope),
					},
					# Core Unit Identifier
					'drop' => {
						'one' => q({0} dr),
						'other' => q({0} drope),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'one' => q({0} imp. fl oz),
						'other' => q({0} imp. fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'one' => q({0} imp. fl oz),
						'other' => q({0} imp. fl oz),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(liter),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(liter),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'one' => q({0} ml),
						'other' => q({0}ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'one' => q({0} ml),
						'other' => q({0}ml),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(imp. quart),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(imp. quart),
					},
				},
				'short' => {
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(bogeminutt),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(bogeminutt),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(bogesekund),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(bogesekund),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radianar),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radianar),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} acre),
						'other' => q({0} acre),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} acre),
						'other' => q({0} acre),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(tommar²),
						'one' => q({0} tomme²),
						'other' => q({0} tommar²),
						'per' => q({0}/tomme²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(tommar²),
						'one' => q({0} tomme²),
						'other' => q({0} tommar²),
						'per' => q({0}/tomme²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(engelske mil²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(engelske mil²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/l),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(eng. mil/gal),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(eng. mil/gal),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(eng. mil/brit. gal),
						'one' => q({0} mile/brit. gal),
						'other' => q({0} mile/brit. gal),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(eng. mil/brit. gal),
						'one' => q({0} mile/brit. gal),
						'other' => q({0} mile/brit. gal),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					# Core Unit Identifier
					'byte' => {
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gb),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kb),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mb),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tb),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(hå.),
						'one' => q({0} hå.),
						'other' => q({0} hå.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(hå.),
						'one' => q({0} hå.),
						'other' => q({0} hå.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(timar),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(timar),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrosekund),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrosekund),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisekund),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisekund),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minutt),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minutt),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(månadar),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(månadar),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekund),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekund),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(veker),
						'one' => q({0} v),
						'other' => q({0} v),
						'per' => q({0}/v),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(veker),
						'one' => q({0} v),
						'other' => q({0} v),
						'per' => q({0}/v),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(poundforce),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(poundforce),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(ppt),
						'one' => q({0} ppt),
						'other' => q({0} ppt),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(ppt),
						'one' => q({0} ppt),
						'other' => q({0} ppt),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapikslar),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapikslar),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pikslar),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pikslar),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(famner),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(famner),
					},
					# Long Unit Identifier
					'length-foot' => {
						'per' => q({0}/ft),
					},
					# Core Unit Identifier
					'foot' => {
						'per' => q({0}/ft),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(tommar),
						'one' => q({0} tomme),
						'other' => q({0} tommar),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(tommar),
						'one' => q({0} tomme),
						'other' => q({0} tommar),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q({0} lysår),
						'other' => q({0} lysår),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0} lysår),
						'other' => q({0} lysår),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(engelske mil),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(engelske mil),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikometer),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikometer),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pt),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pt),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(engelske yard),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(engelske yard),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(solluminositetar),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(solluminositetar),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(solmassar),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(solmassar),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stones),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stones),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(engelske mil/t),
						'one' => q({0} mile/t),
						'other' => q({0} mile/t),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(engelske mil/t),
						'one' => q({0} mile/t),
						'other' => q({0} mile/t),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}{1}),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(tommar³),
						'one' => q({0} tomme³),
						'other' => q({0} tommar³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(tommar³),
						'one' => q({0} tomme³),
						'other' => q({0} tommar³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(engelske mil³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(engelske mil³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(koppar),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(koppar),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(m. koppar),
						'one' => q({0} m. kopp),
						'other' => q({0} m. koppar),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(m. koppar),
						'one' => q({0} m. kopp),
						'other' => q({0} m. koppar),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(dsskei),
						'one' => q({0} dsskei),
						'other' => q({0} dsskei),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(dsskei),
						'one' => q({0} dsskei),
						'other' => q({0} dsskei),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(brit. dsskei),
						'one' => q({0} brit. dsskei),
						'other' => q({0} imp. bs),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(brit. dsskei),
						'one' => q({0} brit. dsskei),
						'other' => q({0} imp. bs),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(drope),
						'one' => q({0} drope),
						'other' => q({0} drope),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(drope),
						'one' => q({0} drope),
						'other' => q({0} drope),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(væskeunse),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(væskeunse),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(britisk væskeunse),
						'one' => q({0} britisk væskeunse),
						'other' => q({0} britiske væskeunser),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(britisk væskeunse),
						'one' => q({0} britisk væskeunse),
						'other' => q({0} britiske væskeunser),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Core Unit Identifier
					'pint' => {
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(brit. quart),
						'one' => q({0} b. quart),
						'other' => q({0} b. quart),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(brit. quart),
						'one' => q({0} b. quart),
						'other' => q({0} b. quart),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ja|j|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:nei|n)$' }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'long' => {
				'1000000' => {
					'one' => '0 million',
					'other' => '0 millionar',
				},
				'10000000' => {
					'one' => '00 millionar',
					'other' => '00 millionar',
				},
				'100000000' => {
					'one' => '000 millionar',
					'other' => '000 millionar',
				},
				'1000000000' => {
					'one' => '0 milliard',
					'other' => '0 milliardar',
				},
				'10000000000' => {
					'one' => '00 milliardar',
					'other' => '00 milliardar',
				},
				'100000000000' => {
					'one' => '000 milliardar',
					'other' => '000 milliardar',
				},
				'1000000000000' => {
					'one' => '0 billion',
					'other' => '0 billionar',
				},
				'10000000000000' => {
					'one' => '00 billionar',
					'other' => '00 billionar',
				},
				'100000000000000' => {
					'one' => '000 billionar',
					'other' => '000 billionar',
				},
			},
		},
} },
);

has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00 ¤',
					},
				},
			},
		},
} },
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'ADP' => {
			display_name => {
				'currency' => q(andorranske peseta),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(afghanske afghani \(1927–2002\)),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(angolske kwanza \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(angolske nye kwanza \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(angolske kwanza reajustado \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(argentiske austral),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(argentinske peso \(1983–1985\)),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(austerrikske schilling),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(arubiske florinar),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(bosnisk-hercegovinske dinarar \(1992–1994\)),
				'one' => q(bosnisk-hercegovinsk dinar \(1992–1994\)),
				'other' => q(bosnisk-hercegovinske dinarer \(1992–1994\)),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(nye bosnisk-hercegovinske dinarar \(1994–1997\)),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(belgiske franc \(konvertibel\)),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(belgiske franc \(finansiell\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(bulgarsk hard lev),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(bahrainske dinarar),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(boliviske peso),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(boliviske mvdol),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(brasiliansk cruzeiro novo \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(brasilianske cruzado),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(brasilianske cruzado novo),
				'one' => q(brasiliansk cruzado novo \(1989–1990\)),
				'other' => q(brasilianske cruzado novo \(1989–1990\)),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(brasilianske cruzeiro),
				'one' => q(brasiliansk cruzeiro \(1993–1994\)),
				'other' => q(brasilianske cruzeiro \(1993–1994\)),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(burmesisk kyat),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(belarusiske nye rublar \(1994–1999\)),
				'one' => q(belarusisk ny rubel \(BYB\)),
				'other' => q(belarusiske nye rublar \(BYB\)),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(nye belarusiske rublar),
				'one' => q(ny belarusisk rubel),
				'other' => q(nye belarusiske rublar),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(belarusiske rublar \(2000–2016\)),
				'one' => q(belarusisk rubel \(2000–2016\)),
				'other' => q(belarusiske rublar \(2000–2016\)),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(WIR-euro),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(WIR-franc),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(kolombianske pesos),
				'one' => q(kolombiansk peso),
				'other' => q(kolombianske pesos),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(unidad de valor real),
				'one' => q(unidad de valor real),
				'other' => q(unidad de valor real),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(kostarikanske colón),
				'one' => q(kostarikansk colón),
				'other' => q(kostarikanske colón),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(gamle serbiske dinarer),
				'one' => q(gammal serbisk dinar),
				'other' => q(gamle serbiske dinarar),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(kappverdiske escudo),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(austtyske mark),
				'one' => q(austtysk mark),
				'other' => q(austtyske mark),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(algeriske dinarar),
			},
		},
		'EEK' => {
			display_name => {
				'one' => q(estisk kroon),
				'other' => q(estiske kroon),
			},
		},
		'GBP' => {
			symbol => 'GBP',
		},
		'GHC' => {
			display_name => {
				'currency' => q(ghanesiske cedi \(1979–2007\)),
			},
		},
		'GQE' => {
			display_name => {
				'one' => q(ekvatorialguineansk ekwele),
				'other' => q(ekvatorialguineanske ekwele),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(greske drakme),
				'one' => q(gresk drakme),
				'other' => q(greske drakmar),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Guinea-Bissau-peso),
				'one' => q(Guinea-Bissau-peso),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(kroatiske dinar),
				'one' => q(kroatisk dinar),
				'other' => q(kroatiske dinarar),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(ungarske forintar),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(indonesiske rupiahar),
				'one' => q(indonesisk rupiah),
				'other' => q(indonesiske rupiahar),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(nye israelske sheklar),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(indiske rupiar),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(irakiske dinarar),
				'one' => q(irakisk dinar),
				'other' => q(irakiske dinarar),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(iranske rial),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(jordanske dinarar),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(kuwaitiske dinarar),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(srilankiske rupiar),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(litauiske lita),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(litauiske talona),
				'one' => q(litauisk talona),
				'other' => q(litauiske talona),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(luxemburgske konvertibel franc),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(latviske lat),
				'one' => q(latvisk lat),
				'other' => q(latviske lat),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(latviske rublar),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(libyske dinarar),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(moldovske leuar),
				'one' => q(moldovsk leu),
				'other' => q(moldovske leuar),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(makedonske denarar),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(makedonske denarar \(1992–1993\)),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(mauritiske rupiar),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(maldiviske rupiar),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(meksikanske sølvpeso \(1861–1992\)),
				'one' => q(meksikansk sølvpeso \(MXP\)),
				'other' => q(meksikanske sølvpeso \(MXP\)),
			},
		},
		'MZM' => {
			display_name => {
				'one' => q(gammal mosambikisk metical),
				'other' => q(gamle mosambikiske metical),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(nicaraguanske cordoba),
				'one' => q(nicaraguansk cordoba),
				'other' => q(nicaraguanske cordoba),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(nepalske rupiar),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(nyzealandske dollar),
				'one' => q(nyzealandsk dollar),
				'other' => q(nyzealandske dollar),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(omanske rial),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(pakistanske rupiar),
			},
		},
		'PLZ' => {
			display_name => {
				'one' => q(polsk zloty \(PLZ\)),
				'other' => q(polske zloty \(PLZ\)),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(paraguayanske guaraní),
				'one' => q(paraguayansk guaraní),
				'other' => q(paraguayanske guaraní),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(qatarske rial),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(gamle rumenske leu),
				'one' => q(gammal rumensk leu),
				'other' => q(gamle rumenske lei),
			},
		},
		'RON' => {
			symbol => 'lei',
			display_name => {
				'currency' => q(rumenske leuar),
				'one' => q(rumensk leu),
				'other' => q(rumenske leuar),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(serbiske dinarar),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(russiske rublar),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(russiske rublar \(1991–1998\)),
				'one' => q(russisk rubel \(1991–1998\)),
				'other' => q(russiske rublar \(1991–1998\)),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(saudiarabiske rial),
				'one' => q(saudiarabisk rial),
				'other' => q(saudiarabiske rial),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(seychelliske rupiar),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(gamle sudanske dinarer),
				'one' => q(gammal sudansk dinar),
				'other' => q(gamle sudanske dinarar),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(gamle sudanske pund),
				'one' => q(gammalt sudansk pund),
				'other' => q(gamle sudanske pund),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(sierraleonske leonar),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(sierraleonske leonar \(1964—2022\)),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(sovjetiske rublar),
				'one' => q(sovjetisk rubel),
				'other' => q(sovjetiske rublar),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(eswatinisk lilangeni),
				'one' => q(eswatinisk lilangeni),
				'other' => q(eswatiniske emalangeni),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(tadsjikiske rublar),
				'one' => q(tadsjikisk rubel),
				'other' => q(tadsjikiske rublar),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(tunisiske dinarar),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(gamle tyrkiske lire),
				'one' => q(gammal tyrkisk lire),
				'other' => q(gamle tyrkiske lire),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(tyrkiske lira),
				'one' => q(tyrkisk lira),
				'other' => q(tyrkiske lira),
			},
		},
		'TWD' => {
			symbol => '$',
		},
		'USS' => {
			display_name => {
				'currency' => q(amerikanske dollar \(same dag\)),
				'one' => q(amerikansk dollar \(same dag\)),
				'other' => q(amerikanske dollar \(same dag\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(uruguayanske peso en unidades indexadas),
				'one' => q(uruguayansk peso en unidades indexadas),
				'other' => q(uruguayanske peso en unidades indexadas),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(uruguayanske peso \(1975–1993\)),
				'one' => q(uruguayansk peso \(UYP\)),
				'other' => q(uruguayanske peso \(UYP\)),
			},
		},
		'UYU' => {
			display_name => {
				'one' => q(uruguayansk peso),
				'other' => q(uruguayanske pesos),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(usbekiske sum),
				'one' => q(usbekisk sum),
				'other' => q(usbekiske sum),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vanuatuiske vatu),
				'one' => q(vanuatuisk vatu),
				'other' => q(vanuatuiske vatu),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(europeiske samansette einingar),
				'one' => q(europeisk samansett eining),
				'other' => q(europeiske samansette einingar),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(europeiske monetære einingar),
				'one' => q(europeisk monetær eining),
				'other' => q(europeiske monetære einingar),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(europeiske kontoeiningar \(XBC\)),
				'one' => q(europeisk kontoeining \(XBC\)),
				'other' => q(europeiske kontoeiningar \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(europeiske kontoeiningar \(XBD\)),
				'one' => q(europeisk kontoeining \(XBD\)),
				'other' => q(europeiske kontoeiningar \(XBD\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(austkaribiske dollar),
				'one' => q(austkaribisk dollar),
				'other' => q(austkaribiske dollar),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(spesielle trekkrettar),
				'one' => q(spesiell trekkrett),
				'other' => q(spesielle trekkrettar),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(europeiske valutaeiningar),
				'one' => q(europeisk valutaeining),
				'other' => q(europeiske valutaeiningar),
			},
		},
		'XPD' => {
			display_name => {
				'one' => q(palladium),
				'other' => q(palladium),
			},
		},
		'XTS' => {
			display_name => {
				'one' => q(testvalutakode),
				'other' => q(testvalutakode),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(ukjend valuta),
				'one' => q(\(ukjend valuta\)),
				'other' => q(\(ukjend valuta\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(jemenittiske dinarar),
				'one' => q(jemenittisk dinar),
				'other' => q(jemenittiske dinarar),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(jemenittiske rial),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(jugoslaviske dinarar \(hard\)),
				'one' => q(jugoslavisk dinar \(hard\)),
				'other' => q(jugoslaviske dinarar \(hard\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(jugoslaviske noviy-dinarar),
				'one' => q(jugoslavisk noviy-dinar),
				'other' => q(jugoslaviske noviy-dinarar),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(jugoslaviske konvertibel dinarar),
				'one' => q(jugoslavisk konvertibel dinar),
				'other' => q(jugoslaviske konvertible dinarar),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(sørafrikanske rand \(finansiell\)),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(zairisk ny zaire),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(zairisk zaire),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(zimbabwisk dollar),
			},
		},
	} },
);


has 'calendar_days' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'format' => {
					abbreviated => {
						mon => 'må.',
						tue => 'ty.',
						wed => 'on.',
						thu => 'to.',
						fri => 'fr.',
						sat => 'la.',
						sun => 'sø.'
					},
					short => {
						mon => 'må.',
						tue => 'ty.',
						wed => 'on.',
						thu => 'to.',
						fri => 'fr.',
						sat => 'la.',
						sun => 'sø.'
					},
					wide => {
						mon => 'måndag',
						tue => 'tysdag',
						wed => 'onsdag',
						thu => 'torsdag',
						fri => 'fredag',
						sat => 'laurdag',
						sun => 'søndag'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'mån',
						tue => 'tys',
						wed => 'ons',
						thu => 'tor',
						fri => 'fre',
						sat => 'lau',
						sun => 'søn'
					},
				},
			},
	} },
);

has 'calendar_quarters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'stand-alone' => {
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
				},
			},
	} },
);

has 'day_period_data' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { sub {
		# Time in hhmm format
		my ($self, $type, $time, $day_period_type) = @_;
		$day_period_type //= 'default';
		SWITCH:
		for ($type) {
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
		}
	} },
);

around day_period_data => sub {
    my ($orig, $self) = @_;
    return $self->$orig;
};

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'abbreviated' => {
					'am' => q{f.m.},
					'pm' => q{e.m.},
				},
				'wide' => {
					'afternoon1' => q{på ettermiddagen},
					'evening1' => q{på kvelden},
					'midnight' => q{midnatt},
					'morning1' => q{på morgonen},
					'morning2' => q{på formiddagen},
					'night1' => q{på natta},
				},
			},
			'stand-alone' => {
				'wide' => {
					'afternoon1' => q{ettermiddag},
					'evening1' => q{kveld},
					'morning1' => q{morgon},
					'morning2' => q{formiddag},
					'night1' => q{natt},
				},
			},
		},
	} },
);

has 'eras' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
		},
		'gregorian' => {
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
		},
		'gregorian' => {
			'full' => q{EEEE d. MMMM y},
			'long' => q{d. MMMM y},
			'medium' => q{d. MMM y},
			'short' => q{dd.MM.y},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
		},
		'gregorian' => {
			'full' => q{'kl'. HH:mm:ss zzzz},
			'long' => q{HH:mm:ss z},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
		},
		'gregorian' => {
			'full' => q{{1} {0}},
			'long' => q{{1} 'kl'. {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			MMMMW => q{'veke' W 'i' MMMM},
			yw => q{'veke' w 'i' Y},
		},
	} },
);

has 'datetime_formats_append_item' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			MMMEd => {
				d => q{E d.–E d. MMM},
			},
			yM => {
				M => q{MM.y–MM.y G},
				y => q{MM.y–MM.y G},
			},
			yMEd => {
				M => q{E dd.MM.y–E dd.MM.y G},
				d => q{E dd.MM.y–E dd.MM.y G},
				y => q{E dd.MM.y–E dd.MM.y G},
			},
			yMMMEd => {
				d => q{E d.–E d. MMM y G},
			},
			yMd => {
				M => q{dd.MM.y–dd.MM.y G},
				d => q{dd.MM.y–dd.MM.y G},
				y => q{dd.MM.y–dd.MM.y G},
			},
		},
		'gregorian' => {
			Md => {
				M => q{dd.MM–dd.MM},
				d => q{dd.MM–dd.MM},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(sommartid – {0}),
		'Africa_Eastern' => {
			long => {
				'standard' => q#austafrikansk tid#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#vestafrikansk sommartid#,
				'generic' => q#vestafrikansk tid#,
				'standard' => q#vestafrikansk standardtid#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#alaskisk sommartid#,
				'generic' => q#alaskisk tid#,
				'standard' => q#alaskisk normaltid#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#sommartid for Amazonas#,
				'generic' => q#tidssone for Amazonas#,
				'standard' => q#normaltid for Amazonas#,
			},
		},
		'America/Cayman' => {
			exemplarCity => q#Caymanøyane#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiaba#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#sommartid for sentrale Nord-Amerika#,
				'generic' => q#tidssone for sentrale Nord-Amerika#,
				'standard' => q#normaltid for sentrale Nord-Amerika#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#sommartid for den nordamerikansk austkysten#,
				'generic' => q#tidssone for den nordamerikanske austkysten#,
				'standard' => q#normaltid for den nordamerikanske austkysten#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#sommartid for Rocky Mountains (USA)#,
				'generic' => q#tidssone for Rocky Mountains (USA)#,
				'standard' => q#normaltid for Rocky Mountains (USA)#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#sommartid for den nordamerikanske stillehavskysten#,
				'generic' => q#tidssone for den nordamerikanske stillehavskysten#,
				'standard' => q#normaltid for den nordamerikanske stillehavskysten#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#sommartid for Apia#,
				'generic' => q#tidssone for Apia#,
				'standard' => q#normaltid for Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#arabisk sommartid#,
				'generic' => q#arabisk tid#,
				'standard' => q#arabisk normaltid#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#argentinsk sommartid#,
				'generic' => q#argentinsk tid#,
				'standard' => q#argentinsk normaltid#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#vestargentinsk sommartid#,
				'generic' => q#vestargentinsk tid#,
				'standard' => q#vestargentinsk normaltid#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#armensk sommartid#,
				'generic' => q#armensk tid#,
				'standard' => q#armensk normaltid#,
			},
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Asjgabat#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Tsjojbalsan#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Khovd#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Yangôn#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#sommartid for den nordamerikanske atlanterhavskysten#,
				'generic' => q#tidssone for den nordamerikanske atlanterhavskysten#,
				'standard' => q#normaltid for den nordamerikanske atlanterhavskysten#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Asorane#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanariøyane#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Færøyane#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#sentralaustralsk sommartid#,
				'generic' => q#sentralaustralsk tid#,
				'standard' => q#sentralaustralsk standardtid#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#vest-sentralaustralsk sommartid#,
				'generic' => q#vest-sentralaustralsk tid#,
				'standard' => q#vest-sentralaustralsk standardtid#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#austaustralsk sommartid#,
				'generic' => q#austaustralsk tid#,
				'standard' => q#austaustralsk standardtid#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#vestaustralsk sommartid#,
				'generic' => q#vestaustralsk tid#,
				'standard' => q#vestaustralsk standardtid#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#aserbajdsjansk sommartid#,
				'generic' => q#aserbajdsjansk tid#,
				'standard' => q#aserbajdsjansk normaltid#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#asorisk sommartid#,
				'generic' => q#asorisk tid#,
				'standard' => q#asorisk normaltid#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#bangladeshisk sommartid#,
				'generic' => q#bangladeshisk tid#,
				'standard' => q#bangladeshisk normaltid#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#sommartid for Brasilia#,
				'generic' => q#tidssone for Brasilia#,
				'standard' => q#normaltid for Brasilia#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#kappverdisk sommartid#,
				'generic' => q#kappverdisk tid#,
				'standard' => q#kappverdisk normaltid#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#sommartid for Chatham#,
				'generic' => q#tidssone for Chatham#,
				'standard' => q#normaltid for Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#chilensk sommartid#,
				'generic' => q#chilensk tid#,
				'standard' => q#chilensk normaltid#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#kinesisk sommartid#,
				'generic' => q#kinesisk tid#,
				'standard' => q#kinesisk normaltid#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#sommartid for Tsjojbalsan#,
				'generic' => q#tidssone for Tsjojbalsan#,
				'standard' => q#normaltid for Tsjojbalsan#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#tidssone for Kokosøyane#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#kolombiansk sommartid#,
				'generic' => q#kolombiansk tid#,
				'standard' => q#kolombiansk normaltid#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#sommartid for Cookøyane#,
				'generic' => q#tidssone for Cookøyane#,
				'standard' => q#normaltid for Cookøyane#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#kubansk sommartid#,
				'generic' => q#kubansk tid#,
				'standard' => q#kubansk normaltid#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#tidssone for Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#austtimoresisk tid#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#sommartid for Påskeøya#,
				'generic' => q#tidssone for Påskeøya#,
				'standard' => q#normaltid for Påskeøya#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#ukjend by#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#irsk sommartid#,
			},
		},
		'Europe/London' => {
			long => {
				'daylight' => q#britisk sommartid#,
			},
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#sentraleuropeisk sommartid#,
				'generic' => q#sentraleuropeisk tid#,
				'standard' => q#sentraleuropeisk standardtid#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#austeuropeisk sommartid#,
				'generic' => q#austeuropeisk tid#,
				'standard' => q#austeuropeisk standardtid#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#fjern-austeuropeisk tid#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#vesteuropeisk sommartid#,
				'generic' => q#vesteuropeisk tid#,
				'standard' => q#vesteuropeisk standardtid#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#sommartid for Falklandsøyane#,
				'generic' => q#tidssone for Falklandsøyane#,
				'standard' => q#normaltid for Falklandsøyane#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#fijiansk sommartid#,
				'generic' => q#fijiansk tid#,
				'standard' => q#fijiansk normaltid#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#tidssone for Dei franske sørterritoria#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#tidssone for Galápagosøyane#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#georgisk sommartid#,
				'generic' => q#georgisk tid#,
				'standard' => q#georgisk normaltid#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#tidssone for Gilbertøyane#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#austgrønlandsk sommartid#,
				'generic' => q#austgrønlandsk tid#,
				'standard' => q#austgrønlandsk normaltid#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#vestgrønlandsk sommartid#,
				'generic' => q#vestgrønlandsk tid#,
				'standard' => q#vestgrønlandsk normaltid#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#sommartid for Hawaii og Aleutene#,
				'generic' => q#tidssone for Hawaii og Aleutene#,
				'standard' => q#normaltid for Hawaii og Aleutene#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#hongkongkinesisk sommartid#,
				'generic' => q#hongkongkinesisk tid#,
				'standard' => q#hongkongkinesisk normaltid#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#sommartid for Khovd#,
				'generic' => q#tidssone for Khovd#,
				'standard' => q#normaltid for Khovd#,
			},
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokosøyane#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komorane#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivane#,
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#austindonesisk tid#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#iransk sommartid#,
				'generic' => q#iransk tid#,
				'standard' => q#iransk normaltid#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#sommartid for Irkutsk#,
				'generic' => q#tidssone for Irkutsk#,
				'standard' => q#normaltid for Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#israelsk sommartid#,
				'generic' => q#israelsk tid#,
				'standard' => q#israelsk normaltid#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#japansk sommartid#,
				'generic' => q#japansk tid#,
				'standard' => q#japansk normaltid#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#austkasakhstansk tid#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#koreansk sommartid#,
				'generic' => q#koreansk tid#,
				'standard' => q#koreansk normaltid#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#sommartid for Krasnojarsk#,
				'generic' => q#tidssone for Krasnojarsk#,
				'standard' => q#normaltid for Krasnojarsk#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#tidssone for Lineøyane#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#sommartid for Lord Howe-øya#,
				'generic' => q#tidssone for Lord Howe-øya#,
				'standard' => q#normaltid for Lord Howe-øya#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#sommartid for Magadan#,
				'generic' => q#tidssone for Magadan#,
				'standard' => q#normaltid for Magadan#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#tidssone for Marquesasøyane#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#mauritisk sommartid#,
				'generic' => q#mauritisk tid#,
				'standard' => q#mauritisk normaltid#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#sommartid for nordvestlege Mexico#,
				'generic' => q#tidssone for nordvestlege Mexico#,
				'standard' => q#normaltid for nordvestlege Mexico#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#sommartid for den meksikanske stillehavskysten#,
				'generic' => q#tidssone for den meksikanske stillehavskysten#,
				'standard' => q#normaltid for den meksikanske stillehavskysten#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#sommartid for Ulan Bator#,
				'generic' => q#tidssone for Ulan Bator#,
				'standard' => q#normaltid for Ulan Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#sommartid for Moskva#,
				'generic' => q#tidssone for Moskva#,
				'standard' => q#normaltid for Moskva#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#kaledonsk sommartid#,
				'generic' => q#kaledonsk tid#,
				'standard' => q#kaledonsk normaltid#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#nyzealandsk sommartid#,
				'generic' => q#nyzealandsk tid#,
				'standard' => q#nyzealandsk normaltid#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#sommartid for Newfoundland#,
				'generic' => q#tidssone for Newfoundland#,
				'standard' => q#normaltid for Newfoundland#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#sommartid for Norfolkøya#,
				'generic' => q#tidssone for Norfolkøya#,
				'standard' => q#normaltid for Norfolkøya#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#sommartid for Fernando de Noronha#,
				'generic' => q#tidssone for Fernando de Noronha#,
				'standard' => q#normaltid for Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#sommartid for Novosibirsk#,
				'generic' => q#tidssone for Novosibirsk#,
				'standard' => q#normaltid for Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#sommartid for Omsk#,
				'generic' => q#tidssone for Omsk#,
				'standard' => q#normaltid for Omsk#,
			},
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galápagosøyane#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#pakistansk sommartid#,
				'generic' => q#pakistansk tid#,
				'standard' => q#pakistansk normaltid#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#paraguayansk sommartid#,
				'generic' => q#paraguayansk tid#,
				'standard' => q#paraguayansk normaltid#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#peruansk sommartid#,
				'generic' => q#peruansk tid#,
				'standard' => q#peruansk normaltid#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#filippinsk sommartid#,
				'generic' => q#filippinsk tid#,
				'standard' => q#filippinsk normaltid#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#tidssone for Phoenixøyane#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#sommartid for Saint-Pierre-et-Miquelon#,
				'generic' => q#tidssone for Saint-Pierre-et-Miquelon#,
				'standard' => q#normaltid for Saint-Pierre-et-Miquelon#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#sommartid for Sakhalin#,
				'generic' => q#tidssone for Sakhalin#,
				'standard' => q#normaltid for Sakhalin#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#samoansk sommartid#,
				'generic' => q#samoansk tid#,
				'standard' => q#samoansk normaltid#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#sommartid for Taipei#,
				'generic' => q#tidssone for Taipei#,
				'standard' => q#normaltid for Taipei#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#tongansk sommartid#,
				'generic' => q#tongansk tid#,
				'standard' => q#tongansk normaltid#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#tidssone for Chuukøyane#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#turkmensk sommartid#,
				'generic' => q#turkmensk tid#,
				'standard' => q#turkmensk normaltid#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#uruguayansk sommartid#,
				'generic' => q#uruguayansk tid#,
				'standard' => q#uruguayansk normaltid#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#usbekisk sommartid#,
				'generic' => q#usbekisk tid#,
				'standard' => q#usbekisk normaltid#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#vanuatisk sommartid#,
				'generic' => q#vanuatisk tid#,
				'standard' => q#vanuatisk normaltid#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#sommartid for Vladivostok#,
				'generic' => q#tidssone for Vladivostok#,
				'standard' => q#normaltid for Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#sommartid for Volgograd#,
				'generic' => q#tidssone for Volgograd#,
				'standard' => q#normaltid for Volgograd#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#tidssone for Wallis- og Futunaøyane#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#sommartid for Jakutsk#,
				'generic' => q#tidssone for Jakutsk#,
				'standard' => q#normaltid for Jakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#sommartid for Jekaterinburg#,
				'generic' => q#tidssone for Jekaterinburg#,
				'standard' => q#normaltid for Jekaterinburg#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
