=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ee - Package for language Ewe

=cut

package Locale::CLDR::Locales::Ee;
# This file auto generated from Data\common\main\ee.xml
#	on Sun 25 Feb 10:41:40 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Root');
has 'valid_algorithmic_formats' => (
    is => 'ro',
    isa => ArrayRef,
    init_arg => undef,
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal','spellout-ordinal','digits-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'after-billions' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(' kpakple =%spellout-cardinal=),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(' kple =%spellout-cardinal=),
				},
				'100000000' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(' kple =%spellout-cardinal=),
				},
				'100000000000' => {
					base_value => q(100000000000),
					divisor => q(100000000000),
					rule => q(' =%spellout-cardinal=),
				},
				'max' => {
					base_value => q(100000000000),
					divisor => q(100000000000),
					rule => q(' =%spellout-cardinal=),
				},
			},
		},
		'after-hundred-thousands' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(' kpakple =%spellout-cardinal=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(' =%spellout-cardinal=),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(' =%spellout-cardinal=),
				},
			},
		},
		'after-hundreds' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(kple =%spellout-cardinal=),
				},
				'21' => {
					base_value => q(21),
					divisor => q(10),
					rule => q(=%spellout-cardinal=),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(kple =%spellout-cardinal=),
				},
				'31' => {
					base_value => q(31),
					divisor => q(10),
					rule => q(=%spellout-cardinal=),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(kple =%spellout-cardinal=),
				},
				'41' => {
					base_value => q(41),
					divisor => q(10),
					rule => q(=%spellout-cardinal=),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(kple =%spellout-cardinal=),
				},
				'51' => {
					base_value => q(51),
					divisor => q(10),
					rule => q(=%spellout-cardinal=),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(kple =%spellout-cardinal=),
				},
				'61' => {
					base_value => q(61),
					divisor => q(10),
					rule => q(=%spellout-cardinal=),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(kple =%spellout-cardinal=),
				},
				'71' => {
					base_value => q(71),
					divisor => q(10),
					rule => q(=%spellout-cardinal=),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(kple =%spellout-cardinal=),
				},
				'81' => {
					base_value => q(81),
					divisor => q(10),
					rule => q(=%spellout-cardinal=),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(kple =%spellout-cardinal=),
				},
				'91' => {
					base_value => q(91),
					divisor => q(10),
					rule => q(=%spellout-cardinal=),
				},
				'max' => {
					base_value => q(91),
					divisor => q(10),
					rule => q(=%spellout-cardinal=),
				},
			},
		},
		'after-millions' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(' kpakple =%spellout-cardinal=),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(' kple =%spellout-cardinal=),
				},
				'100000' => {
					base_value => q(100000),
					divisor => q(100000),
					rule => q(' =%spellout-cardinal=),
				},
				'max' => {
					base_value => q(100000),
					divisor => q(100000),
					rule => q(' =%spellout-cardinal=),
				},
			},
		},
		'after-thousands' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(' kple =%spellout-cardinal=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(' =%spellout-cardinal=),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(' =%spellout-cardinal=),
				},
			},
		},
		'digits-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0= lia),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=#,##0= tɔ),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=#,##0= lia),
				},
				'max' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=#,##0= lia),
				},
			},
		},
		'spellout-base' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ɖekeo),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ɖekɛ),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(eve),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(etɔ̃),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(ene),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(atɔ̃),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(ade),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(adre),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(enyi),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(asieke),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(ewo),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(wui→→),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(bla←←[ vɔ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(alafa ←%spellout-cardinal←[ →%%after-hundreds→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(akpe ←%spellout-cardinal←[→%%after-thousands→]),
				},
				'100000' => {
					base_value => q(100000),
					divisor => q(1000),
					rule => q(akpe ←%spellout-cardinal←[→%%after-hundred-thousands→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miliɔn ←%spellout-cardinal←[→%%after-millions→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miliɔn akpe ←%spellout-cardinal←[→%%after-millions→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biliɔn ←%spellout-cardinal←[→%%after-billions→]),
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
		'spellout-cardinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(→→ xlẽyimegbee),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ɖekeo),
				},
				'0.x' => {
					divisor => q(1),
					rule => q(kakɛ →→),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← kple kakɛ →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ɖeka),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%spellout-base=),
				},
				'max' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%spellout-base=),
				},
			},
		},
		'spellout-numbering' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
			},
		},
		'spellout-numbering-year' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
				'max' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
			},
		},
		'spellout-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(→→ xlẽyimegbee),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ɖekeolia),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.0=lia),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(gbãtɔ),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-cardinal=lia),
				},
				'max' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-cardinal=lia),
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
				'ab' => 'abkhaziagbe',
 				'ady' => 'adyghegbe',
 				'af' => 'afrikaangbe',
 				'agq' => 'aghemgbe',
 				'ak' => 'blugbe',
 				'am' => 'amhariagbe',
 				'ar' => 'Arabiagbe',
 				'as' => 'assamegbe',
 				'asa' => 'asagbe',
 				'ast' => 'asturiagbe',
 				'av' => 'avariagbe',
 				'ay' => 'aymargbe',
 				'az' => 'azerbaijangbe',
 				'ba' => 'bashkigbe',
 				'bas' => 'basaagbe',
 				'bax' => 'bamugbe',
 				'bbj' => 'ghomalagbe',
 				'be' => 'belarusiagbe',
 				'bem' => 'bembagbe',
 				'bez' => 'benagbe',
 				'bfd' => 'bafutgbe',
 				'bg' => 'bulgariagbe',
 				'bi' => 'bislamagbe',
 				'bkm' => 'komgbe',
 				'bm' => 'bambaragbe',
 				'bn' => 'Bengaligbe',
 				'bo' => 'tibetagbe',
 				'br' => 'bretongbe',
 				'brx' => 'bodogbe',
 				'bs' => 'bosniagbe',
 				'bss' => 'akoosiagbe',
 				'bum' => 'bulugbe',
 				'byv' => 'medumbagbe',
 				'ca' => 'katalagbe',
 				'ceb' => 'Sebuanogbe',
 				'ch' => 'kamorrogbe',
 				'chk' => 'tsukesegbe',
 				'chm' => 'tsetsniagbe',
 				'cs' => 'tsɛkgbe',
 				'cy' => 'walesgbe',
 				'da' => 'denmarkgbe',
 				'de' => 'Germaniagbe',
 				'de_AT' => 'Germaniagbe (Austria)',
 				'de_CH' => 'Germaniagbe (Switzerland)',
 				'dje' => 'zamagbe',
 				'dua' => 'dualagbe',
 				'dv' => 'divehgbe',
 				'dyo' => 'dzola-fonyigbe',
 				'dz' => 'dzongkhagbe',
 				'ebu' => 'embugbe',
 				'ee' => 'Eʋegbe',
 				'efi' => 'efigbe',
 				'el' => 'grisigbe',
 				'en' => 'Yevugbe',
 				'en_AU' => 'Yevugbe (Australia)',
 				'en_CA' => 'Yevugbe (Canada)',
 				'en_GB' => 'Yevugbe (Britain)',
 				'en_GB@alt=short' => 'Yevugbe (GB)',
 				'en_US' => 'Yevugbe (America)',
 				'en_US@alt=short' => 'Yevugbe (US)',
 				'eo' => 'esperantogbe',
 				'es' => 'Spanishgbe',
 				'es_419' => 'Spanishgbe (Latin America)',
 				'es_ES' => 'Spanishgbe (Europe)',
 				'es_MX' => 'Spanishgbe (Mexico)',
 				'et' => 'estoniagbe',
 				'eu' => 'basqugbe',
 				'ewo' => 'ewondogbe',
 				'fa' => 'persiagbe',
 				'fan' => 'fangbe',
 				'ff' => 'fulagbe',
 				'fi' => 'finlanɖgbe',
 				'fil' => 'filipingbe',
 				'fj' => 'fidzigbe',
 				'fo' => 'faroegbe',
 				'fr' => 'Fransegbe',
 				'fr_CA' => 'Fransegbe (Canada)',
 				'fr_CH' => 'Fransegbe (Switzerland)',
 				'fy' => 'ɣetoɖoƒe frisiagbe',
 				'ga' => 'irelanɖgbe',
 				'gaa' => 'gɛgbe',
 				'gd' => 'skɔtlanɖ gaeliagbe',
 				'gil' => 'gilbertgbe',
 				'gl' => 'galatagbe',
 				'gn' => 'guarangbe',
 				'gsw' => 'swizerlanɖtɔwo ƒe germaniagbe',
 				'gu' => 'gujarati',
 				'ha' => 'hausagbe',
 				'haw' => 'hawaigbe',
 				'he' => 'hebrigbe',
 				'hi' => 'Hindigbe',
 				'hil' => 'hiligenɔgbe',
 				'ho' => 'hiri motugbe',
 				'hr' => 'kroatiagbe',
 				'ht' => 'haitigbe',
 				'hu' => 'hungarigbe',
 				'hy' => 'armeniagbe',
 				'ibb' => 'ibibiogbe',
 				'id' => 'Indonesiagbe',
 				'ig' => 'igbogbe',
 				'ilo' => 'ilikogbe',
 				'inh' => 'ingusigbe',
 				'is' => 'icelanɖgbe',
 				'it' => 'Italiagbe',
 				'ja' => 'Japangbe',
 				'jv' => 'dzavangbe',
 				'ka' => 'gɔgiagbe',
 				'kbd' => 'kabardiagbe',
 				'kea' => 'cape verdegbe',
 				'kg' => 'kongogbe',
 				'kha' => 'khasigbe',
 				'kj' => 'kunyamagbe',
 				'kk' => 'kazakhstangbe',
 				'kkj' => 'kakogbe',
 				'kl' => 'kalaalisugbe',
 				'km' => 'khmergbe',
 				'kn' => 'kannadagbe',
 				'ko' => 'Koreagbe',
 				'kok' => 'konkaniagbe',
 				'kos' => 'kosraeagbe',
 				'kr' => 'kanuriagbe',
 				'krc' => 'karakay-bakargbe',
 				'ks' => 'kashmirgbe',
 				'ksf' => 'bafiagbe',
 				'ku' => 'kurdiagbe',
 				'kum' => 'kumikagbe',
 				'ky' => 'kirghistangbe',
 				'la' => 'latin',
 				'lah' => 'lahndagbe',
 				'lb' => 'laksembɔggbe',
 				'lez' => 'lezghiagbe',
 				'ln' => 'lingala',
 				'lo' => 'laogbe',
 				'lt' => 'lithuaniagbe',
 				'lu' => 'luba-katangagbe',
 				'lua' => 'luba-lulugbe',
 				'luy' => 'luyiagbe',
 				'lv' => 'latviagbe',
 				'maf' => 'mafagbe',
 				'mai' => 'maitiligbe',
 				'mdf' => 'moktsiagbe',
 				'mg' => 'malagasegbe',
 				'mgh' => 'makuwa-mitogbe',
 				'mh' => 'marshalgbe',
 				'mi' => 'maorgbe',
 				'mk' => 'makedoniagbe',
 				'ml' => 'malayagbe',
 				'mn' => 'mongoliagbe',
 				'mr' => 'marathiagbe',
 				'ms' => 'malaygbe',
 				'mt' => 'maltagbe',
 				'mua' => 'mundangbe',
 				'mul' => 'gbegbɔgblɔ sɔgbɔwo',
 				'my' => 'burmagbe',
 				'mye' => 'myenegbe',
 				'myv' => 'erziyagbe',
 				'na' => 'naurugbe',
 				'nb' => 'nɔweigbe bokmål',
 				'nd' => 'dziehe ndebelegbe',
 				'ne' => 'nepalgbe',
 				'niu' => 'niuegbe',
 				'nl' => 'Hollandgbe',
 				'nl_BE' => 'Flemishgbe',
 				'nmg' => 'kwasiogbe',
 				'nn' => 'nɔweigbe ninɔsk',
 				'nnh' => 'ngiemboongbe',
 				'no' => 'nɔweigbe',
 				'nr' => 'anyiehe ndebelegbe',
 				'nso' => 'dziehe sothogbe',
 				'nus' => 'nuergbe',
 				'ny' => 'nyanjagbe',
 				'or' => 'oriyagbe',
 				'os' => 'ossetiagbe',
 				'pa' => 'pundzabgbe',
 				'pag' => 'pangsinagbe',
 				'pap' => 'papiamentogbe',
 				'pau' => 'paluagbe',
 				'pl' => 'Polishgbe',
 				'pon' => 'ponpeiagbe',
 				'ps' => 'pashtogbe',
 				'pt' => 'Portuguesegbe',
 				'pt_BR' => 'Portuguesegbe (Brazil)',
 				'pt_PT' => 'Portuguesegbe (Europe)',
 				'qu' => 'kwetsuagbe',
 				'rm' => 'romanshgbe',
 				'rn' => 'rundigbe',
 				'ro' => 'romaniagbe',
 				'rof' => 'rombogbe',
 				'ru' => 'Russiagbe',
 				'rw' => 'ruwandagbe',
 				'rwk' => 'rwagbe',
 				'sa' => 'sanskrigbe',
 				'sah' => 'sakagbe',
 				'sat' => 'santaligbe',
 				'sbp' => 'sangugbe',
 				'sd' => 'sindhgbe',
 				'se' => 'dziehe samigbe',
 				'sg' => 'sangogbe',
 				'sh' => 'serbo-croatiagbe',
 				'si' => 'sinhalgbe',
 				'sk' => 'slovakiagbe',
 				'sl' => 'sloveniagbe',
 				'sm' => 'samoagbe',
 				'sn' => 'shonagbe',
 				'so' => 'somaliagbe',
 				'sq' => 'albaniagbe',
 				'sr' => 'serbiagbe',
 				'ss' => 'swatgbe',
 				'st' => 'anyiehe sothogbe',
 				'sv' => 'swedengbe',
 				'sw' => 'swahili',
 				'swb' => 'komorogbe',
 				'ta' => 'tamilgbe',
 				'te' => 'telegugbe',
 				'tet' => 'tetumgbe',
 				'tg' => 'tadzikistangbe',
 				'th' => 'Thailandgbe',
 				'ti' => 'tigrinyagbe',
 				'tk' => 'tɛkmengbe',
 				'tkl' => 'tokelaugbe',
 				'tl' => 'tagalogbe',
 				'tn' => 'tswanagbe',
 				'to' => 'tongagbe',
 				'tpi' => 'tok pisigbe',
 				'tr' => 'Turkishgbe',
 				'ts' => 'tsongagbe',
 				'tt' => 'tatargbe',
 				'tvl' => 'tuvalugbe',
 				'twq' => 'tasawakgbe',
 				'ty' => 'tahitigbe',
 				'tyv' => 'tuviniagbe',
 				'udm' => 'udmurtgbe',
 				'ug' => 'uighurgbe',
 				'uk' => 'ukraingbe',
 				'und' => 'gbegbɔgblɔ manya',
 				'ur' => 'urdugbe',
 				'uz' => 'uzbekistangbe',
 				'vai' => 'vaigbe',
 				've' => 'vendagbe',
 				'vi' => 'vietnamgbe',
 				'wae' => 'walsegbe',
 				'war' => 'waraygbe',
 				'wo' => 'wolofgbe',
 				'xh' => 'xhosagbe',
 				'yap' => 'yapesigbe',
 				'yav' => 'yangbengbe',
 				'ybb' => 'yembagbe',
 				'yo' => 'yorubagbe',
 				'yue' => 'cantongbe',
 				'za' => 'zhuangbe',
 				'zh' => 'Chinagbe',
 				'zh_Hans' => 'tsainagbe',
 				'zh_Hant' => 'blema tsainagbe',
 				'zu' => 'zulugbe',
 				'zxx' => 'gbegbɔgblɔ manɔmee',

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
			'Arab' => 'Arabiagbeŋɔŋlɔ',
 			'Armi' => 'aramia gbeŋɔŋlɔ',
 			'Armn' => 'armeniagbeŋɔŋlɔ',
 			'Avst' => 'avesta gbeŋɔŋlɔ',
 			'Bali' => 'balini gbeŋɔŋlɔ',
 			'Bamu' => 'bamum gbeŋɔŋlɔ',
 			'Batk' => 'batak gbeŋɔŋlɔ',
 			'Beng' => 'bengaligbeŋɔŋlɔ',
 			'Blis' => 'bliss ŋɔŋlɔdzesi',
 			'Bopo' => 'bopomfogbeŋɔŋlɔ',
 			'Brah' => 'brami gbeŋɔŋlɔ',
 			'Brai' => 'braillegbeŋɔŋlɔ',
 			'Buhd' => 'buhid gbeŋɔŋlɔ',
 			'Cakm' => 'tsakma gbeŋɔŋlɔ',
 			'Cans' => 'kanada wɔɖeka ƒe abɔridzin gbedodo',
 			'Cari' => 'karia gbeŋɔŋlɔ',
 			'Cham' => 'tsam gbeŋɔŋlɔ',
 			'Cher' => 'tseroke gbeŋɔŋlɔ',
 			'Cirt' => 'seif gbeŋɔŋlɔ',
 			'Copt' => 'koptia gbeŋɔŋlɔ',
 			'Cprt' => 'saipriot gbeŋɔŋlɔ',
 			'Cyrl' => 'Cyrillicgbeŋɔŋlɔ',
 			'Cyrs' => 'slavonia sirillia sɔleme gbeŋɔŋlɔ xoxotɔ',
 			'Deva' => 'devanagarigbeŋɔŋlɔ',
 			'Dsrt' => 'deseret gbeŋɔŋlɔ',
 			'Egyd' => 'egypte demotia gbeŋɔŋlɔ',
 			'Egyh' => 'egypte hieratia gbeŋɔŋlɔ',
 			'Egyp' => 'egypte hieroglif nuŋɔŋlɔ',
 			'Ethi' => 'ethiopiagbeŋɔŋlɔ',
 			'Geok' => 'dzɔdzia khutsiria gbeŋɔŋlɔ',
 			'Geor' => 'gɔgiagbeŋɔŋlɔ',
 			'Glag' => 'glagolitia gbeŋɔŋlɔ',
 			'Goth' => 'gothia gbeŋɔŋlɔ',
 			'Gran' => 'grantha gbeŋɔŋlɔ',
 			'Grek' => 'grisigbeŋɔŋlɔ',
 			'Gujr' => 'gudzaratigbeŋɔŋlɔ',
 			'Guru' => 'gurmukhigbeŋɔŋlɔ',
 			'Hang' => 'hangulgbeŋɔŋlɔ',
 			'Hani' => 'hangbeŋɔŋlɔ',
 			'Hano' => 'hanuno gbeŋɔŋlɔ',
 			'Hans' => 'Chinesegbeŋɔŋlɔ',
 			'Hans@alt=stand-alone' => 'Hansgbeŋɔŋlɔ',
 			'Hant' => 'Blema Chinesegbeŋɔŋlɔ',
 			'Hant@alt=stand-alone' => 'Blema Hantgbeŋcŋlɔ',
 			'Hebr' => 'hebrigbeŋɔŋlɔ',
 			'Hira' => 'hiraganagbeŋɔŋlɔ',
 			'Hmng' => 'pahawh hmong gbeŋɔŋlɔ',
 			'Hrkt' => 'dzapan gbedodo tɔxee',
 			'Hung' => 'hungaria gbeŋɔŋlɔ xoxotɔ',
 			'Inds' => 'indus gbeŋɔŋlɔ',
 			'Ital' => 'aitalik xoxotɔ',
 			'Java' => 'dzavanese gbeŋɔŋlɔ',
 			'Jpan' => 'Japanesegbeŋɔŋlɔ',
 			'Kali' => 'kayah li gbeŋɔŋlɔ',
 			'Kana' => 'katakanagbeŋɔŋlɔ',
 			'Khar' => 'kharoshthi gbeŋɔŋlɔ',
 			'Khmr' => 'khmergbeŋɔŋlɔ',
 			'Khoj' => 'khodziki gbeŋɔŋlɔ',
 			'Knda' => 'kannadagbeŋɔŋlɔ',
 			'Kore' => 'Koreagbeŋɔŋlɔ',
 			'Kthi' => 'kaithi gbeŋɔŋlɔ',
 			'Lana' => 'lanna gbeŋɔŋlɔ',
 			'Laoo' => 'laogbeŋɔŋlɔ',
 			'Latf' => 'fraktur latin gbeŋɔŋlɔ',
 			'Latg' => 'gaelia latin gbeŋɔŋlɔ',
 			'Latn' => 'Latingbeŋɔŋlɔ',
 			'Lepc' => 'leptsa gbeŋɔŋlɔ',
 			'Limb' => 'limbu gbeŋɔŋlɔ',
 			'Lina' => 'linia a gbeŋɔŋlɔ',
 			'Linb' => 'linea b gbeŋɔŋlɔ',
 			'Lisu' => 'fraser gbeŋɔŋlɔ',
 			'Lyci' => 'lisia gbeŋɔŋlɔ',
 			'Lydi' => 'lidia gbeŋɔŋlɔ',
 			'Mand' => 'mandae gbeŋɔŋlɔ',
 			'Mani' => 'manitsia gbeŋɔŋlɔ',
 			'Maya' => 'mayan hieroglif gbeŋɔŋlɔ',
 			'Merc' => 'meroitia atsyia gbeŋɔŋlɔ',
 			'Mero' => 'meroitia gbeŋɔŋlɔ',
 			'Mlym' => 'malayagbeŋɔŋlɔ',
 			'Mong' => 'mongoliagbeŋɔŋlɔ',
 			'Moon' => 'moon gbeŋɔŋlɔ',
 			'Mtei' => 'meitei mayek gbeŋɔŋlɔ',
 			'Mymr' => 'myanmargbeŋɔŋlɔ',
 			'Nkgb' => 'naxi geba gbeŋɔŋlɔ',
 			'Nkoo' => 'n’ko gbeŋɔŋlɔ',
 			'Ogam' => 'ogham gbeŋɔŋlɔ',
 			'Olck' => 'ol tsiki gbeŋɔŋlɔ',
 			'Orkh' => 'orkhon gbeŋɔŋlɔ',
 			'Orya' => 'oriyagbeŋɔŋlɔ',
 			'Osma' => 'osmaya gbeŋɔŋlɔ',
 			'Perm' => 'permia gbeŋɔŋlɔ xoxotɔ',
 			'Phag' => 'phags-pa gbeŋɔŋlɔ',
 			'Phli' => 'pahlavi gbeŋɔŋlɔ tɔxee',
 			'Phlp' => 'psamta pahlavi gbeŋɔŋlɔ',
 			'Phlv' => 'agbaleme pahlavi gbeŋɔŋlɔ',
 			'Phnx' => 'foenesia gbeŋɔŋlɔ',
 			'Plrd' => 'pollard gbegbɔgblɔ',
 			'Prti' => 'parthia gbeŋɔŋlɔ tɔxee',
 			'Rjng' => 'redza gbeŋɔŋlɔ',
 			'Roro' => 'rongorongo gbeŋɔŋlɔ',
 			'Runr' => 'runia gbeŋɔŋlɔ',
 			'Samr' => 'samaria gbeŋɔŋlɔ',
 			'Sara' => 'sarati gbeŋɔŋlɔ',
 			'Sarb' => 'anyiehe arabia gbeŋɔŋlɔ xoxotɔ',
 			'Saur' => 'saurashtra gbeŋɔŋlɔ',
 			'Sgnw' => 'atsyia nuŋɔŋlɔ',
 			'Shaw' => 'tsavia gbeŋɔŋlɔ',
 			'Sinh' => 'sinhalagbeŋɔŋlɔ',
 			'Sund' => 'sundana gbeŋɔŋlɔ',
 			'Sylo' => 'sailoti nagri gbeŋɔŋlɔ',
 			'Syrc' => 'siriak gbeŋɔŋlɔ',
 			'Syre' => 'estrangelo siria gbeŋɔŋlɔ',
 			'Syrj' => 'ɣetoɖoƒe siria gbeŋɔŋlɔ',
 			'Syrn' => 'ɣedzeƒe siria gbeŋɔŋlɔ',
 			'Tagb' => 'tagbanwa gbeŋɔŋlɔ',
 			'Tale' => 'tai le gbeŋɔŋlɔ',
 			'Talu' => 'tail lue gbeŋɔŋlɔ yeye',
 			'Taml' => 'tamilgbeŋɔŋlɔ',
 			'Tavt' => 'tai viet gbeŋɔŋlɔ',
 			'Telu' => 'telegugbeŋɔŋlɔ',
 			'Teng' => 'tengwar gbeŋɔŋlɔ',
 			'Tfng' => 'tifinagh gbeŋɔŋlɔ',
 			'Tglg' => 'tagalog gbeŋɔŋlɔ',
 			'Thaa' => 'thaanagbeŋɔŋlɔ',
 			'Thai' => 'taigbeŋɔŋlɔ',
 			'Tibt' => 'tibetgbeŋɔŋlɔ',
 			'Tirh' => 'tirhuta gbeŋɔŋlɔ',
 			'Ugar' => 'ugaritia gbeŋɔŋlɔ',
 			'Vaii' => 'vai gbeŋɔŋlɔ',
 			'Visp' => 'gbegbɔgblɔ si dzena',
 			'Wara' => 'varang kshiti gbeŋɔŋlɔ',
 			'Xpeo' => 'persia gbeŋɔŋlɔ xoxotɔ',
 			'Xsux' => 'sumero-akkadia kunei gbeŋɔŋlɔ',
 			'Yiii' => 'yi gbeŋɔŋlɔ',
 			'Zinh' => 'gbeŋɔŋlɔ si wo dzɔ va tu',
 			'Zmth' => 'akɔnta nuŋɔŋlɔ',
 			'Zsym' => 'ŋɔŋlɔdzesiwo',
 			'Zxxx' => 'gbemaŋlɔ',
 			'Zyyy' => 'gbeŋɔŋlɔ bɔbɔ',
 			'Zzzz' => 'gbeŋɔŋlɔ manya',

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
			'001' => 'xexeme',
 			'002' => 'Afrika nutome',
 			'003' => 'Dziehe Amerika nutome',
 			'005' => 'Anyiehe Amerika nutome',
 			'009' => 'Oceania nutome',
 			'011' => 'Ɣetoɖoƒelɔƒo Afrika nutome',
 			'013' => 'Titina Amerika nutome',
 			'014' => 'Ɣedzeƒe Afrika nutome',
 			'015' => 'Dziehe Afrika nutome',
 			'017' => 'Titina Afrika nutome',
 			'018' => 'Anyiehelɔƒo Afrika nutome',
 			'019' => 'Amerika nutome',
 			'021' => 'Dziehelɔƒo Amerika nutome',
 			'029' => 'Karibbea nutome',
 			'030' => 'Ɣedzeƒe Asia nutome',
 			'034' => 'Anyiehelɔƒo Asia nutome',
 			'035' => 'Anyiehe Ɣedzeƒe Afrika nutome',
 			'039' => 'Anyiehelɔƒo Europa nutome',
 			'053' => 'Australia kple New Zealand nutome',
 			'054' => 'Melanesia nutome',
 			'057' => 'Mikronesia',
 			'061' => 'Pɔlinesia nutome',
 			'142' => 'Asia nutome',
 			'143' => 'Titina Asia nutome',
 			'145' => 'Ɣetoɖoƒelɔƒo Asia nutome',
 			'150' => 'Europa nutome',
 			'151' => 'Ɣedzeƒe Europa nutome',
 			'154' => 'Dziehelɔƒo Europa nutome',
 			'155' => 'Ɣetoɖoƒelɔƒo Europa nutome',
 			'419' => 'Latin Amerika nutome',
 			'AC' => 'Ascension ƒudomekpo nutome',
 			'AD' => 'Andorra nutome',
 			'AE' => 'United Arab Emirates nutome',
 			'AF' => 'Afghanistan nutome',
 			'AG' => '́Antigua kple Barbuda nutome',
 			'AI' => 'Anguilla nutome',
 			'AL' => 'Albania nutome',
 			'AM' => 'Armenia nutome',
 			'AO' => 'Angola nutome',
 			'AQ' => 'Antartica nutome',
 			'AR' => 'Argentina nutome',
 			'AS' => 'Amerika Samoa nutome',
 			'AT' => 'Austria nutome',
 			'AU' => 'Australia nutome',
 			'AW' => 'Aruba nutome',
 			'AX' => 'Åland ƒudomekpo nutome',
 			'AZ' => 'Azerbaijan nutome',
 			'BA' => 'Bosnia kple Herzergovina nutome',
 			'BB' => 'Barbados nutome',
 			'BD' => 'Bangladesh nutome',
 			'BE' => 'Belgium nutome',
 			'BF' => 'Burkina Faso nutome',
 			'BG' => 'Bulgaria nutome',
 			'BH' => 'Bahrain nutome',
 			'BI' => 'Burundi nutome',
 			'BJ' => 'Benin nutome',
 			'BL' => 'Saint Barthélemy nutome',
 			'BM' => 'Bermuda nutome',
 			'BN' => 'Brunei nutome',
 			'BO' => 'Bolivia nutome',
 			'BQ' => 'Karibbeatɔwo ƒe Nedalanɖs nutome',
 			'BR' => 'Brazil nutome',
 			'BS' => 'Bahamas nutome',
 			'BT' => 'Bhutan nutome',
 			'BV' => 'Bouvet ƒudomekpo nutome',
 			'BW' => 'Botswana nutome',
 			'BY' => 'Belarus nutome',
 			'BZ' => 'Belize nutome',
 			'CA' => 'Canada nutome',
 			'CC' => 'Kokos (Kiling) fudomekpo nutome',
 			'CD' => 'Kongo Kinshasa nutome',
 			'CD@alt=variant' => 'Kongo demokratik repɔblik nutome',
 			'CF' => 'Titina Afrika repɔblik nutome',
 			'CG' => 'Kongo Brazzaville nutome',
 			'CG@alt=variant' => 'Kongo repɔblik nutome',
 			'CH' => 'Switzerland nutome',
 			'CI' => 'Kote d’Ivoire nutome',
 			'CI@alt=variant' => 'Ivory Kost nutome',
 			'CK' => 'Kook ƒudomekpo nutome',
 			'CL' => 'Tsile nutome',
 			'CM' => 'Kamerun nutome',
 			'CN' => 'Tsaina nutome',
 			'CO' => 'Kolombia nutome',
 			'CP' => 'Klipaton ƒudomekpo nutome',
 			'CR' => 'Kosta Rika nutome',
 			'CU' => 'Kuba nutome',
 			'CV' => 'Kape Verde nutome',
 			'CW' => 'Kurakao nutome',
 			'CX' => 'Kristmas ƒudomekpo nutome',
 			'CY' => 'Saiprus nutome',
 			'CZ' => 'Tsɛk repɔblik nutome',
 			'DE' => 'Germania nutome',
 			'DG' => 'Diego Garsia nutome',
 			'DJ' => 'Dzibuti nutome',
 			'DK' => 'Denmark nutome',
 			'DM' => 'Dominika nutome',
 			'DO' => 'Dominika repɔblik nutome',
 			'DZ' => 'Algeria nutome',
 			'EA' => 'Keuta and Melilla nutome',
 			'EC' => 'Ekuadɔ nutome',
 			'EE' => 'Estonia nutome',
 			'EG' => 'Egypte nutome',
 			'EH' => 'Ɣetoɖoƒe Sahara nutome',
 			'ER' => 'Eritrea nutome',
 			'ES' => 'Spain nutome',
 			'ET' => 'Etiopia nutome',
 			'EU' => 'Europa Wɔɖeka nutome',
 			'FI' => 'Finland nutome',
 			'FJ' => 'Fidzi nutome',
 			'FK' => 'Falkland ƒudomekpowo nutome',
 			'FK@alt=variant' => 'Falkland ƒudomekpowo (Islas Malvinas) nutome',
 			'FM' => 'Mikronesia nutome',
 			'FO' => 'Faroe ƒudomekpowo nutome',
 			'FR' => 'France nutome',
 			'GA' => 'Gabɔn nutome',
 			'GB' => 'United Kingdom nutome',
 			'GD' => 'Grenada nutome',
 			'GE' => 'Georgia nutome',
 			'GF' => 'Frentsi Gayana nutome',
 			'GG' => 'Guernse nutome',
 			'GH' => 'Ghana nutome',
 			'GI' => 'Gibraltar nutome',
 			'GL' => 'Grinland nutome',
 			'GM' => 'Gambia nutome',
 			'GN' => 'Guini nutome',
 			'GP' => 'Guadelupe nutome',
 			'GQ' => 'Ekuatorial Guini nutome',
 			'GR' => 'Greece nutome',
 			'GS' => 'Anyiehe Georgia kple Anyiehe Sandwich ƒudomekpowo nutome',
 			'GT' => 'Guatemala nutome',
 			'GU' => 'Guam nutome',
 			'GW' => 'Gini-Bisao nutome',
 			'GY' => 'Guyanadu',
 			'HK' => 'Hɔng Kɔng SAR Tsaina nutome',
 			'HK@alt=short' => 'Hɔng Kɔng nutome',
 			'HM' => 'Heard kple Mcdonald ƒudomekpowo nutome',
 			'HN' => 'Hondurasdu',
 			'HR' => 'Kroatsia nutome',
 			'HT' => 'Haiti nutome',
 			'HU' => 'Hungari nutome',
 			'IC' => 'Kanari ƒudomekpowo nutome',
 			'ID' => 'Indonesia nutome',
 			'IE' => 'Ireland nutome',
 			'IL' => 'Israel nutome',
 			'IM' => 'Aisle of Man nutome',
 			'IN' => 'India nutome',
 			'IO' => 'Britaintɔwo ƒe india ƒudome nutome',
 			'IQ' => 'iraqdukɔ',
 			'IR' => 'Iran nutome',
 			'IS' => 'Aiseland nutome',
 			'IT' => 'Italia nutome',
 			'JE' => 'Dzɛse nutome',
 			'JM' => 'Dzamaika nutome',
 			'JO' => 'Yordan nutome',
 			'JP' => 'Dzapan nutome',
 			'KE' => 'Kenya nutome',
 			'KG' => 'Kirgizstan nutome',
 			'KH' => 'Kambodia nutome',
 			'KI' => 'Kiribati nutome',
 			'KM' => 'Komoros nutome',
 			'KN' => 'Saint Kitis kple Nevis nutome',
 			'KP' => 'Dziehe Korea nutome',
 			'KR' => 'Anyiehe Korea nutome',
 			'KW' => 'Kuwait nutome',
 			'KY' => 'Kayman ƒudomekpowo nutome',
 			'KZ' => 'Kazakstan nutome',
 			'LA' => 'Laos nutome',
 			'LB' => 'Lebanɔn nutome',
 			'LC' => 'Saint Lusia nutome',
 			'LI' => 'Litsenstein nutome',
 			'LK' => 'Sri Lanka nutome',
 			'LR' => 'Liberia nutome',
 			'LS' => 'Lɛsoto nutome',
 			'LT' => 'Lituania nutome',
 			'LU' => 'Lazembɔg nutome',
 			'LV' => 'Latvia nutome',
 			'LY' => 'Libya nutome',
 			'MA' => 'Moroko nutome',
 			'MC' => 'Monako nutome',
 			'MD' => 'Moldova nutome',
 			'ME' => 'Montenegro nutome',
 			'MF' => 'Saint Martin nutome',
 			'MG' => 'Madagaska nutome',
 			'MH' => 'Marshal ƒudomekpowo nutome',
 			'ML' => 'Mali nutome',
 			'MM' => 'Myanmar (Burma) nutome',
 			'MN' => 'Mongolia nutome',
 			'MO' => 'Macau SAR Tsaina nutome',
 			'MO@alt=short' => 'Macau nutome',
 			'MP' => 'Dziehe Marina ƒudomekpowo nutome',
 			'MQ' => 'Martiniki nutome',
 			'MR' => 'Mauritania nutome',
 			'MS' => 'Montserrat nutome',
 			'MT' => 'Malta nutome',
 			'MU' => 'mauritiusdukɔ',
 			'MV' => 'maldivesdukɔ',
 			'MW' => 'Malawi nutome',
 			'MX' => 'Mexico nutome',
 			'MY' => 'Malaysia nutome',
 			'MZ' => 'Mozambiki nutome',
 			'NA' => 'Namibia nutome',
 			'NC' => 'New Kaledonia nutome',
 			'NE' => 'Niger nutome',
 			'NF' => 'Norfolk ƒudomekpo nutome',
 			'NG' => 'Nigeria nutome',
 			'NI' => 'Nicaraguadukɔ',
 			'NL' => 'Netherlands nutome',
 			'NO' => 'Norway nutome',
 			'NP' => 'Nepal nutome',
 			'NR' => 'Nauru nutome',
 			'NU' => 'Niue nutome',
 			'NZ' => 'New Zealand nutome',
 			'OM' => 'Oman nutome',
 			'PA' => 'Panama nutome',
 			'PE' => 'Peru nutome',
 			'PF' => 'Frentsi Pɔlinesia nutome',
 			'PG' => 'Papua New Gini nutome',
 			'PH' => 'Filipini nutome',
 			'PK' => 'Pakistan nutome',
 			'PL' => 'Poland nutome',
 			'PM' => 'Saint Pierre kple Mikelɔn nutome',
 			'PN' => 'Pitkairn ƒudomekpo nutome',
 			'PR' => 'Puerto Riko nutome',
 			'PS' => 'Palestinia nutome',
 			'PT' => 'Portugal nutome',
 			'PW' => 'Palau nutome',
 			'PY' => 'Paragua nutome',
 			'QA' => 'Katar nutome',
 			'QO' => 'Outlaying Oceania nutome',
 			'RE' => 'Réunion nutome',
 			'RO' => 'Romania nutome',
 			'RS' => 'Serbia nutome',
 			'RU' => 'Russia nutome',
 			'RW' => 'Rwanda nutome',
 			'SA' => 'Saudi Arabia nutome',
 			'SB' => 'Solomon ƒudomekpowo nutome',
 			'SC' => 'Seshɛls nutome',
 			'SD' => 'Sudan nutome',
 			'SE' => 'Sweden nutome',
 			'SG' => 'Singapɔr nutome',
 			'SH' => 'Saint Helena nutome',
 			'SI' => 'Slovenia nutome',
 			'SJ' => 'Svalbard kple Yan Mayen nutome',
 			'SK' => 'Slovakia nutome',
 			'SL' => 'Sierra Leone nutome',
 			'SM' => 'San Marino nutome',
 			'SN' => 'Senegal nutome',
 			'SO' => 'Somalia nutome',
 			'SR' => 'Suriname nutome',
 			'SS' => 'Anyiehe Sudan nutome',
 			'ST' => 'São Tomé kple Príncipe nutome',
 			'SV' => 'El Salvadɔ nutome',
 			'SX' => 'Sint Maarten nutome',
 			'SY' => 'Siria nutome',
 			'SZ' => 'Swaziland nutome',
 			'TA' => 'Tristan da Kunha nutome',
 			'TC' => 'Tɛks kple Kaikos ƒudomekpowo nutome',
 			'TD' => 'Tsad nutome',
 			'TF' => 'Anyiehe Franseme nutome',
 			'TG' => 'Togo nutome',
 			'TH' => 'Thailand nutome',
 			'TJ' => 'Tajikistan nutome',
 			'TK' => 'Tokelau nutome',
 			'TL' => 'Timor-Leste nutome',
 			'TL@alt=variant' => 'Ɣedzeƒe Timɔ nutome',
 			'TM' => 'Tɛkmenistan nutome',
 			'TN' => 'Tunisia nutome',
 			'TO' => 'Tonga nutome',
 			'TR' => 'Tɛki nutome',
 			'TT' => 'Trinidad kple Tobago nutome',
 			'TV' => 'Tuvalu nutome',
 			'TW' => 'Taiwan nutome',
 			'TZ' => 'Tanzania nutome',
 			'UA' => 'Ukraine nutome',
 			'UG' => 'Uganda nutome',
 			'UM' => 'U.S. Minor Outlaying ƒudomekpowo nutome',
 			'US' => 'USA nutome',
 			'UY' => 'uruguaydukɔ',
 			'UZ' => 'Uzbekistan nutome',
 			'VA' => 'Vatikandu nutome',
 			'VC' => 'Saint Vincent kple Grenadine nutome',
 			'VE' => 'Venezuela nutome',
 			'VG' => 'Britaintɔwo ƒe Virgin ƒudomekpowo nutome',
 			'VI' => 'U.S. Vɛrgin ƒudomekpowo nutome',
 			'VN' => 'Vietnam nutome',
 			'VU' => 'Vanuatu nutome',
 			'WF' => 'Wallis kple Futuna nutome',
 			'WS' => 'Samoa nutome',
 			'YE' => 'Yemen nutome',
 			'YT' => 'Mayotte nutome',
 			'ZA' => 'Anyiehe Africa nutome',
 			'ZM' => 'Zambia nutome',
 			'ZW' => 'Zimbabwe nutome',
 			'ZZ' => 'nutome manya',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'ALALC97' => 'ALALC9',
 			'BISCAYAN' => 'BISCAYA',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'kalenda',
 			'collation' => 'tutuɖo',
 			'currency' => 'gaɖuɖu',
 			'numbers' => 'nɔmbawo',

		}
	},
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => {
 				'buddhist' => q{buddha subɔlawo ƒe kalenda},
 				'chinese' => q{chinatɔwo ƒe kalenda},
 				'coptic' => q{coptia kalenda},
 				'ethiopic' => q{ethiopiatɔwo ƒe kalenda},
 				'ethiopic-amete-alem' => q{ethiopia amate alemtɔwo ƒe kalenda},
 				'gregorian' => q{Gregorian kalenda},
 				'hebrew' => q{hebritɔwo ƒe kalenda},
 				'indian' => q{india dukɔ ƒe kalenda},
 				'islamic' => q{islam subɔlawo ƒe kalenda},
 				'islamic-civil' => q{islam subɔlawo ƒe sivil kalenda},
 				'japanese' => q{japantɔwo ƒe kalenda},
 				'persian' => q{persiatɔwo ƒe kalenda},
 				'roc' => q{china repɔbliktɔwo ƒe kalenda tso 1912},
 			},
 			'collation' => {
 				'big5han' => q{blema chinatɔwo ƒe ɖoɖomɔ nu},
 				'dictionary' => q{nuɖoɖo ɖe nyagɔmeɖegbalẽ ƒe ɖoɖomɔ nu},
 				'ducet' => q{nuɖoɖo ɖe unicode ƒe ɖoɖo nu},
 				'gb2312han' => q{chinagbe yeye ƒe ɖoɖomɔ nu},
 				'phonebook' => q{fonegbalẽ me ɖoɖomɔ nu},
 				'pinyin' => q{pinyin ɖoɖomɔ nu},
 				'reformed' => q{nugbugbɔtoɖo ƒe ɖoɖomɔ nu},
 				'search' => q{nudidi hena zazã gbadza},
 				'searchjl' => q{nudidi le hangul ƒe ɖoɖo gbãtɔ nu},
 				'stroke' => q{stroke ɖoɖomɔ nu},
 				'traditional' => q{blema ɖoɖomɔ nu},
 				'unihan' => q{ɖoɖomɔnutɔxɛ manɔŋu stroke ƒe ɖoɖo nu},
 			},
 			'numbers' => {
 				'arab' => q{india ƒe arabia digitwo},
 				'arabext' => q{india ƒe arabia digitwo dzi yiyi},
 				'armn' => q{armeniatɔwo ƒe numeralwo},
 				'armnlow' => q{armeniatɔwo ƒe numeral suetɔwo},
 				'bali' => q{balina digitwo},
 				'beng' => q{bengalitɔwo ƒe digitwo},
 				'cham' => q{tsam digitwo},
 				'deva' => q{devanagari digitwo},
 				'ethi' => q{ethiopia numeralwo},
 				'fullwide' => q{digit kekeme blibotɔwo},
 				'geor' => q{georgiatɔwo ƒe numeralwo},
 				'grek' => q{greecetɔwo ƒe nemeralwo},
 				'greklow' => q{greecetɔwo ƒe numeral suetɔwo},
 				'gujr' => q{gujarati digitwo},
 				'guru' => q{gurmukhi digitwo},
 				'hanidec' => q{chinatɔwo ƒe nɔmba madeblibowo},
 				'hans' => q{chinatɔwo ƒe numeralwo},
 				'hansfin' => q{chinatɔwo ƒe gadzikpɔ numeralwo},
 				'hant' => q{blema chinatɔwo ƒe numeralwo},
 				'hantfin' => q{blema chinatɔwo ƒe gadzikpɔ numeralwo},
 				'hebr' => q{hebritɔwo ƒe numeralwo},
 				'java' => q{dzava digitwo},
 				'jpan' => q{japantɔwo ƒe numeralwo},
 				'jpanfin' => q{japantɔwo ƒe gadzikpɔnumeralwo},
 				'kali' => q{kali digitwo},
 				'khmr' => q{khmertɔwo ƒe nɔmbawo},
 				'knda' => q{kannadatɔwo ƒe digitwo},
 				'lana' => q{lana digitwo},
 				'lanatham' => q{lanatham digitwo},
 				'laoo' => q{laotɔwo ƒe digitwo},
 				'latn' => q{Nɔmbawo le Latingbe ƒe ɖoɖo nu},
 				'lepc' => q{leptsa digitwo},
 				'limb' => q{limbu digitwo},
 				'mlym' => q{malaya digitwo},
 				'mong' => q{mongolia digitwo},
 				'mtei' => q{meetei mayek digitwo},
 				'mymr' => q{myanmar digitwo},
 				'mymrshan' => q{myanmar shan digitwo},
 				'nkoo' => q{n’ko digitwo},
 				'olck' => q{ol tsiki digitwo},
 				'orya' => q{oriya digitwo},
 				'roman' => q{romatɔwo ƒe numeralwo},
 				'romanlow' => q{romatɔwo ƒe numeral suetɔwo},
 				'saur' => q{saurashtra digitwo},
 				'sund' => q{sundana digitwo},
 				'talu' => q{tai lue digit yeye wo},
 				'taml' => q{tamil numeralwo},
 				'tamldec' => q{tamil digitwo},
 				'telu' => q{telegu digitwo},
 				'thai' => q{thai digitwo},
 				'tibt' => q{tibet digitwo},
 				'vaii' => q{vaii digitwo},
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
			'metric' => q{metric},
 			'UK' => q{uk},
 			'US' => q{us},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'gbegbɔgblɔ {0}',
 			'script' => 'gbeŋɔŋlɔ {0}',
 			'region' => 'memama {0}',

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
			auxiliary => qr{[ăâåäā æ cç ĕêë ĭîï j ñ ŏôöø œ q ŭûü ÿ]},
			index => ['A', 'B', 'D', 'Ɖ', 'E', 'Ɛ', 'F', 'Ƒ', 'G', 'Ɣ', 'H', 'X', 'I', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'R', 'S', 'T', 'U', 'V', 'Ʋ', 'W', 'Y', 'Z'],
			main => qr{[aáàã b d ɖ eéèẽ ɛ{ɛ́}{ɛ̀}{ɛ̃} f ƒ g ɣ h x iíìĩ k l m n ŋ oóòõ ɔ{ɔ́}{ɔ̀}{ɔ̃} p r s t uúùũ v ʋ w y z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] \{ \} § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'D', 'Ɖ', 'E', 'Ɛ', 'F', 'Ƒ', 'G', 'Ɣ', 'H', 'X', 'I', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'R', 'S', 'T', 'U', 'V', 'Ʋ', 'W', 'Y', 'Z'], };
},
);


has 'more_information' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{...},
);

has 'duration_units' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { {
				hm => '\'ga\' h:mm',
				hms => '\'ga\' h:mm:ss',
				ms => 'aɖabaƒoƒo m:ss',
			} }
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q(aɖabaƒoƒo {0}),
						'other' => q(aɖabaƒoƒo {0}),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q(aɖabaƒoƒo {0}),
						'other' => q(aɖabaƒoƒo {0}),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekend),
						'one' => q(sekend {0} wo),
						'other' => q(sekend {0} wo),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekend),
						'one' => q(sekend {0} wo),
						'other' => q(sekend {0} wo),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(agbadroƒe),
						'one' => q(agbadroƒe {0}),
						'other' => q(agbadroƒe {0}),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(agbadroƒe),
						'one' => q(agbadroƒe {0}),
						'other' => q(agbadroƒe {0}),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(abɔ),
						'one' => q(abɔ {0}),
						'other' => q(abɔ {0}),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(abɔ),
						'one' => q(abɔ {0}),
						'other' => q(abɔ {0}),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(ŋkeke),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(ŋkeke),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(gaƒoƒo),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(gaƒoƒo),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(aɖabaƒoƒo),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(aɖabaƒoƒo),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q(s {0}),
						'other' => q(s {0}),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q(s {0}),
						'other' => q(s {0}),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(kɔsiɖa),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(kɔsiɖa),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ƒe),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ƒe),
					},
				},
				'short' => {
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(ŋkekewo),
						'one' => q(ŋkeke {0}),
						'other' => q(ŋkeke {0}),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(ŋkekewo),
						'one' => q(ŋkeke {0}),
						'other' => q(ŋkeke {0}),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(gaƒoƒowo),
						'one' => q(gaƒoƒo {0}),
						'other' => q(gaƒoƒo {0}),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(gaƒoƒowo),
						'one' => q(gaƒoƒo {0}),
						'other' => q(gaƒoƒo {0}),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(aɖabaƒoƒowo),
						'one' => q(a {0}),
						'other' => q(a {0}),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(aɖabaƒoƒowo),
						'one' => q(a {0}),
						'other' => q(a {0}),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(ɣletiwo),
						'one' => q(ɣleti {0}),
						'other' => q(ɣleti {0}),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(ɣletiwo),
						'one' => q(ɣleti {0}),
						'other' => q(ɣleti {0}),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q(sekend {0}),
						'other' => q(sekend {0}),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q(sekend {0}),
						'other' => q(sekend {0}),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(kɔsiɖawo),
						'one' => q(kɔsiɖa {0}),
						'other' => q(kɔsiɖa {0}),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(kɔsiɖawo),
						'one' => q(kɔsiɖa {0}),
						'other' => q(kɔsiɖa {0}),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ƒewo),
						'one' => q(ƒe {0}),
						'other' => q(ƒe {0}),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ƒewo),
						'one' => q(ƒe {0}),
						'other' => q(ƒe {0}),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ɛ|Ɛ|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ao|A|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0}, kple {1}),
				2 => q({0} kple {1}),
		} }
);

has 'minimum_grouping_digits' => (
	is			=>'ro',
	isa			=> Int,
	init_arg	=> undef,
	default		=> 3,
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'nan' => q(mnn),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'long' => {
				'1000' => {
					'one' => 'akpe 0',
					'other' => 'akpe 0',
				},
				'10000' => {
					'one' => 'akpe 00',
					'other' => 'akpe 00',
				},
				'100000' => {
					'one' => 'akpe 000',
					'other' => 'akpe 000',
				},
				'1000000' => {
					'one' => 'miliɔn 0',
					'other' => 'miliɔn 0',
				},
				'10000000' => {
					'one' => 'miliɔn 00',
					'other' => 'miliɔn 00',
				},
				'100000000' => {
					'one' => 'miliɔn 000',
					'other' => 'miliɔn 000',
				},
				'1000000000' => {
					'one' => 'biliɔn 0',
					'other' => 'biliɔn 0',
				},
				'10000000000' => {
					'one' => 'biliɔn 00',
					'other' => 'biliɔn 00',
				},
				'100000000000' => {
					'one' => 'biliɔn 000',
					'other' => 'biliɔn 000',
				},
				'1000000000000' => {
					'one' => '0 triliɔn',
					'other' => '0 triliɔn',
				},
				'10000000000000' => {
					'one' => 'triliɔn 00',
					'other' => 'triliɔn 00',
				},
				'100000000000000' => {
					'one' => 'triliɔn 000',
					'other' => 'triliɔn 000',
				},
			},
			'short' => {
				'1000000000' => {
					'one' => '0B',
					'other' => '0B',
				},
				'10000000000' => {
					'one' => '00B',
					'other' => '00B',
				},
				'100000000000' => {
					'one' => '000B',
					'other' => '000B',
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
						'negative' => '(¤#,##0.00)',
						'positive' => '¤#,##0.00',
					},
					'standard' => {
						'positive' => '¤#,##0.00',
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
				'currency' => q(andorraga peseta),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(united arab emiratesga dirham),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(afghanistanga afghani \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afghanistanga afghani),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(albaniaga lek \(1946–1965\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(albaniaga lek),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(armeniaga dram),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(netherlands antilleaga guilder),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(angolaga kwanza),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(angolaga kwanza \(1977–1991\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(angolaga kwanza \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(angolaga kwanza xoxotɔ \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(argentinaga austral),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(argentinaga peso ley \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(argentinaga peso \(1881–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(argentinaga peso \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(argentinaga peso),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(ɔstriaga schilling),
			},
		},
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(Australiaga dollar),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(arubaga lorin),
				'one' => q(arubaga florin),
				'other' => q(arubaga florin),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(azerbaidzanga manat \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(azerbaidzanga manat),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(bosnia-herzegovinaga dinar \(1992–1994\)),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(bosnia-herzegovinaga convertible mark),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(bosnia kple herzegovinaga dinar yeyètɔ \(1994–1997\)),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(barbadosga dollar),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(bangladeshga taka),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(beldziumga franc \(convertible\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(beldziumga franc),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(beldziumga franc \(financial\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(bɔlgariaga hard lev),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(bɔlgariaga socialist lev),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(bulgariaga lev),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(bulgariaga lev \(1879–1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(bahrainga dinar),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(burundiga franc),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(bermudaga dollar),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(bruneiga dollar),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(boliviaga boliviano),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(boliviaga boliviano \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(boliviaga peso),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(boliviaga mvdol),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(braziliaga cruzeiro xoxotɔ \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(brazilia cruzado \(1986–1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(braziliaga cruzeiro xoxotɔ gbãtɔ \(1990–1993\)),
				'one' => q(braziliaga cruzeiro xoxotɔ gbãtɔ \(1990–1993\)),
				'other' => q(braziliaga cruzeiro xoxotɔ gbãtɔwo \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(braziliaga real),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(brazilia cruzado xoxotɔ \(1989–1990\)),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(braziliaga cruzeiro \(1993–1994\)),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(braziliaga cruzeiro \(1942–1967\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(bahamasga dollar),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(bhutanga ngultrum),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(burmaga kyat),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(botswanaga pula),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(belarusiaga ruble yeytɔ \(1994–1999\)),
				'one' => q(belarusiaga ruble yeytɔ \(1994–1999\)),
				'other' => q(belarusiaga ruble yeyetɔ \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(belarusiaga ruble),
				'one' => q(belarusiaga ruble),
				'other' => q(belarusiaga rublewo),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(belarusiaga ruble \(2000–2016\)),
				'one' => q(belarusiaga ruble \(2000–2016\)),
				'other' => q(belarusiaga rublewo \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(belizega dollar),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(canadaga dollar),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(kongoga franc),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(WIR euro CHE),
				'one' => q(WIR euro CHE),
				'other' => q(WIR eurowo CHE),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(switzerlandga franc),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(WIR euro CHW),
				'one' => q(WIR euro CHW),
				'other' => q(WIR eurowo CHW),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(tsilega escudo),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(tsilegakɔnta dzidzenu UF),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(chilega peso),
			},
		},
		'CNX' => {
			display_name => {
				'currency' => q(tsainatɔwo ƒe gadzraɖoƒe dollar),
				'one' => q(tsainatɔwo ƒe gadzraɖoƒe dollar),
				'other' => q(tsainatɔwo ƒe gadzraɖoƒe dollarwo),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Chinesega yuan),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(colombiaga peso),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(kolombiaga vavãtɔ),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(costa ricaga colón),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(serbiaga dinar \(2002–2006\)),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(tsɛkoslovakiaga hard koruna),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(cubaga convertible peso),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(cubaga peso),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(kape verdega escudo),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(saipriɔtga pound),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(czechga koruna),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(ɣedzeƒe germaniaga mark),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(germaniaga mark),
				'one' => q(germaniaga mark),
				'other' => q(germaniaga markwo),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(dziboutiga franc),
				'one' => q(dziboutiga franc),
				'other' => q(dzibutiga franc),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(denmarkga krone),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(dominicaga peso),
				'one' => q(dominikaga peso),
				'other' => q(dominikaga peso),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(aldzeriaga dinar),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(ekuadɔga sucre),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(ekuadɔ dzidzenu matrɔmatrɔ),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(estoniaga kroon),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(egyptega pound),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(eritreaga nakfa),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(spaniaga peseta \(A\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(spaniaga peseta \(Convertible\)),
				'one' => q(spaniaga peseta \(Convertible\)),
				'other' => q(spaniaga pesetas \(Convertible\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(spaniaga peseta),
				'one' => q(spaniaga peseta),
				'other' => q(spaniaga pesetas),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(ethiopiaga birr),
			},
		},
		'EUR' => {
			display_name => {
				'one' => q(euro),
				'other' => q(euro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(finlandga markka),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(fidziga dollar),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(falkland islands pound),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(frentsiga franc),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(britainga pound),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(dzɔdziaga kupon larit),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(dzɔdziaga lari),
				'one' => q(dzɔdziaga larit),
				'other' => q(dzɔdziaga larit),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(ghana siɖi \(1979–2007\)),
			},
		},
		'GHS' => {
			symbol => 'GH₵',
			display_name => {
				'currency' => q(ghana siɖi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(gilbratarga pound),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(gambiaga dalasi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(giniga franc),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(giniga syli),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(ekuatorial giniga ekwele),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(grisiga drachma),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(guatemalaga quetzal),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(pɔtugaltɔwo ƒe giniga escudo),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(gini-bisau peso),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(guyanaga dollar),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Hong Kongga dollar),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(honduraga lempira),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(kroatiaga dinar),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(croatiaga kuna),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(haitiga gourde),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(hungariaga forint),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Indonesiaga rupiah),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(ireland pound),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(israelga pound),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(israelga sheqel \(1980–1985\)),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(israelga yeyetɔ sheqel),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Indiaga rupee),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(irakga dinar),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(iranga rial),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(aiselandga króna \(1918–1981\)),
				'one' => q(aiselandga króna \(1918–1981\)),
				'other' => q(aiselandga krónur \(1918–1981\)),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(icelandga króna),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(italiaga lira),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(jamaicaga dollar),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(yɔdanga dinar),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Japanesega yen),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(kenyaga shilling),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(kirgistanga som),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(kambodiaga riel),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(komoroga franc),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(dziehe koreaga won),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(anyiehe koreaga hwan \(1953–1962\)),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(anyiehe koreaga won \(1945–1953\)),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(South Koreaga won),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(kuwaitga dinar),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(cayman islandsga dollar),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(kazakhstanga tenge),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(laosga kip),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(lebanonga pound),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(sri lankaga rupee),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(liberiaga dollar),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(lesotoga loti),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(lithuaniaga litas),
				'one' => q(lithuaniaga litas),
				'other' => q(lithuaniaga litai),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(lithuaniaga talonas),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(lazembɔgga convertible franc),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(lazembɔgga franc),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(lazembɔgga gadzikpɔ franc),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(latviaga lats),
				'one' => q(latviaga lats),
				'other' => q(latviaga lati),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(latviaga ruble),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(libyaga dinar),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(morokoga dirham),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(morokoga franc),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(monegaskga franc),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(moldovaga cupon),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(moldovaga leu),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(malagasega ariary),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(malagasega franc),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(marcedoniaga denar),
				'one' => q(makedoniaga denar),
				'other' => q(marcedoniaga denar),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(makedoniaga denar \(1992–1993\)),
				'one' => q(makedoniaga denar \(1992–1993\)),
				'other' => q(makedoniaga denari \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(maliga franc),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(myanmaga kyat),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(mongoliaga tugrik),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(makanesega pataca),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(mɔritaniaga ouguiya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(mɔritaniaga ouguiya),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(maltaga lira),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(maltaga pound),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(mɔritiusga rupee),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(maldiviaga rufiyaa),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(malawiga kwacha),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(mexicoga peso),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(malaysiaga ringit),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(mozambikga metikal),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(namibiaga dollar),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(naidzeriaga naira),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(nikaraguaga córdoba \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(nicaraguaga córdoba),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(hollandga guilder),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(norwayga krone),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(nepalga rupee),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(new zealanɖga dollar),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(omanga rial),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(panamaga balboa),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(peruga inti),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(peruga sol),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(peruga sol \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(papua new guineaga kina),
				'one' => q(papua new giniga kina),
				'other' => q(papua new giniga kina),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(filipiniga peso),
				'one' => q(filipinga peso),
				'other' => q(filipinga peso),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(pakistaniga rupee),
				'one' => q(pakistanga rupee),
				'other' => q(pakistanga rupee),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(polandga zloty),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(polanɖga zloty \(1950–1995\)),
				'one' => q(polandga zloty \(1950–1995\)),
				'other' => q(polandga zloty \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(pɔtugalga escudo),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(paraguayga guarani),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(katarga rial),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(rhodesiaga dollar),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(romaniaga leu \(1952–2006\)),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(romaniaga leu),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(serbiaga dinar),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(russiaga ruble),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(rɔtsiaga ruble \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(rwandaga franc),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Saudi Arabiaga riyal),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(solomon ƒudomekpo dukɔwo ƒe ga dollar),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(sɛtselsga rupee),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(sudanga dinar \(1992–2007\)),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(sudanga pound),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(sudanga pound \(1957–1998\)),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(swedenga krone),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(singapɔga dollar),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(saint helenaga pound),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(slovaniaga tolar),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(slovakga koruna),
				'one' => q(slovakiaga koruna),
				'other' => q(slovakiaga koruna),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(sierra leonega leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(sierra leonega leone \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(somaliaga shilling),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(surinamga dollar),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(surinamega guilder),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(anyiehe sudanga pound),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(são tomé kple príncipega dobra \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(são tomé kple príncipega dobra),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(sovietga rouble),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(salvadɔga colón),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(syriaga pound),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(swaziga lilangeni),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Thailandga baht),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(tajikistanga ruble),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(tajikistanga somoni),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(turkmenistanga manat \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(turkmenistanga manat),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(tunisiaga dinar),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(tonagaga pa’anga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(timɔga escudo),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(tɛkiiga lira \(1922–2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Turkishga lira),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(trinidad & tobagoga dollar),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Taiwanga dollar),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Tanzaniatɔwofɛgadudu),
				'one' => q(tanzaniaga shilling),
				'other' => q(tanzaniaga shilling),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(ukrainega hryvnia),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(ukrainega karbovanet),
				'one' => q(ukrainega karbovanet),
				'other' => q(ukrainega karbovantsiv),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(ugandaga shilling \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(ugandaga shilling),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(us ga dollar),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(us ga dollar \(ŋkeke si gbɔna tɔ\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(us ga dollar \(ŋkeke ma ke tɔ\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(uruguayga peso UYI),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(uruguayga peso \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(uruguayga peso),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(uzbekistanga som),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(venezuelaga bolívar \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(venezuelaga bolívar \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(venezuelaga bolívar),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(vietnamga dong),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(vietnamga dong \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vanuatuga vatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(samaoga tala),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(ɣetoɖofe afrikaga CFA franc BEAC),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(klosalo),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(sika),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(europa dzidzenu xba),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(europa gadzidzenu xbb),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(europa kɔnta dzidzenu xbc),
				'one' => q(europa kɔnta dzidzenu),
				'other' => q(europa kɔnta dzidzenu),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(europa kɔnta dzidzenu xbd),
				'one' => q(europaga \(XBD\)),
				'other' => q(europaga \(XBD\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(east caribbeanga dollar),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(gaɖuɖu ɖoɖo tɔxɛ),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(europa gaɖuɖu),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(fransemega sika franc),
				'one' => q(frentsiga sika franc),
				'other' => q(frentsiga sika franc),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(frentsi UIC-franc),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(ɣetoɖofe afrikaga CFA franc BCEAO),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(palladiumga),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP ga franc),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(platinum),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(RINET gadodo XRE),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(gaɖuɖu dodokpɔ dzesi xts),
				'one' => q(gaɖuɖu dodokpɔ dzesi),
				'other' => q(gaɖuɖu dodokpɔ dzesi),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(gaɖuɖu manya),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(yemeniga dinar),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(yemeniga rial),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(yugoslaviaga hard dinar \(1966–1990\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(yugoslaviaga yeyetɔ dinar \(1994–2002\)),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(yugoslaviaga convertible dinar \(1990–1992\)),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(yugoslaviaga dinar \(1992–1993\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(anyiehe afrikaga rand \(gadzikpɔtɔ\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(South Africaga rand),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(zambiaga kwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(zambiaga kwacha),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(zairega yeyetɔ zaire),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(zairega zaire \(1971–1993\)),
				'one' => q(zairega zaire \(1971–1993\)),
				'other' => q(zairega zaires \(1971–1993\)),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(zimbabwega dollar \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(zimbabwega dollar \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(zimbabwega dollar \(2008\)),
			},
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'chinese' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'dzv',
							'dzd',
							'ted',
							'afɔ',
							'dam',
							'mas',
							'sia',
							'dea',
							'any',
							'kel',
							'ade',
							'dzm'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfiẽ',
							'damɛ',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'dzv',
							'dzd',
							'ted',
							'afɔ',
							'dam',
							'mas',
							'sia',
							'dea',
							'any',
							'kele',
							'ade',
							'dzm'
						],
						leap => [
							
						],
					},
				},
			},
			'coptic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'dzv',
							'dzd',
							'ted',
							'afɔ',
							'dam',
							'mas',
							'sia',
							'dea',
							'any',
							'kel',
							'ade',
							'dzm',
							'foa'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfiẽ',
							'damɛ',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome',
							'ƒoave'
						],
						leap => [
							
						],
					},
				},
			},
			'ethiopic' => {
				'format' => {
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfiẽ',
							'damɛ',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome',
							'ƒoave'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'dzv',
							'dzd',
							'ted',
							'afɔ',
							'dam',
							'mas',
							'sia',
							'dea',
							'any',
							'kel',
							'ade',
							'dzm',
							'ƒoa'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfie',
							'damɛ',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome',
							'ƒoave'
						],
						leap => [
							
						],
					},
				},
			},
			'gregorian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'dzv',
							'dzd',
							'ted',
							'afɔ',
							'dam',
							'mas',
							'sia',
							'dea',
							'any',
							'kel',
							'ade',
							'dzm'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfĩe',
							'dama',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'd',
							'd',
							't',
							'a',
							'd',
							'm',
							's',
							'd',
							'a',
							'k',
							'a',
							'd'
						],
						leap => [
							
						],
					},
				},
			},
			'hebrew' => {
				'format' => {
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfiẽ',
							'damɛ',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome',
							'ƒoave'
						],
						leap => [
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'dzv',
							'dzd',
							'ted',
							'afɔ',
							'dam',
							'mas',
							'sia',
							'dea',
							'any',
							'kel',
							'ade',
							'dzm',
							'foa'
						],
						leap => [
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							
						],
					},
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfiẽ',
							'damɛ',
							'masa',
							'siamlɔm',
							'dasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome',
							'ƒoave'
						],
						leap => [
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							
						],
					},
				},
			},
			'indian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'dzv',
							'dzd',
							'ted',
							'afɔ',
							'dam',
							'mas',
							'sia',
							'dea',
							'any',
							'kel',
							'ade',
							'dzm'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔ',
							'damɛ',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfiẽ',
							'damɛ',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome'
						],
						leap => [
							
						],
					},
				},
			},
			'islamic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'dzv',
							'dzd',
							'ted',
							'afɔ',
							'dam',
							'mas',
							'sia',
							'dea',
							'any',
							'kel',
							'ade',
							'dzm'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfiẽ',
							'damɛ',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome'
						],
						leap => [
							
						],
					},
				},
			},
			'persian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'dzv',
							'dzd',
							'ted',
							'afɔ',
							'dam',
							'mas',
							'sia',
							'dea',
							'any',
							'kel',
							'ade',
							'dzm'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'dzove',
							'dzodze',
							'tedoxe',
							'afɔfiẽ',
							'damɛ',
							'masa',
							'siamlɔm',
							'deasiamime',
							'anyɔnyɔ',
							'kele',
							'adeɛmekpɔxe',
							'dzome'
						],
						leap => [
							
						],
					},
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
						mon => 'dzo',
						tue => 'bla',
						wed => 'kuɖ',
						thu => 'yaw',
						fri => 'fiɖ',
						sat => 'mem',
						sun => 'kɔs'
					},
					wide => {
						mon => 'dzoɖa',
						tue => 'blaɖa',
						wed => 'kuɖa',
						thu => 'yawoɖa',
						fri => 'fiɖa',
						sat => 'memleɖa',
						sun => 'kɔsiɖa'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'd',
						tue => 'b',
						wed => 'k',
						thu => 'y',
						fri => 'f',
						sat => 'm',
						sun => 'k'
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
				'format' => {
					abbreviated => {0 => 'k1',
						1 => 'k2',
						2 => 'k3',
						3 => 'k4'
					},
					wide => {0 => 'kɔta gbãtɔ',
						1 => 'kɔta evelia',
						2 => 'kɔta etɔ̃lia',
						3 => 'kɔta enelia'
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
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'coptic') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'indian') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 500;
					return 'morning2' if $time >= 500
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
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
					'afternoon1' => q{ŋdɔ},
					'afternoon2' => q{ɣetrɔ},
					'am' => q{ŋdi},
					'evening1' => q{fiẽ},
					'morning1' => q{fɔŋli},
					'morning2' => q{ŋdi},
					'night1' => q{zã},
					'pm' => q{ɣetrɔ},
				},
				'narrow' => {
					'am' => q{ŋ},
					'pm' => q{ɣ},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'am' => q{ŋ},
					'pm' => q{ɣ},
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
		'buddhist' => {
		},
		'chinese' => {
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'HYV',
				'1' => 'Yŋ'
			},
			narrow => {
				'0' => 'hY'
			},
			wide => {
				'0' => 'Hafi Yesu Va',
				'1' => 'Yesu ŋɔli'
			},
		},
		'hebrew' => {
			abbreviated => {
				'0' => 'ŋdi'
			},
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
		},
		'persian' => {
		},
		'roc' => {
			abbreviated => {
				'0' => 'hafi R.O.C.'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'chinese' => {
			'full' => q{EEEE, U MMMM dd 'lia'},
			'long' => q{U MMMM d 'lia'},
			'medium' => q{U MMM d 'lia'},
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{EEEE, MMMM d 'lia' y G},
			'long' => q{MMMM d 'lia' y G},
			'medium' => q{MMM d 'lia', y G},
			'short' => q{M/d/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, MMMM d 'lia' y},
			'long' => q{MMMM d 'lia' y},
			'medium' => q{MMM d 'lia', y},
			'short' => q{M/d/yy},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
			'full' => q{EEEE, MMMM dd 'lia', G y},
			'long' => q{MMMM d 'lia', G y},
			'medium' => q{MMM d 'lia', G y},
			'short' => q{dd-MM-GGGGG yy},
		},
		'persian' => {
		},
		'roc' => {
			'full' => q{EEEE, MMMM dd 'lia', G y},
			'long' => q{MMMM d 'lia', G y},
			'medium' => q{MMM d 'lia', G y},
			'short' => q{dd-MM-GGGGG y},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'chinese' => {
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{a 'ga' h:mm:ss zzzz},
			'long' => q{a 'ga' h:mm:ss z},
			'medium' => q{a 'ga' h:mm:ss},
			'short' => q{a 'ga' h:mm},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
		},
		'persian' => {
		},
		'roc' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'chinese' => {
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{0} {1}},
			'long' => q{{0} {1}},
			'medium' => q{{0} {1}},
			'short' => q{{0} {1}},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
		},
		'persian' => {
		},
		'roc' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
			hm => q{a 'ga' h: 'aɖabaƒoƒo' mm},
			hms => q{a 'ga' h: 'aɖabaƒoƒo' mm:ss},
			ms => q{'ga' mm:ss},
		},
		'generic' => {
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d 'lia' y G},
			GyMMMd => q{MMM d 'lia', y G},
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d 'lia'},
			MMMMEd => q{E, MMMM d 'lia'},
			MMMMd => q{MMMM d 'lia'},
			MMMd => q{MMM d 'lia'},
			Md => q{M/d},
			h => q{a 'ga' h},
			hm => q{a 'ga' h:mm},
			hms => q{a 'ga' h:mm:ss},
			ms => q{'aɖabaƒoƒo' mm:ss},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y G},
			yyyyMEd => q{E, M/d/y G},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, MMM d 'lia' y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{MMM d 'lia', y G},
			yyyyMd => q{M/d/y G},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Bh => q{'ga' h 'le' B 'me'},
			Bhm => q{'ga' h 'aɖabaƒoƒo' mm 'le' B 'me'},
			Bhms => q{h:mm:ss 'le' B 'me'},
			EBhm => q{'ga' h:mm 'le' E B 'me'},
			EBhms => q{'ga' h:mm:ss 'le' E B 'me'},
			EHm => q{E 'ga' HH:mm},
			EHms => q{E 'ga' HH:mm:ss},
			Ed => q{E d},
			Ehm => q{E a 'ga' h:mm},
			Ehms => q{E a 'ga' h:mm:ss},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d 'lia' y G},
			GyMMMd => q{MMM d 'lia', y G},
			Hmsv => q{'ga' HH:mm:ss 'le' v},
			Hmv => q{'ga' HH:mm 'le' v},
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d 'lia'},
			MMMMEd => q{E, MMMM d 'lia'},
			MMMMW => q{MMMM 'ƒe' 'kɔsiɖa' W 'lia'},
			MMMMd => q{MMMM d 'lia'},
			MMMd => q{MMM d 'lia'},
			Md => q{M/d},
			h => q{a 'ga' h},
			hm => q{a 'ga' h:mm},
			hms => q{a 'ga' h:mm:ss},
			hmsv => q{a 'ga' h:mm:ss 'le' v},
			hmv => q{a 'ga' h:mm 'le' v},
			ms => q{'aɖabaƒoƒo' mm:ss},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yMMMd => q{MMM d 'lia', y},
			yMd => q{M/d/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'kɔsiɖa' w 'lia' 'le' 'ƒe' Y 'me'},
		},
		'japanese' => {
			MMMEd => q{E MMM d 'lia'},
		},
		'roc' => {
			MMMEd => q{E MMM d 'lia'},
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
			M => {
				M => q{'ɣleti' M 'lia' – 'ɣleti' M 'lia'},
			},
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, MMM d 'lia' – E, MMM d 'lia'},
				d => q{E, MMM d 'lia' – E, MMM d 'lia'},
			},
			MMMd => {
				M => q{MMM d 'lia' – MMM d 'lia'},
				d => q{MMM d 'lia' – d 'lia'},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			h => {
				a => q{a h – a h},
				h => q{a h–h},
			},
			hm => {
				a => q{a 'ga' h:mm – a 'ga' h:mm},
				h => q{a 'ga' h:mm - 'ga' h:mm},
				m => q{a 'ga' h:mm – 'ga' h:mm},
			},
			hmv => {
				a => q{a 'ga' h:mm – a 'ga' h:mm v},
				h => q{a 'ga' h:mm–h:mm v},
				m => q{a h:mm–h:mm v},
			},
			hv => {
				a => q{a h – a h v},
				h => q{a 'ga' h–h v},
			},
			yM => {
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E, M/d/y – E, M/d/y G},
				d => q{E, M/d/y – E, M/d/y G},
				y => q{E, M/d/y – E, M/d/y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, MMM d 'lia' – E, MMM d 'lia', y G},
				d => q{E, MMM d 'lia' – E, MMM d 'lia', y G},
				y => q{E, MMM d 'lia', y – E, MMM d 'lia', y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{MMM d 'lia' – MMM d 'lia', y G},
				d => q{MMM d 'lia' – d 'lia' , y G},
				y => q{MMM d 'lia' , y – MMM d 'lia', y G},
			},
			yMd => {
				M => q{M/d/y – M/d/y G},
				d => q{M/d/y – M/d/y G},
				y => q{M/d/y – M/d/y G},
			},
		},
		'gregorian' => {
			M => {
				M => q{'ɣleti' M 'lia' – 'ɣleti' M 'lia'},
			},
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, MMM d 'lia' – E, MMM d 'lia'},
				d => q{E, MMM d 'lia' – E, MMM d 'lia'},
			},
			MMMd => {
				M => q{MMM d 'lia' – MMM d 'lia'},
				d => q{MMM d 'lia' – d 'lia'},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			h => {
				a => q{a h – a h},
				h => q{a h–h},
			},
			hm => {
				a => q{a 'ga' h:mm – a 'ga' h:mm},
				h => q{a 'ga' h:mm - 'ga' h:mm},
				m => q{a 'ga' h:mm – 'ga' h:mm},
			},
			hmv => {
				a => q{a 'ga' h:mm – a 'ga' h:mm v},
				h => q{a 'ga' h:mm–h:mm v},
				m => q{a h:mm–h:mm v},
			},
			hv => {
				a => q{a h – a h v},
				h => q{a 'ga' h–h v},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, M/d/y – E, M/d/y},
				d => q{E, M/d/y – E, M/d/y},
				y => q{E, M/d/y – E, M/d/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, MMM d 'lia' – E, MMM d 'lia', y},
				d => q{E, MMM d 'lia' – E, MMM d 'lia', y},
				y => q{E, MMM d 'lia', y – E, MMM d 'lia', y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{MMM d 'lia' – MMM d 'lia', y},
				d => q{MMM d 'lia' – d 'lia' , y},
				y => q{MMM d 'lia' , y – MMM d 'lia', y},
			},
			yMd => {
				M => q{M/d/y – M/d/y},
				d => q{M/d/y – M/d/y},
				y => q{M/d/y – M/d/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		gmtFormat => q({0} GMT),
		regionFormat => q({0} gaƒoƒo me),
		regionFormat => q({0} kele gaƒoƒo me),
		regionFormat => q({0} nutome gaƒoƒo me),
		'Acre' => {
			long => {
				'daylight' => q#Eker dzomeŋɔli gaƒoƒome#,
				'generic' => q#Eker gaƒoƒome#,
				'standard' => q#Eker gaƒoƒoɖoanyime#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Afghanistan gaƒoƒo me#,
			},
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Central Africa gaƒoƒo me#,
			},
			short => {
				'standard' => q#CAT#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#East Africa gaƒoƒo me#,
			},
			short => {
				'standard' => q#EAT#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#South Africa nutome gaƒoƒo me#,
			},
			short => {
				'standard' => q#SAST#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#West Africa dzomeŋɔli gaƒoƒo me#,
				'generic' => q#West Africa gaƒoƒo me#,
				'standard' => q#West Africa nutome gaƒoƒo me#,
			},
			short => {
				'daylight' => q#WAST#,
				'generic' => q#WAT#,
				'standard' => q#WAT#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alaska kele gaƒoƒo me#,
				'generic' => q#Alaska gaƒoƒome#,
				'standard' => q#Alaska nutome gaƒoƒo me#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Almati dzomeŋɔli gaƒoƒome#,
				'generic' => q#Almati gaƒoƒome#,
				'standard' => q#Almati gaƒoƒoɖoanyime#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amazon dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Amazon gaƒoƒome#,
				'standard' => q#Amazon nutome gaƒoƒo me#,
			},
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Titina America kele gaƒoƒo me#,
				'generic' => q#Titina America gaƒoƒome#,
				'standard' => q#Titina America nutome gaƒoƒo me#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Eastern America kele gaƒoƒo me#,
				'generic' => q#Eastern America gaƒoƒo me#,
				'standard' => q#Eastern America nutome gaƒoƒo me#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Mountain kele gaƒoƒo me#,
				'generic' => q#Mountain gaƒoƒo me#,
				'standard' => q#Mountain nutome gaƒoƒo me#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Pacific kele gaƒoƒo me#,
				'generic' => q#Pacific gaƒoƒome#,
				'standard' => q#Pacific nutome gaƒoƒo me#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Anadir ŋkekeme gaƒoƒome#,
				'generic' => q#Anadir gaƒoƒome#,
				'standard' => q#Anadir gaƒoƒoɖoanyime#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Apia kele gaƒoƒo me#,
				'generic' => q#Apia gaƒoƒo me#,
				'standard' => q#Apia nutome gaƒoƒo me#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Aktau dzomeŋɔli gaƒoƒome#,
				'generic' => q#Aktau gaƒoƒome#,
				'standard' => q#Aktau gaƒoƒoɖoanyime#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Akttobe gaƒoƒome#,
				'generic' => q#Aktobe gaƒoƒome#,
				'standard' => q#Aktobe gaƒoƒoɖoanyime#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arabia dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Arabia gaƒoƒo me#,
				'standard' => q#Arabia nutome gaƒoƒo me#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentina dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Argentina gaƒoƒo me#,
				'standard' => q#Argentina nutome gaƒoƒo me#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Ɣetoɖoƒe Argentina dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Ɣetoɖoƒe Argentina gaƒoƒo me#,
				'standard' => q#Ɣetoɖoƒe Argentina nutome gaƒoƒo me#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armenia dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Armenia gaƒoƒo me#,
				'standard' => q#Armenia nutome gaƒoƒo me#,
			},
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Kathmandu nutomegaƒoƒome#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlantic kele gaƒoƒome#,
				'generic' => q#Atlantic gaƒoƒome#,
				'standard' => q#Atlantic nutome gaƒoƒome#,
			},
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Australian Central dzomeli gaƒoƒo me#,
				'generic' => q#Central Australia gaƒoƒo me#,
				'standard' => q#Australian Central nutome gaƒoƒo me#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Australian Central Western kele gaƒoƒo me#,
				'generic' => q#Australian Central Australia ɣetoɖofe gaƒoƒo me#,
				'standard' => q#Australian Central Western nutome gaƒoƒo me#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Australian Eastern kele gaƒoƒo me#,
				'generic' => q#Eastern Australia gaƒoƒo me#,
				'standard' => q#Australian Eastern nutome gaƒoƒo me#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Australian Western kele gaƒoƒo me#,
				'generic' => q#Western Australia gaƒoƒo me#,
				'standard' => q#Australian Western nutome gaƒoƒo me#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Azerbaijan dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Azerbaijan gaƒoƒo me#,
				'standard' => q#Azerbaijan nutome gaƒoƒo me#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azores dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Azores gaƒoƒo me#,
				'standard' => q#Azores nutome gaƒoƒo me#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladesh dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Bangladesh gaƒoƒo me#,
				'standard' => q#Bangladesh nutome gaƒoƒo me#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Bhutan gaƒoƒo me#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Bolivia gaƒoƒo me#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brasilia dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Brasilia gaƒoƒo me#,
				'standard' => q#Brasilia nutome gaƒoƒo me#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunei Darussalam gaƒoƒo me#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Cape Verde dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Cape Verde gaƒoƒo me#,
				'standard' => q#Cape Verde nutome gaƒoƒo me#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Chamorro gaƒoƒo me#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Chatham kele gaƒoƒo me#,
				'generic' => q#Chatham gaƒoƒo me#,
				'standard' => q#Chatham nutome gaƒoƒo me#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Chile dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Chile gaƒoƒo me#,
				'standard' => q#Chile nutome gaƒoƒo me#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#China kele gaƒoƒo me#,
				'generic' => q#China gaƒoƒo me#,
				'standard' => q#China nutome gaƒoƒo me#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Choibalsan dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Choibalsan gaƒoƒo me#,
				'standard' => q#Choibalsan nutome gaƒoƒo me#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Christmas Island gaƒoƒo me#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Cocos Islands gaƒoƒo me#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Colombia dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Colombia gaƒoƒo me#,
				'standard' => q#Colombia nutome gaƒoƒo me#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Cook Islands dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Cook Islands gaƒoƒo me#,
				'standard' => q#Cook Islands nutome gaƒoƒo me#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Cuba kele gaƒoƒome#,
				'generic' => q#Cuba gaƒoƒome#,
				'standard' => q#Cuba nutome gaƒoƒome#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Davis gaƒoƒo me#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dumont-d’Urville gaƒoƒo me#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#East Timor gaƒoƒo me#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Easter Island dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Easter Island gaƒoƒo me#,
				'standard' => q#Easter Island nutome gaƒoƒo me#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ecuador gaƒoƒo me#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Xexeme gaƒoƒoɖoanyi me#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Du manya#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Ireland nutome gaƒoƒo me#,
			},
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#British dzomeŋɔli gaƒoƒo me#,
			},
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Central Europe dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Central Europe gaƒoƒo me#,
				'standard' => q#Central Europe nutome gaƒoƒo me#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Ɣedzeƒe Europe ŋkekeme gaƒoƒome#,
				'generic' => q#Ɣedzeƒe Europe gaƒoƒome#,
				'standard' => q#Ɣedzeƒe Europe gaƒoƒoɖoanyime#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Western Europe dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Western Europe gaƒoƒo me#,
				'standard' => q#Western Europe nutome gaƒoƒo me#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Falkland Islands dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Falkland Islands gaƒoƒo me#,
				'standard' => q#Falkland Islands nutome gaƒoƒo me#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fiji dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Fiji gaƒoƒo me#,
				'standard' => q#Fiji nutome gaƒoƒo me#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#French Guiana gaƒoƒo me#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#French Southern & Antarctic gaƒoƒo me#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwich gaƒoƒo me#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagos gaƒoƒo me#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambier gaƒoƒo me#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Georgia dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Georgia gaƒoƒo me#,
				'standard' => q#Georgia nutome gaƒoƒo me#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gilbert Islands gaƒoƒo me#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#East Greenland dzomeŋɔli gaƒoƒo me#,
				'generic' => q#East Greenland gaƒoƒome#,
				'standard' => q#East Greenland nutome gaƒoƒo me#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#West Greenland kele gaƒoƒo me#,
				'generic' => q#West Greenland gaƒoƒo me#,
				'standard' => q#West Greenland nutome gaƒoƒo me#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Gulf nutome gaƒoƒo me#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Guyana gaƒoƒo me#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawaii-Aleutia kele gaƒoƒo me#,
				'generic' => q#Hawaii-Aleutia gaƒoƒo me#,
				'standard' => q#Hawaii-Aleutia nutome gaƒoƒo me#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hong Kong dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Hong Kong gaƒoƒo me#,
				'standard' => q#Hong Kong nutome gaƒoƒo me#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hovd dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Hovd gaƒoƒo me#,
				'standard' => q#Hovd nutome gaƒoƒo me#,
			},
		},
		'India' => {
			long => {
				'standard' => q#India gaƒoƒo me#,
			},
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Indian Ocean gaƒoƒo me#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Indonesia gaƒoƒo me#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Central Indonesia gaƒoƒo me#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Eastern Indonesia gaƒoƒo me#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Western Indonesia gaƒoƒo me#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Iran kele gaƒoƒo me#,
				'generic' => q#Iran gaƒoƒo me#,
				'standard' => q#Iran nutome gaƒoƒo me#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkutsk dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Irkutsk gaƒoƒo me#,
				'standard' => q#Irkutsk nutome gaƒoƒo me#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Israel kele gaƒoƒo me#,
				'generic' => q#Israel gaƒoƒo me#,
				'standard' => q#Israel nutome gaƒoƒo me#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japan dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Japan gaƒoƒo me#,
				'standard' => q#Japan nutome gaƒoƒo me#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Petropavlovsk-Kamtsatski ŋkekeme gaƒoƒome#,
				'generic' => q#Petropavlovsk-Kamtsatski gaƒoƒome#,
				'standard' => q#Petropavlovsk-Kamtsatski gaƒoƒoɖoanyime#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#East Kazakhstan gaƒoƒo me#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#West Kazakhstan gaƒoƒo me#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Korea dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Korea gaƒoƒo me#,
				'standard' => q#Korea nutome gaƒoƒo me#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosrae gaƒoƒo me#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnoyarsk dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Krasnoyarsk gaƒoƒo me#,
				'standard' => q#Krasnoyarsk nutome gaƒoƒo me#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kyrgystan gaƒoƒo me#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Line Islands gaƒoƒo me#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord Howe kele gaƒoƒo me#,
				'generic' => q#Lord Howe gaƒoƒo me#,
				'standard' => q#Lord Howe nutome gaƒoƒo me#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Makau ŋkekeme gaƒoƒome#,
				'generic' => q#Makau gaƒoƒome#,
				'standard' => q#Makau gaƒoƒoɖoanyime#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Macquarie Island gaƒoƒo me#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadan dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Magadan gaƒoƒo me#,
				'standard' => q#Magadan nutome gaƒoƒo me#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malaysia gaƒoƒo me#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Maldives gaƒoƒo me#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Marquesas gaƒoƒo me#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Marshall Islands gaƒoƒo me#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mauritius dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Mauritius gaƒoƒo me#,
				'standard' => q#Mauritius nutome gaƒoƒo me#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mawson gaƒoƒo me#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Northwest Mexico kele gaƒoƒo me#,
				'generic' => q#Northwest Mexico gaƒoƒo me#,
				'standard' => q#Northwest Mexico nutome gaƒoƒo me#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Mexican Pacific kele gaƒoƒome#,
				'generic' => q#Mexican Pacific gaƒoƒo me#,
				'standard' => q#Mexican Pacific nutome gaƒoƒo me#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulan Bator dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Ulan Bator gaƒoƒo me#,
				'standard' => q#Ulan Bator nutome gaƒoƒo me#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moscow dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Moscow gaƒoƒo me#,
				'standard' => q#Moscow nutome gaƒoƒo me#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Myanmar gaƒoƒo me#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauru gaƒoƒo me#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepal gaƒoƒo me#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#New Caledonia dzomeŋɔli gaƒoƒo me#,
				'generic' => q#New Caledonia gaƒoƒo me#,
				'standard' => q#New Caledonia nutome gaƒoƒo me#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#New Zealand kele gaƒoƒo me#,
				'generic' => q#New Zealand gaƒoƒo me#,
				'standard' => q#New Zealand nutome gaƒoƒo me#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Newfoundland kele gaƒoƒome#,
				'generic' => q#Newfoundland gaƒoƒome#,
				'standard' => q#Newfoundland nutome gaƒoƒome#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niue gaƒoƒo me#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Norfolk Island dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Norfolk Island gaƒoƒo me#,
				'standard' => q#Norfolk Island nutome gaƒoƒo me#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de Noronha dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Fernando de Noronha gaƒoƒo me#,
				'standard' => q#Fernando de Noronha nutome gaƒoƒo me#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibirsk dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Novosibirsk gaƒoƒo me#,
				'standard' => q#Novosibirsk nutome gaƒoƒo me#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omsk dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Omsk gaƒoƒo me#,
				'standard' => q#Omsk nutome gaƒoƒo me#,
			},
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistan dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Pakistan gaƒoƒo me#,
				'standard' => q#Pakistan nutome gaƒoƒo me#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palau gaƒoƒo me#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papua New Guinea gaƒoƒo me#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paraguay dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Paraguay gaƒoƒo me#,
				'standard' => q#Paraguay nutome gaƒoƒo me#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peru dzomeŋɔli gaƒoƒome#,
				'generic' => q#Peru gaƒoƒo me#,
				'standard' => q#Peru nutome gaƒoƒo me#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Philippine dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Philippine gaƒoƒo me#,
				'standard' => q#Philippine nutome gaƒoƒo me#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Phoenix Islands gaƒoƒo me#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#St. Pierre & Miquelon kele gaƒoƒome#,
				'generic' => q#St. Pierre & Miquelon gaƒoƒome#,
				'standard' => q#St. Pierre & Miquelon nutome gaƒoƒome#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitcairn gaƒoƒo me#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponape gaƒoƒo me#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pyongyang gaƒoƒo me#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Kizilɔrda dzomeŋɔli gaƒoƒome#,
				'generic' => q#Kizilɔrda gaƒoƒome#,
				'standard' => q#Kizilɔrda gaƒoƒoɖoanyime#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Reunion gaƒoƒo me#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rothera gaƒoƒo me#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sakhalin dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Sakhalin gaƒoƒo me#,
				'standard' => q#Sakhalin nutome gaƒoƒo me#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Samara ŋkekeme gaƒoƒome#,
				'generic' => q#Samara gaƒoƒome#,
				'standard' => q#Samara gaƒoƒoɖoanyime#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoa kele gaƒoƒo me#,
				'generic' => q#Samoa gaƒoƒo me#,
				'standard' => q#Samoa nutome gaƒoƒo me#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seychelles gaƒoƒo me#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapore nutome gaƒoƒo me#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Solomon Islands gaƒoƒo me#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#South Georgia gaƒoƒo me#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Suriname gaƒoƒome#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syowa gaƒoƒo me#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahiti gaƒoƒo me#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taipei kele gaƒoƒo me#,
				'generic' => q#Taipei gaƒoƒo me#,
				'standard' => q#Taipei nutome gaƒoƒo me#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tajikistan gaƒoƒo me#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelau gaƒoƒo me#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tonga dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Tonga gaƒoƒo me#,
				'standard' => q#Tonga nutome gaƒoƒo me#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuuk gaƒoƒo me#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmenistan dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Turkmenistan gaƒoƒo me#,
				'standard' => q#Turkmenistan nutome gaƒoƒo me#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvalu gaƒoƒo me#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Uruguay dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Uruguay gaƒoƒo me#,
				'standard' => q#Uruguay nutome gaƒoƒo me#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Uzbekistan dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Uzbekistan gaƒoƒo me#,
				'standard' => q#Uzbekistan nutome gaƒoƒo me#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatu dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Vanuatu gaƒoƒo me#,
				'standard' => q#Vanuatu nutome gaƒoƒo me#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venezuela gaƒoƒo me#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Vladivostok dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Vladivostok gaƒoƒo me#,
				'standard' => q#Vladivostok nutome gaƒoƒo me#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Vogograd dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Volgograd gaƒoƒo me#,
				'standard' => q#Volgograd nutome gaƒoƒo me#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Vostok gaƒoƒo me#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Wake Island gaƒoƒo me#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wallis & Futuna gaƒoƒo me#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Yakutsk dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Yakutsk gaƒoƒo me#,
				'standard' => q#Yakutsk nutome gaƒoƒo me#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Yekaterinburg dzomeŋɔli gaƒoƒo me#,
				'generic' => q#Yekaterinburg gaƒoƒo me#,
				'standard' => q#Yekaterinburg nutome gaƒoƒo me#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
