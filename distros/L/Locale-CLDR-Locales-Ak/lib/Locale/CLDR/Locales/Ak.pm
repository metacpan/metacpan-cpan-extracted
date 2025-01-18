=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ak - Package for language Akan

=cut

package Locale::CLDR::Locales::Ak;
# This file auto generated from Data\common\main\ak.xml
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

extends('Locale::CLDR::Locales::Root');
has 'valid_algorithmic_formats' => (
    is => 'ro',
    isa => ArrayRef,
    init_arg => undef,
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal','spellout-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'spellout-cardinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(kaw →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(hwee),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pɔw →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(koro),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(abien),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(abiasa),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(anan),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(anum),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(asia),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(asuon),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(awɔtwe),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(akron),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(du[-→%%spellout-cardinal-tens→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(aduonu[-→%%spellout-cardinal-tens→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(aduasa[-→%%spellout-cardinal-tens→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(adu←←[-→%%spellout-cardinal-tens→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(­ɔha[-na-­→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(aha-←←[-na-→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(apem[-na-→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(mpem-←←[-na-→→]),
				},
				'100000' => {
					base_value => q(100000),
					divisor => q(100000),
					rule => q(mpem-ɔha[-na-→→]),
				},
				'200000' => {
					base_value => q(200000),
					divisor => q(100000),
					rule => q(mpem-aha-←←[-na-→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(ɔpepepem-←←[-na-→→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(mpepepem-←←[-na-→→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(ɔpepepepem-←←[-na-→→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(mpepepepem-←←[-na-→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(ɔpepepepepem-←←[-na-→→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(mpepepepepem-←←[-na-→→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(ɔpepepepepepem-←←[-na-→→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(mpepepepepepem-←←[-na-→→]),
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
		'spellout-cardinal-tens' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(biako),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
				'max' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
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
				'-x' => {
					divisor => q(1),
					rule => q(kaw →→),
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
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(←← →→→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←← →→→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←← →→→),
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
		'spellout-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(kaw →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(a-ɛ-tɔ-so-hwee),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(a-ɛ-di-kane),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(a-ɛ-tɔ-so-=%spellout-cardinal=),
				},
				'max' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(a-ɛ-tɔ-so-=%spellout-cardinal=),
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
				'af' => 'Afrikaans',
 				'ak' => 'Akan',
 				'am' => 'Amarik',
 				'ar' => 'Arabeke',
 				'ar_001' => 'Arabeke Kasa Nhyehyɛeɛ Foforɔ',
 				'as' => 'Asamese',
 				'ast' => 'Asturiani',
 				'az' => 'Asabegyanni',
 				'be' => 'Belarus kasa',
 				'bg' => 'Bɔlgeria kasa',
 				'bgc' => 'Harianvi',
 				'bho' => 'Bopuri',
 				'blo' => 'Anii',
 				'bn' => 'Bengali kasa',
 				'br' => 'Britenni',
 				'brx' => 'Bodo',
 				'bs' => 'Bosniani',
 				'ca' => 'Katalan',
 				'ceb' => 'Kebuano',
 				'chr' => 'Kiroki',
 				'cs' => 'Kyɛk kasa',
 				'csw' => 'Tadeɛm Kreefoɔ Kasa',
 				'cv' => 'Kyuvahyi',
 				'cy' => 'Wɛɛhye Kasa',
 				'da' => 'Dane kasa',
 				'de' => 'Gyaaman',
 				'de_AT' => 'Ɔstria Gyaaman',
 				'de_CH' => 'Swisalande Gyaaman',
 				'doi' => 'Dɔgri',
 				'dsb' => 'Sɔɔbia a ɛwɔ fam',
 				'el' => 'Greek kasa',
 				'en' => 'Borɔfo',
 				'en_GB' => 'Ngresi Borɔfo',
 				'en_US' => 'Amɛrika Borɔfo',
 				'eo' => 'Esperanto',
 				'es' => 'Spain kasa',
 				'es_419' => 'Spain kasa (Laaten Amɛrika)',
 				'et' => 'Estonia kasa',
 				'eu' => 'Baske',
 				'fa' => 'Pɛɛhyia kasa',
 				'ff' => 'Fula kasa',
 				'fi' => 'Finlande kasa',
 				'fil' => 'Filipin kasa',
 				'fo' => 'Farosi',
 				'fr' => 'Frɛnkye',
 				'fr_CA' => 'Kanada Frɛnkye',
 				'fr_CH' => 'Swisalande Frɛnkye',
 				'fy' => 'Atɔeɛ Fam Frihyia Kasa',
 				'ga' => 'Aerelande kasa',
 				'gd' => 'Skotlandfoɔ Galek Kasa',
 				'gl' => 'Galisia kasa',
 				'gu' => 'Gugyarata',
 				'ha' => 'Hausa',
 				'he' => 'Hibri kasa',
 				'hi' => 'Hindi',
 				'hi_Latn' => 'Laatenfoɔ Hindi',
 				'hi_Latn@alt=variant' => 'Hindibrɔfo',
 				'hr' => 'Kurowehyia kasa',
 				'hsb' => 'Atifi fam Sɔɔbia Kasa',
 				'hu' => 'Hangri kasa',
 				'hy' => 'Aameniani',
 				'ia' => 'Kasa ntam',
 				'id' => 'Indonihyia kasa',
 				'ie' => 'Kasa afrafra',
 				'ig' => 'Igbo kasa',
 				'is' => 'Aeslande kasa',
 				'it' => 'Italy kasa',
 				'ja' => 'Gyapan kasa',
 				'jv' => 'Gyabanis kasa',
 				'ka' => 'Gyɔɔgyia kasa',
 				'kea' => 'Kabuvadianu',
 				'kgp' => 'Kaingang',
 				'kk' => 'kasaki kasa',
 				'km' => 'Kambodia kasa',
 				'kn' => 'Kanada',
 				'ko' => 'Korea kasa',
 				'kok' => 'Konkani kasa',
 				'ks' => 'Kahyimiɛ',
 				'ku' => 'Kɛɛde kasa',
 				'kxv' => 'Kuvi kasa',
 				'ky' => 'Kɛgyese kasa',
 				'lb' => 'Lɔsimbɔge kasa',
 				'lij' => 'Liguria kasa',
 				'lmo' => 'Lombad kasa',
 				'lo' => 'Lawo kasa',
 				'lt' => 'Lituania kasa',
 				'lv' => 'Latvia kasa',
 				'mai' => 'Maetili',
 				'mi' => 'Mawori',
 				'mk' => 'Mɛsidonia kasa',
 				'ml' => 'Malayalam kasa',
 				'mn' => 'Mongoliafoɔ kasa',
 				'mni' => 'Manipuri',
 				'mr' => 'Marati',
 				'ms' => 'Malay kasa',
 				'mt' => 'Malta kasa',
 				'mul' => 'Kasa ahodoɔ',
 				'my' => 'Bɛɛmis kasa',
 				'nds' => 'Gyaaman kasa a ɛwɔ fam',
 				'ne' => 'Nɛpal kasa',
 				'nl' => 'Dɛɛkye',
 				'nl_BE' => 'Dɛɛkye (Bɛɛgyiɔm',
 				'nn' => 'Nɔwefoɔ Ninɔso',
 				'no' => 'Nɔwefoɔ kasa',
 				'nqo' => 'Nko',
 				'oc' => 'Osita kasa',
 				'or' => 'Odia',
 				'pa' => 'Pungyabi kasa',
 				'pcm' => 'Nigeriafoɔ Pigyin',
 				'pl' => 'Pɔland kasa',
 				'prg' => 'Prusia kasa',
 				'ps' => 'Pahyito',
 				'pt' => 'Pɔɔtugal kasa',
 				'qu' => 'Kwɛkya',
 				'raj' => 'Ragyasitan kasa',
 				'rm' => 'Romanhye kasa',
 				'ro' => 'Romenia kasa',
 				'ru' => 'Rahyia kasa',
 				'rw' => 'Rewanda kasa',
 				'sa' => 'Sanskrit kasa',
 				'sah' => 'Yakut Kasa',
 				'sat' => 'Santal kasa',
 				'sc' => 'Saadinia kasa',
 				'sd' => 'Sindi',
 				'si' => 'Sinhala',
 				'sk' => 'Slovak Kasa',
 				'sl' => 'Slovɛniafoɔ Kasa',
 				'so' => 'Somalia kasa',
 				'sq' => 'Aabeniani',
 				'sr' => 'Sɛbia Kasa',
 				'su' => 'Sunda Kasa',
 				'sv' => 'Sweden kasa',
 				'sw' => 'Swahili',
 				'syr' => 'Siiria Kasa',
 				'szl' => 'Silesiafoɔ Kasa',
 				'ta' => 'Tamil kasa',
 				'te' => 'Telugu',
 				'tg' => 'Tɛgyeke kasa',
 				'th' => 'Taeland kasa',
 				'ti' => 'Tigrinya kasa',
 				'tk' => 'Tɛkmɛnistan Kasa',
 				'to' => 'Tonga kasa',
 				'tr' => 'Tɛɛki kasa',
 				'tt' => 'Tata kasa',
 				'ug' => 'Yugaa Kasa',
 				'uk' => 'Ukren kasa',
 				'und' => 'kasa a yɛnnim',
 				'ur' => 'Urdu kasa',
 				'uz' => 'Usbɛkistan Kasa',
 				'vec' => 'Vɛnihyia Kasa',
 				'vi' => 'Viɛtnam kasa',
 				'vmw' => 'Makuwa',
 				'wo' => 'Wolɔfo Kasa',
 				'xh' => 'Hosa Kasa',
 				'xnr' => 'Kangri',
 				'yo' => 'Yoruba',
 				'yrl' => 'Ningatu',
 				'yue' => 'Kantonese',
 				'yue@alt=menu' => 'Kyaena Kantonese',
 				'za' => 'Zuang',
 				'zh' => 'Kyaena kasa',
 				'zh@alt=menu' => 'Madarin, Kyaena kasa',
 				'zh_Hans' => 'Kyaena kasa a emu yɛ mmrɛ',
 				'zh_Hans@alt=long' => 'Mandarin Kyaena kasa a emu yɛ mmrɛ',
 				'zh_Hant' => 'Tete Kyaena kasa',
 				'zh_Hant@alt=long' => 'Tete Mandarin Kyaena kasa',
 				'zu' => 'Zulu',
 				'zxx' => 'Lengwestese biara nnim',

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
			'Adlm' => 'Adlam kasa',
 			'Arab' => 'Arabeke',
 			'Aran' => 'Nastaliki kasa',
 			'Armn' => 'Amenia kasa',
 			'Beng' => 'Bangala kasa',
 			'Bopo' => 'Bopomofo kasa',
 			'Brai' => 'Anifrafoɔ kasa',
 			'Cakm' => 'Kyakma kasa',
 			'Cans' => 'Kanadafoɔ Kann Kasa a Wɔakeka Abom',
 			'Cher' => 'Kɛroki',
 			'Cyrl' => 'Kreleke',
 			'Deva' => 'Dɛvanagari kasa',
 			'Ethi' => 'Yitiopia kasa',
 			'Geor' => 'Dwɔɔgyia kasa',
 			'Grek' => 'Griiki kasa',
 			'Gujr' => 'Gudwurati kasa',
 			'Guru' => 'Gurumuki kasa',
 			'Hanb' => 'Hanse a Bopomofo kasa ka ho',
 			'Hang' => 'Hangul kasa',
 			'Hani' => 'Han',
 			'Hans' => 'Kyaena Kasa Hanse',
 			'Hant' => 'Tete',
 			'Hant@alt=stand-alone' => 'Tete Kyaena Kasa Hanse',
 			'Hebr' => 'Hibri kasa',
 			'Hira' => 'Hiragana kasa',
 			'Hrkt' => 'Gyapanfoɔ selabolo kasa',
 			'Jamo' => 'Gyamo kasa',
 			'Jpan' => 'Gyapanfoɔ kasa',
 			'Kana' => 'Katakana kasa',
 			'Khmr' => 'Kɛma kasa',
 			'Knda' => 'Kanada kasa',
 			'Kore' => 'Korea kasa',
 			'Laoo' => 'Lawo kasa',
 			'Latn' => 'Laatin',
 			'Mlym' => 'Malayalam kasa',
 			'Mong' => 'Mongoliafoɔ kasa',
 			'Mtei' => 'Meeti Mayɛke kasa',
 			'Mymr' => 'Mayama kasa',
 			'Nkoo' => 'Nko kasa',
 			'Olck' => 'Ol Kyiki kasa',
 			'Orya' => 'Odia kasa',
 			'Rohg' => 'Hanifi kasa',
 			'Sinh' => 'Sinhala kasa',
 			'Sund' => 'Sudanni kasa',
 			'Syrc' => 'Siiria Tete kasa',
 			'Taml' => 'Tamil kasa',
 			'Telu' => 'Telugu kasa',
 			'Tfng' => 'Tifinafo kasa',
 			'Thaa' => 'Taana kasa',
 			'Thai' => 'Taelanfoɔ kasa',
 			'Tibt' => 'Tibɛtanfoɔ kasa',
 			'Vaii' => 'Vai kasa',
 			'Yiii' => 'Yifoɔ kasa',
 			'Zmth' => 'Nkontabudeɛ',
 			'Zsye' => 'Yimogyi',
 			'Zsym' => 'Ahyɛnsodeɛ',
 			'Zxxx' => 'Deɛ wɔntwerɛeɛ',
 			'Zyyy' => 'obiara nim',
 			'Zzzz' => 'Deɛ yɛnnim',

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
			'001' => 'wiase',
 			'002' => 'Abibirem',
 			'003' => 'Amɛrika Atifi',
 			'005' => 'Amɛrika Anaafoɔ',
 			'009' => 'Osiana',
 			'011' => 'Abibirem Atɔeɛ Fam',
 			'013' => 'Amɛrika Mfimfini',
 			'014' => 'Abibirem Apueiɛ Fam',
 			'015' => 'Abibirem Atifi Fam',
 			'017' => 'Abibirem Mfimfini',
 			'018' => 'Abibirem Anaafoɔ Fam',
 			'019' => 'Amɛrikafoɔ',
 			'021' => 'Amɛrika Atifi Fam',
 			'029' => 'Karibia',
 			'030' => 'Asia Apueiɛ',
 			'034' => 'Asia Anaafoɔ',
 			'035' => 'Asia Anaafoɔ Apuieɛ',
 			'039' => 'Yuropu Anaafoɔ',
 			'053' => 'Ɔstrelia ne Asia',
 			'054' => 'Melanesia',
 			'057' => 'Micronesia Mantam',
 			'061' => 'Pɔlenesia',
 			'142' => 'Asia',
 			'143' => 'Asia Mfimfini',
 			'145' => 'Asia Atɔeɛ',
 			'150' => 'Yuropu',
 			'151' => 'Yuropu Apuieɛ',
 			'154' => 'Yuropu Atifi',
 			'155' => 'Yuropu Atɔeɛ',
 			'202' => 'Abibirem Mpaprɛ Anaafoɔ',
 			'419' => 'Laaten Amɛrika',
 			'AC' => 'Asɛnhyin',
 			'AD' => 'Andora',
 			'AE' => 'United Arab Emirates',
 			'AF' => 'Afganistan',
 			'AG' => 'Antigua ne Baabuda',
 			'AI' => 'Anguila',
 			'AL' => 'Albenia',
 			'AM' => 'Aamenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antaatika',
 			'AR' => 'Agyɛntina',
 			'AS' => 'Amɛrika Samoa',
 			'AT' => 'Ɔstria',
 			'AU' => 'Ɔstrelia',
 			'AW' => 'Aruba',
 			'AX' => 'Aland Aeland',
 			'AZ' => 'Asabegyan',
 			'BA' => 'Bosnia ne Hɛzegovina',
 			'BB' => 'Baabados',
 			'BD' => 'Bangladɛhye',
 			'BE' => 'Bɛlgyium',
 			'BF' => 'Bɔkina Faso',
 			'BG' => 'Bɔlgeria',
 			'BH' => 'Baren',
 			'BI' => 'Burundi',
 			'BJ' => 'Bɛnin',
 			'BL' => 'St. Baatilemi',
 			'BM' => 'Bɛmuda',
 			'BN' => 'Brunae',
 			'BO' => 'Bolivia',
 			'BQ' => 'Caribbean Netherlands',
 			'BR' => 'Brazil',
 			'BS' => 'Bahama',
 			'BT' => 'Butan',
 			'BV' => 'Bouvet Island',
 			'BW' => 'Bɔtswana',
 			'BY' => 'Bɛlarus',
 			'BZ' => 'Beliz',
 			'CA' => 'Kanada',
 			'CC' => 'Kokoso Supɔ',
 			'CD' => 'Kongo Kinhyaahya',
 			'CD@alt=variant' => 'DR Kongo',
 			'CF' => 'Afrika Finimfin Man',
 			'CG' => 'Kongo',
 			'CG@alt=variant' => 'Kongo Man',
 			'CH' => 'Swetzaland',
 			'CI' => 'Kodivuwa',
 			'CK' => 'Kuk Nsupɔ',
 			'CL' => 'Kyili',
 			'CM' => 'Kamɛrun',
 			'CN' => 'Kyaena',
 			'CO' => 'Kolombia',
 			'CP' => 'Klepatin Aeland',
 			'CR' => 'Kɔsta Rika',
 			'CU' => 'Kuba',
 			'CV' => 'Kepvɛdfo Islands',
 			'CW' => 'Kurakaw',
 			'CX' => 'Buronya Supɔ',
 			'CY' => 'Saeprɔso',
 			'CZ' => 'Kyɛk',
 			'CZ@alt=variant' => 'Kyɛk Man',
 			'DE' => 'Gyaaman',
 			'DG' => 'Diɛgo Gaasia',
 			'DJ' => 'Gyibuti',
 			'DK' => 'Dɛnmak',
 			'DM' => 'Dɔmeneka',
 			'DO' => 'Dɔmeneka Man',
 			'DZ' => 'Ɔlgyeria',
 			'EA' => 'Ceuta ne Melilla',
 			'EC' => 'Yikuwedɔ',
 			'EE' => 'Ɛstonia',
 			'EG' => 'Misrim',
 			'EH' => 'Sahara Atɔeɛ',
 			'ER' => 'Ɛritrea',
 			'ES' => 'Spain',
 			'ET' => 'Ithiopia',
 			'EU' => 'Yuropu Nkabomkuo',
 			'EZ' => 'Yuropu Fam',
 			'FI' => 'Finland',
 			'FJ' => 'Figyi',
 			'FK' => 'Fɔkman Aeland',
 			'FK@alt=variant' => 'Fɔkman Aeland (Islas Maivinas)',
 			'FM' => 'Maekronehyia',
 			'FO' => 'Faro Aeland',
 			'FR' => 'Franse',
 			'GA' => 'Gabɔn',
 			'GB' => 'UK',
 			'GD' => 'Grenada',
 			'GE' => 'Gyɔgyea',
 			'GF' => 'Frɛnkye Gayana',
 			'GG' => 'Guɛnse',
 			'GH' => 'Gaana',
 			'GI' => 'Gyebralta',
 			'GL' => 'Greenman',
 			'GM' => 'Gambia',
 			'GN' => 'Gini',
 			'GP' => 'Guwadelup',
 			'GQ' => 'Gini Ikuweta',
 			'GR' => 'Greekman',
 			'GS' => 'Gyɔɔgyia Anaafoɔ ne Sandwich Aeland Anaafoɔ',
 			'GT' => 'Guwatemala',
 			'GU' => 'Guam',
 			'GW' => 'Gini Bisaw',
 			'GY' => 'Gayana',
 			'HK' => 'Hɔnkɔn Kyaena',
 			'HK@alt=short' => 'Hɔnkɔn',
 			'HM' => 'Heard ne McDonald Supɔ',
 			'HN' => 'Hɔnduras',
 			'HR' => 'Krowehyia',
 			'HT' => 'Heiti',
 			'HU' => 'Hangari',
 			'IC' => 'Canary Islands',
 			'ID' => 'Indɔnehyia',
 			'IE' => 'Aereland',
 			'IL' => 'Israe',
 			'IM' => 'Isle of Man',
 			'IN' => 'India',
 			'IO' => 'Britenfo Man Wɔ India Po No Mu',
 			'IO@alt=chagos' => 'Kyagɔso Akyipalego',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Aesland',
 			'IT' => 'Itali',
 			'JE' => 'Gyɛsi',
 			'JM' => 'Gyameka',
 			'JO' => 'Gyɔdan',
 			'JP' => 'Gyapan',
 			'KE' => 'Kenya',
 			'KG' => 'Kɛɛgestan',
 			'KH' => 'Kambodia',
 			'KI' => 'Kiribati',
 			'KM' => 'Kɔmɔrɔs',
 			'KN' => 'Saint Kitts ne Nɛves',
 			'KP' => 'Korea Atifi',
 			'KR' => 'Korea Anaafoɔ',
 			'KW' => 'Kuweti',
 			'KY' => 'Kemanfo Islands',
 			'KZ' => 'Kazakstan',
 			'LA' => 'Laos',
 			'LB' => 'Lɛbanɔn',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Lektenstaen',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Laeberia',
 			'LS' => 'Lesoto',
 			'LT' => 'Lituwenia',
 			'LU' => 'Lusimbɛg',
 			'LV' => 'Latvia',
 			'LY' => 'Libya',
 			'MA' => 'Moroko',
 			'MC' => 'Monako',
 			'MD' => 'Mɔldova',
 			'ME' => 'Mɔntenegro',
 			'MF' => 'St. Maatin',
 			'MG' => 'Madagaska',
 			'MH' => 'Mahyaa Aeland',
 			'MK' => 'Mesidonia Atifi',
 			'ML' => 'Mali',
 			'MM' => 'Mayaama (Bɛɛma)',
 			'MN' => 'Mɔngolia',
 			'MO' => 'Makaw Kyaena',
 			'MO@alt=short' => 'Makaw',
 			'MP' => 'Mariana Atifi Fam Aeland',
 			'MQ' => 'Matinik',
 			'MR' => 'Mɔretenia',
 			'MS' => 'Mantserat',
 			'MT' => 'Mɔlta',
 			'MU' => 'Mɔrehyeɔs',
 			'MV' => 'Maldives',
 			'MW' => 'Malawi',
 			'MX' => 'Mɛksiko',
 			'MY' => 'Malehyia',
 			'MZ' => 'Mozambik',
 			'NA' => 'Namibia',
 			'NC' => 'Kaledonia Foforo',
 			'NE' => 'Nigyɛɛ',
 			'NF' => 'Norfold Supɔ',
 			'NG' => 'Naegyeria',
 			'NI' => 'Nekaraguwa',
 			'NL' => 'Nɛdɛland',
 			'NO' => 'Nɔɔwe',
 			'NP' => 'Nɛpal',
 			'NR' => 'Naworu',
 			'NU' => 'Niyu',
 			'NZ' => 'Ziland Foforo',
 			'NZ@alt=variant' => 'Ziland Foforɔ a ɛwɔ Awotiarua',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Frɛnkye Pɔlenehyia',
 			'PG' => 'Papua Gini Foforɔ',
 			'PH' => 'Filipin',
 			'PK' => 'Pakistan',
 			'PL' => 'Pɔland',
 			'PM' => 'Saint Pierre ne Miquelon',
 			'PN' => 'Pitkaan Nsupɔ',
 			'PR' => 'Puɛto Riko',
 			'PS' => 'Palestaen West Bank ne Gaza',
 			'PT' => 'Pɔtugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguae',
 			'QA' => 'Kata',
 			'QO' => 'Osiana Ano Ano',
 			'RE' => 'Reyuniɔn',
 			'RO' => 'Romenia',
 			'RS' => 'Sɛbia',
 			'RU' => 'Rɔhyea',
 			'RW' => 'Rewanda',
 			'SA' => 'Saudi Arabia',
 			'SB' => 'Solomɔn Aeland',
 			'SC' => 'Seyhyɛl',
 			'SD' => 'Sudan',
 			'SE' => 'Sweden',
 			'SG' => 'Singapɔ',
 			'SH' => 'Saint Helena',
 			'SI' => 'Slovinia',
 			'SJ' => 'Svalbard ne Jan Mayen',
 			'SK' => 'Slovakia',
 			'SL' => 'Sɛra Liɔn',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Suriname',
 			'SS' => 'Sudan Anaafoɔ',
 			'ST' => 'São Tomé ne Príncipe',
 			'SV' => 'Ɛl Salvadɔ',
 			'SX' => 'Sint Maaten',
 			'SY' => 'Siria',
 			'SZ' => 'Swaziland',
 			'TA' => 'Tristan da Kuna',
 			'TC' => 'Turks ne Caicos Islands',
 			'TD' => 'Kyad',
 			'TF' => 'Franse Anaafoɔ Nsaase',
 			'TG' => 'Togo',
 			'TH' => 'Taeland',
 			'TJ' => 'Tagyikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timɔ Boka',
 			'TL@alt=variant' => 'Timɔ Apueiɛ',
 			'TM' => 'Tɛkmɛnistan',
 			'TN' => 'Tunihyia',
 			'TO' => 'Tonga',
 			'TR' => 'Tɛɛki',
 			'TT' => 'Trinidad ne Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tansania',
 			'UA' => 'Ukren',
 			'UG' => 'Yuganda',
 			'UM' => 'U.S. Nkyɛnnkyɛn Supɔ Ahodoɔ',
 			'UN' => 'Amansan Nkabomkuo',
 			'US' => 'Amɛrika',
 			'UY' => 'Yurugwae',
 			'UZ' => 'Usbɛkistan',
 			'VA' => 'Vatican Man',
 			'VC' => 'Saint Vincent ne Grenadines',
 			'VE' => 'Venezuela',
 			'VG' => 'Ngresifoɔ Virgin Island',
 			'VI' => 'Amɛrika Virgin Islands',
 			'VN' => 'Viɛtnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis ne Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Anto Kasa',
 			'XB' => 'Anto Bidi',
 			'XK' => 'Kosovo',
 			'YE' => 'Yɛmɛn',
 			'YT' => 'Mayɔte',
 			'ZA' => 'Abibirem Anaafoɔ',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabue',
 			'ZZ' => 'Mantam a Yɛnnim',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Kalɛnna',
 			'cf' => 'Sika Fɔmate',
 			'collation' => 'Nyiyie Kwan',
 			'currency' => 'Sika',
 			'hc' => 'Dɔnhwere Nkɔmmaeɛ (12 anaa 24)',
 			'lb' => 'Line Break Nhyehyɛeɛ',
 			'ms' => 'Nsusudeɛ Sestɛm',
 			'numbers' => 'Nɛma',

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
 				'buddhist' => q{Budafoɔ Kalɛnna},
 				'chinese' => q{Kyaenafoɔ Kalɛnna},
 				'coptic' => q{Kɔtesefoɔ Kalɛnna},
 				'dangi' => q{Dangi Kalɛnna},
 				'ethiopic' => q{Yitiopia Kalɛnna},
 				'ethiopic-amete-alem' => q{Yitiopia Amete Alɛm Kalɛnna},
 				'gregorian' => q{Gregorian Kalɛnna},
 				'hebrew' => q{Hibri Kalɛnda},
 				'islamic' => q{Higyiri Kalɛnda},
 				'islamic-civil' => q{Higyiri Kalɛnda (tabula, sivil epokyi},
 				'islamic-umalqura' => q{Higyiri Kalɛnda (Ummm al-Kura)},
 				'iso8601' => q{ISO-8601 Kalɛnna},
 				'japanese' => q{Gyapanfoɔ Kalɛnda},
 				'persian' => q{Pɛɛsiafoɔ Kalɛnda},
 				'roc' => q{Minguo Kalɛnda},
 			},
 			'cf' => {
 				'account' => q{Sika Nkotabuo Fɔmate},
 				'standard' => q{Sika Fɔmate Susudua},
 			},
 			'collation' => {
 				'ducet' => q{Koodu Korɔ Nyiyie Kwan a ɛdi Kan},
 				'search' => q{Daa-Botaeɛ Adehwehwɛ},
 				'standard' => q{Nyiyie Kwan Susudua},
 			},
 			'hc' => {
 				'h11' => q{Nnɔnhwere 12 Sestɛm (0–11)},
 				'h12' => q{Nnɔnhwere 12 Sestɛm (1–12},
 				'h23' => q{Nnɔnhwere 24 Sestɛm (0–23)},
 				'h24' => q{Nnɔnhwere 24 Sestɛm (0–24)},
 			},
 			'lb' => {
 				'loose' => q{Line Break Nhyehyɛeɛ a Emu Yɛ Mmrɛ},
 				'normal' => q{Daa Line Break Nhyehyɛeɛ},
 				'strict' => q{Line Break Nhyehyɛeɛ Ferenkyemm},
 			},
 			'ms' => {
 				'metric' => q{Mɛtreke Nhyehyɛeɛ},
 				'uksystem' => q{Imperial Nsusudeɛ Sestɛm},
 				'ussystem' => q{US Nsusudeɛ Sestɛm},
 			},
 			'numbers' => {
 				'arab' => q{Arabeke Digyete},
 				'arabext' => q{Arabeke Digyete a Wɔatrɛm},
 				'armn' => q{Aamenia Nɔma},
 				'armnlow' => q{Aamenia Nɔma Nkumaa},
 				'beng' => q{Bangla Gigyete},
 				'cakm' => q{Kyakma Digyete},
 				'deva' => q{Devanagari Gigyete},
 				'ethi' => q{Yitiopia Nɔma},
 				'fullwide' => q{Digyete a Emu Pi},
 				'geor' => q{Gyɔgyea Nɔma},
 				'grek' => q{Griiki Nɔma},
 				'greklow' => q{Griiki Nɔma Nkumaa},
 				'gujr' => q{Gugyarati Digyete},
 				'guru' => q{Gurumuki Digyete},
 				'hanidec' => q{Kyaenafoɔ Dɛsima Nɔma},
 				'hans' => q{Kyaenafoɔ Dɛsima Nɔma a Emu Yɛ Mmrɛ},
 				'hansfin' => q{Kyaenafoɔ Sikasɛm Dɛsima Nɔma a Emu Yɛ Mmrɛ},
 				'hant' => q{Kyaenafoɔ Tete Nɔma},
 				'hantfin' => q{Tete Kyaena Sikasɛm Nɔma},
 				'hebr' => q{Hibri Nɔma},
 				'java' => q{Gyavaniisi Digyete},
 				'jpan' => q{Gyapanfoɔ Nɔma},
 				'jpanfin' => q{Gyapanfoɔ Sikasɛm Nɔma},
 				'khmr' => q{Kima Digyete},
 				'knda' => q{Kanada Digyete},
 				'laoo' => q{Lawo Digyete},
 				'latn' => q{Atɔeɛ Fam Digyete},
 				'mlym' => q{Malayalam Digyete},
 				'mtei' => q{Meeti Mayɛke Digyete},
 				'mymr' => q{Mayaama Digyete},
 				'olck' => q{Ol Kyiki Digyete},
 				'orya' => q{Odia Digyete},
 				'roman' => q{Roman Nɔma},
 				'romanlow' => q{Romanfoɔ Nɔma Nkumaa},
 				'taml' => q{Tamil Tete Nɔma},
 				'tamldec' => q{Tamil Digyete},
 				'telu' => q{Telugu Digyete},
 				'thai' => q{Taelanfoɔ Digyete},
 				'tibt' => q{Tibɛtan Digyete},
 				'vaii' => q{Vai Gigyete},
 			},

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
			auxiliary => qr{[áäã c éë í j óö q ü v z]},
			index => ['A', 'B', 'C', 'D', 'E', 'Ɛ', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'Ɔ', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b d e ɛ f g h i k l m n o ɔ p r s t u w y]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'Ɛ', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'Ɔ', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(kadinaa akwankyerɛ),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(kadinaa akwankyerɛ),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(dɛci{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(dɛci{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(piko{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(piko{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(fɛmtɔ{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(fɛmtɔ{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(atto{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(atto{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(sɛnti{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(sɛnti{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(mili{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(mili{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(mikro{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(mikro{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(nano{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(nano{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(dika{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(dika{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(tɛra{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(tɛra{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(pɛta{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(pɛta{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(hɛkto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hɛkto{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(kilo{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(kilo{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(mɛga{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(mɛga{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q({0} g-force),
						'other' => q({0} g-force),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0} g-force),
						'other' => q({0} g-force),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(aakesima),
						'one' => q(aakesima {0}),
						'other' => q(aakesima {0}),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(aakesima),
						'one' => q(aakesima {0}),
						'other' => q(aakesima {0}),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(aakesɛkɛnse),
						'one' => q({0} aakesɛkɛnse),
						'other' => q({0} aakesɛkɛnse),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(aakesɛkɛnse),
						'one' => q({0} aakesɛkɛnse),
						'other' => q({0} aakesɛkɛnse),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(digrii),
						'one' => q(digrii {0}),
						'other' => q(digrii {0}),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(digrii),
						'one' => q(digrii {0}),
						'other' => q(digrii {0}),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radian),
						'one' => q({0} radian),
						'other' => q({0} radian),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radian),
						'one' => q({0} radian),
						'other' => q({0} radian),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(ntwaho),
						'one' => q(ntwaho {0}),
						'other' => q(ntwaho {0}),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(ntwaho),
						'one' => q(ntwaho {0}),
						'other' => q(ntwaho {0}),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(Eka),
						'one' => q({0} eka),
						'other' => q({0} eka),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(Eka),
						'one' => q({0} eka),
						'other' => q({0} eka),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(adeɛ),
						'one' => q(adeɛ {0}),
						'other' => q(adeɛ {0}),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(adeɛ),
						'one' => q(adeɛ {0}),
						'other' => q(adeɛ {0}),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(miligrame dɛsilita biara),
						'one' => q(miligrame dɛsilita biara {0}),
						'other' => q(miligrame dɛsilita biara {0}),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(miligrame dɛsilita biara),
						'one' => q(miligrame dɛsilita biara {0}),
						'other' => q(miligrame dɛsilita biara {0}),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(milimole lita biara),
						'one' => q(milimole lita biara {0}),
						'other' => q(milimole lita biara {0}),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimole lita biara),
						'one' => q(milimole lita biara {0}),
						'other' => q(milimole lita biara {0}),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(mole),
						'one' => q({0} mole),
						'other' => q({0} mole),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(mole),
						'one' => q({0} mole),
						'other' => q({0} mole),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(ɔha nkyɛmu),
						'one' => q(ɔha nkyɛmu {0}),
						'other' => q(ɔha nkyɛmu {0}),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(ɔha nkyɛmu),
						'one' => q(ɔha nkyɛmu {0}),
						'other' => q(ɔha nkyɛmu {0}),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(pɛmile),
						'one' => q(pɛɛmile {0}),
						'other' => q(pɛɛmile {0}),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(pɛmile),
						'one' => q(pɛɛmile {0}),
						'other' => q(pɛɛmile {0}),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(paat ɔpepem biara),
						'one' => q(paat ɔpepem biara {0}),
						'other' => q(paat ɔpepem biara {0}),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(paat ɔpepem biara),
						'one' => q(paat ɔpepem biara {0}),
						'other' => q(paat ɔpepem biara {0}),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(pɛɛmiride),
						'one' => q(pɛɛmiride {0}),
						'other' => q(pɛɛmiride {0}),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(pɛɛmiride),
						'one' => q(pɛɛmiride {0}),
						'other' => q(pɛɛmiride {0}),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(paat ɔpepepem biara),
						'one' => q(paat ɔpepepem biara {0}),
						'other' => q(paat ɔpepepem biara {0}),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(paat ɔpepepem biara),
						'one' => q(paat ɔpepepem biara {0}),
						'other' => q(paat ɔpepepem biara {0}),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(lita kilomita 100 biara),
						'one' => q(lita kilomita 100 biara {0}),
						'other' => q(lita kilomita 100 biara {0}),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(lita kilomita 100 biara),
						'one' => q(lita kilomita 100 biara {0}),
						'other' => q(lita kilomita 100 biara {0}),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(lita kilomita biara),
						'one' => q(lita kilomita biara {0}),
						'other' => q(lita kilomita biara {0}),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(lita kilomita biara),
						'one' => q(lita kilomita biara {0}),
						'other' => q(lita kilomita biara {0}),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mile galɔn biara),
						'one' => q(mile galɔn biara {0}),
						'other' => q(mile galɔn biara {0}),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mile galɔn biara),
						'one' => q(mile galɔn biara {0}),
						'other' => q(mile galɔn biara {0}),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mile Imp. galɔn biara),
						'one' => q(mile Imp. galɔn biara {0}),
						'other' => q(mile Imp. galɔn biara {0}),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mile Imp. galɔn biara),
						'one' => q(mile Imp. galɔn biara {0}),
						'other' => q(mile Imp. galɔn biara {0}),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} apueɛ),
						'north' => q({0} atifi),
						'south' => q({0} anaafoɔ),
						'west' => q({0} atɔeɛ),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} apueɛ),
						'north' => q({0} atifi),
						'south' => q({0} anaafoɔ),
						'west' => q({0} atɔeɛ),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabit),
						'one' => q({0} Gb),
						'other' => q({0} gigabit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabit),
						'one' => q({0} Gb),
						'other' => q({0} gigabit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigabyte),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabyte),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabyte),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabyte),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobits),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobits),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kilobyte),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobyte),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilobyte),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobyte),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(megabyte),
						'one' => q({0} megabyte),
						'other' => q({0} megabyte),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megabyte),
						'one' => q({0} megabyte),
						'other' => q({0} megabyte),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petabytes),
						'one' => q({0} petabyte),
						'other' => q({0} petabyte),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petabytes),
						'one' => q({0} petabyte),
						'other' => q({0} petabyte),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(terabyte),
						'one' => q({0} terabyte),
						'other' => q({0} terabyte),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(terabyte),
						'one' => q({0} terabyte),
						'other' => q({0} terabyte),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(mfeha),
						'one' => q(afeha{0}),
						'other' => q(mfeha{0}),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(mfeha),
						'one' => q(afeha{0}),
						'other' => q(mfeha{0}),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(nna),
						'one' => q(da {0}),
						'other' => q(nna {0}),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(nna),
						'one' => q(da {0}),
						'other' => q(nna {0}),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(mfenhyia du),
						'one' => q(mfenhyia du {0}),
						'other' => q({0} dec),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(mfenhyia du),
						'one' => q(mfenhyia du {0}),
						'other' => q({0} dec),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(dɔnhwere),
						'one' => q(dɔnhwere {0}),
						'other' => q(dɔnhwere {0}),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(dɔnhwere),
						'one' => q(dɔnhwere {0}),
						'other' => q(dɔnhwere {0}),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μsecs),
						'one' => q({0} mikrosɛkɛn),
						'other' => q({0} mikrosɛkɛns),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μsecs),
						'one' => q({0} mikrosɛkɛn),
						'other' => q({0} mikrosɛkɛns),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisɛkɛns),
						'one' => q({0} millisɛkɛn),
						'other' => q({0} millisɛkɛns),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisɛkɛns),
						'one' => q({0} millisɛkɛn),
						'other' => q({0} millisɛkɛns),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(sima),
						'one' => q(sima {0}),
						'other' => q(sima {0}),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(sima),
						'one' => q(sima {0}),
						'other' => q(sima {0}),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(bosome),
						'one' => q(Bosome {0}),
						'other' => q(Bosome {0}),
						'per' => q(bosome biara {0}),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(bosome),
						'one' => q(Bosome {0}),
						'other' => q(Bosome {0}),
						'per' => q(bosome biara {0}),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosɛkɛns),
						'one' => q({0} nanosɛkɛn),
						'other' => q({0} nanosɛkɛns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosɛkɛns),
						'one' => q({0} nanosɛkɛn),
						'other' => q({0} nanosɛkɛns),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(anadwo),
						'one' => q({0} anadwo),
						'other' => q(anadwo{0}),
						'per' => q(anadwo biara{0}),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(anadwo),
						'one' => q({0} anadwo),
						'other' => q(anadwo{0}),
						'per' => q(anadwo biara{0}),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(kɔta),
						'one' => q(kɔta {0}),
						'other' => q({0} q),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(kɔta),
						'one' => q(kɔta {0}),
						'other' => q({0} q),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sima sini),
						'one' => q(sima sini {0}),
						'other' => q(sima sini {0}),
						'per' => q(sima sini biara {0}),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sima sini),
						'one' => q(sima sini {0}),
						'other' => q(sima sini {0}),
						'per' => q(sima sini biara {0}),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(nnawɔtwe),
						'one' => q(nnawɔtwe {0}),
						'other' => q(nnawɔtwe {0}),
						'per' => q(nnawɔtwe biara {0}),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(nnawɔtwe),
						'one' => q(nnawɔtwe {0}),
						'other' => q(nnawɔtwe {0}),
						'per' => q(nnawɔtwe biara {0}),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(mfeɛ),
						'one' => q(mfeɛ {0}),
						'other' => q(mfeɛ {0}),
						'per' => q(mfeɛ biara {0}),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(mfeɛ),
						'one' => q(mfeɛ {0}),
						'other' => q(mfeɛ {0}),
						'per' => q(mfeɛ biara {0}),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowat-nnɔnhwere 100 kilomita biara),
						'one' => q(kilowat-nnɔnhwere 100 kilomita biara {0}),
						'other' => q(kilowat-nnɔnhwere 100 kilomita biara {0}),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowat-nnɔnhwere 100 kilomita biara),
						'one' => q(kilowat-nnɔnhwere 100 kilomita biara {0}),
						'other' => q(kilowat-nnɔnhwere 100 kilomita biara {0}),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(newton),
						'one' => q({0} newton),
						'other' => q({0} newton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newton),
						'one' => q({0} newton),
						'other' => q({0} newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(fɔs mu pɔn),
						'one' => q(fɔs mu pɔn {0}),
						'other' => q(fɔs mu pɔn {0}),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(fɔs mu pɔn),
						'one' => q(fɔs mu pɔn {0}),
						'other' => q(fɔs mu pɔn {0}),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(taipografik ems),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(taipografik ems),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'one' => q({0} megapixel),
						'other' => q({0} megapixels),
					},
					# Core Unit Identifier
					'megapixel' => {
						'one' => q({0} megapixel),
						'other' => q({0} megapixels),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pixels),
						'one' => q({0} pixel),
						'other' => q({0} pixels),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pixels),
						'one' => q({0} pixel),
						'other' => q({0} pixels),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(pixels sɛntimita biara),
						'one' => q(pixels sɛntimita biara {0}),
						'other' => q(pixels sɛntimita biara{0}),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(pixels sɛntimita biara),
						'one' => q(pixels sɛntimita biara {0}),
						'other' => q(pixels sɛntimita biara{0}),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pixels inkye biara),
						'one' => q(pixels inkye biara{0}),
						'other' => q(pixels inkye biara{0}),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pixels inkye biara),
						'one' => q(pixels inkye biara{0}),
						'other' => q(pixels inkye biara{0}),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(astrɔnɔmikaa winit),
						'one' => q(astrɔnɔmikaa winit {0}),
						'other' => q(astrɔnɔmikaa winit {0}),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(astrɔnɔmikaa winit),
						'one' => q(astrɔnɔmikaa winit {0}),
						'other' => q(astrɔnɔmikaa winit {0}),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sɛntimita),
						'one' => q(sɛntimita {0}),
						'other' => q(sɛntimita {0}),
						'per' => q(sɛntimita biara {0}),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sɛntimita),
						'one' => q(sɛntimita {0}),
						'other' => q(sɛntimita {0}),
						'per' => q(sɛntimita biara {0}),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(dɛsimita),
						'one' => q(dɛsimita {0}),
						'other' => q(dɛsimita {0}),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(dɛsimita),
						'one' => q(dɛsimita {0}),
						'other' => q(dɛsimita {0}),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(asaase radiɔs),
						'one' => q(asaase radiɔs {0}),
						'other' => q(asaase radiɔs{0}),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(asaase radiɔs),
						'one' => q(asaase radiɔs {0}),
						'other' => q(asaase radiɔs{0}),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fatɔmse),
						'one' => q(fatɔmse {0}),
						'other' => q(fatɔmse {0}),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fatɔmse),
						'one' => q(fatɔmse {0}),
						'other' => q(fatɔmse {0}),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(ananmɔn),
						'one' => q(ananmɔn {0}),
						'other' => q({0} ft),
						'per' => q(ananmɔn biara {0}),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(ananmɔn),
						'one' => q(ananmɔn {0}),
						'other' => q({0} ft),
						'per' => q(ananmɔn biara {0}),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(fɛɛlɔɔne),
						'one' => q(fɛɛlɔɔne {0}),
						'other' => q(fɛɛlɔɔne {0}),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(fɛɛlɔɔne),
						'one' => q(fɛɛlɔɔne {0}),
						'other' => q(fɛɛlɔɔne {0}),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(inkyisi),
						'one' => q(inkyisi {0}),
						'other' => q(inkyisi {0}),
						'per' => q(inkyisi biara {0}),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(inkyisi),
						'one' => q(inkyisi {0}),
						'other' => q(inkyisi {0}),
						'per' => q(inkyisi biara {0}),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilomita),
						'one' => q(kilomita {0}),
						'other' => q(kilomita {0}),
						'per' => q(kilomita biara{0}),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilomita),
						'one' => q(kilomita {0}),
						'other' => q(kilomita {0}),
						'per' => q(kilomita biara{0}),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(kanea mfeɛ),
						'one' => q(kanea mfeɛ {0}),
						'other' => q(kanea mfeɛ {0}),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(kanea mfeɛ),
						'one' => q(kanea mfeɛ {0}),
						'other' => q(kanea mfeɛ {0}),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(mita),
						'one' => q(mita {0}),
						'other' => q(mita {0}),
						'per' => q(mita biara {0}),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(mita),
						'one' => q(mita {0}),
						'other' => q(mita {0}),
						'per' => q(mita biara {0}),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mikromita),
						'one' => q(mikromita {0}),
						'other' => q(mikromita {0}),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mikromita),
						'one' => q(mikromita {0}),
						'other' => q(mikromita {0}),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(kwansini),
						'one' => q(kwansini {0}),
						'other' => q(kwansini {0}),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(kwansini),
						'one' => q(kwansini {0}),
						'other' => q(kwansini {0}),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(miaase-skandinavian),
						'one' => q(miaase-skandinavian {0}),
						'other' => q(miaase-skandinavian {0}),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(miaase-skandinavian),
						'one' => q(miaase-skandinavian {0}),
						'other' => q(miaase-skandinavian {0}),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(milimita),
						'one' => q(milimita {0}),
						'other' => q(milimita {0}),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(milimita),
						'one' => q(milimita {0}),
						'other' => q(milimita {0}),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanomita),
						'one' => q(nanomita {0}),
						'other' => q(nanomita {0}),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanomita),
						'one' => q(nanomita {0}),
						'other' => q(nanomita {0}),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(nɔtikaa ananmɔn),
						'one' => q(nɔtikaa ananmɔn {0}),
						'other' => q(nɔtikaa ananmɔn {0}),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(nɔtikaa ananmɔn),
						'one' => q(nɔtikaa ananmɔn {0}),
						'other' => q(nɔtikaa ananmɔn {0}),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(paasɛk),
						'one' => q(paasɛk {0}),
						'other' => q(paasɛk {0}),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(paasɛk),
						'one' => q(paasɛk {0}),
						'other' => q(paasɛk {0}),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikomita),
						'one' => q(pikomita {0}),
						'other' => q(pikomita {0}),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikomita),
						'one' => q(pikomita {0}),
						'other' => q(pikomita {0}),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pɔnse),
						'one' => q(pɔnse {0}),
						'other' => q(pɔnse {0}),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pɔnse),
						'one' => q(pɔnse {0}),
						'other' => q(pɔnse {0}),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(sola radii),
						'one' => q(sola radii {0}),
						'other' => q(sola radii {0}),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(sola radii),
						'one' => q(sola radii {0}),
						'other' => q(sola radii {0}),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yaase),
						'one' => q(yaase {0}),
						'other' => q(yaase {0}),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yaase),
						'one' => q(yaase {0}),
						'other' => q(yaase {0}),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kandela),
						'one' => q({0} kandela),
						'other' => q({0} kandela),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kandela),
						'one' => q({0} kandela),
						'other' => q({0} kandela),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lumen),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lumen),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(sola luminɔsitise),
						'one' => q(sola luminɔsitise {0}),
						'other' => q(sola luminɔsitise {0}),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(sola luminɔsitise),
						'one' => q(sola luminɔsitise {0}),
						'other' => q(sola luminɔsitise {0}),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karat),
						'one' => q(karat {0}),
						'other' => q(karat {0}),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karat),
						'one' => q(karat {0}),
						'other' => q(karat {0}),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(daatin),
						'one' => q(daatin {0}),
						'other' => q(daatin {0}),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(daatin),
						'one' => q(daatin {0}),
						'other' => q(daatin {0}),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(Asaase mass),
						'one' => q(Asaase mass {0}),
						'other' => q(Asaase mass {0}),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(Asaase mass),
						'one' => q(Asaase mass {0}),
						'other' => q(Asaase mass {0}),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grame),
						'one' => q(grame {0}),
						'other' => q({0} g),
						'per' => q(grame biara {0}),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grame),
						'one' => q(grame {0}),
						'other' => q({0} g),
						'per' => q(grame biara {0}),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilograme),
						'one' => q(kilograme {0}),
						'other' => q(kilograme {0}),
						'per' => q(kilograme biara {0}),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilograme),
						'one' => q(kilograme {0}),
						'other' => q(kilograme {0}),
						'per' => q(kilograme biara {0}),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(mikrograme),
						'one' => q(mikrograme {0}),
						'other' => q(mikrograme {0}),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(mikrograme),
						'one' => q(mikrograme {0}),
						'other' => q(mikrograme {0}),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(miligrame),
						'one' => q(miligrame {0}),
						'other' => q(miligrame {0}),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(miligrame),
						'one' => q(miligrame {0}),
						'other' => q(miligrame {0}),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(awnse),
						'one' => q(awnse {0}),
						'other' => q(awnse {0}),
						'per' => q(awnse biara {0}),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(awnse),
						'one' => q(awnse {0}),
						'other' => q(awnse {0}),
						'per' => q(awnse biara {0}),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troy awnse),
						'one' => q(troy awnse {0}),
						'other' => q(troy awnse {0}),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troy awnse),
						'one' => q(troy awnse {0}),
						'other' => q(troy awnse {0}),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(pɔns),
						'one' => q(pɔns {0}),
						'other' => q(pɔns {0}),
						'per' => q(pɔns biara {0}),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(pɔns),
						'one' => q(pɔns {0}),
						'other' => q(pɔns {0}),
						'per' => q(pɔns biara {0}),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(sola mass),
						'one' => q(sola mass {0}),
						'other' => q(sola mass {0}),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(sola mass),
						'one' => q(sola mass {0}),
						'other' => q(sola mass {0}),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0} ton),
						'other' => q({0} tons),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0} ton),
						'other' => q({0} tons),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(mɛtreke tons),
						'one' => q(mɛtreke tons {0}),
						'other' => q(mɛtreke tons {0}),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(mɛtreke tons),
						'one' => q(mɛtreke tons {0}),
						'other' => q(mɛtreke tons {0}),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} wɔ {1} biara mu),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} wɔ {1} biara mu),
					},
					# Long Unit Identifier
					'power2' => {
						'one' => q(sokwɛɛ {0}),
						'other' => q(sokwɛɛ {0}),
					},
					# Core Unit Identifier
					'power2' => {
						'one' => q(sokwɛɛ {0}),
						'other' => q(sokwɛɛ {0}),
					},
					# Long Unit Identifier
					'power3' => {
						'one' => q(kubik {0}),
						'other' => q(kubik {0}),
					},
					# Core Unit Identifier
					'power3' => {
						'one' => q(kubik {0}),
						'other' => q(kubik {0}),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(Pɔ),
						'one' => q(Pɔ {0}),
						'other' => q(Pɔ {0}),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(Pɔ),
						'one' => q(Pɔ {0}),
						'other' => q(Pɔ {0}),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(kanea),
						'one' => q(kanea {0}),
						'other' => q(kanea {0}),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(kanea),
						'one' => q(kanea {0}),
						'other' => q(kanea {0}),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}-{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}-{1}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(Newton-mita),
						'one' => q({0} newton-mita),
						'other' => q({0} newton-mita),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(Newton-mita),
						'one' => q({0} newton-mita),
						'other' => q({0} newton-mita),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(pɔn-fɔs-ananmɔn),
						'one' => q(pɔn-fɔs-ananmɔn {0}),
						'other' => q(pɔn-fɔs-ananmɔn {0}),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(pɔn-fɔs-ananmɔn),
						'one' => q(pɔn-fɔs-ananmɔn {0}),
						'other' => q(pɔn-fɔs-ananmɔn {0}),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(bare),
						'one' => q(bare {0}),
						'other' => q(bare {0}),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(bare),
						'one' => q(bare {0}),
						'other' => q(bare {0}),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(kuruwa),
						'one' => q(kuruwa {0}),
						'other' => q(kuruwa {0}),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(kuruwa),
						'one' => q(kuruwa {0}),
						'other' => q(kuruwa {0}),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(atere),
						'one' => q(atere {0}),
						'other' => q(atere {0}),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(atere),
						'one' => q(atere {0}),
						'other' => q(atere {0}),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(drɔm),
						'one' => q(drɔm fl {0}),
						'other' => q(drɔm fl {0}),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(drɔm),
						'one' => q(drɔm fl {0}),
						'other' => q(drɔm fl {0}),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(koko),
						'one' => q(ko {0}),
						'other' => q(koko {0}),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(koko),
						'one' => q(ko {0}),
						'other' => q(koko {0}),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(gyega),
						'one' => q(gyega {0}),
						'other' => q(gyega {0}),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(gyega),
						'one' => q(gyega {0}),
						'other' => q(gyega {0}),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(lita),
						'one' => q({0} l),
						'other' => q({0} lita),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(lita),
						'one' => q({0} l),
						'other' => q({0} lita),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pints),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pints),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(Atere kɛseɛ),
						'one' => q(Atere kɛseɛ {0}),
						'other' => q(Atere kɛseɛ {0}),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(Atere kɛseɛ),
						'one' => q(Atere kɛseɛ {0}),
						'other' => q(Atere kɛseɛ {0}),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(atere fa),
						'one' => q(atere fa {0}),
						'other' => q(atere fa {0}),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(atere fa),
						'one' => q(atere fa {0}),
						'other' => q(atere fa {0}),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'' => {
						'name' => q(akwankyerɛ),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(akwankyerɛ),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(aakesima),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(aakesima),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(aakesɛkɛnse),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(aakesɛkɛnse),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(digrii),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(digrii),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radian),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radian),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(Eka),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(Eka),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(adeɛ),
						'one' => q(adeɛ {0}),
						'other' => q(adeɛ {0}),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(adeɛ),
						'one' => q(adeɛ {0}),
						'other' => q(adeɛ {0}),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karat),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karat),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(milimol/lita),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimol/lita),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(ɔha nkyɛmu),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(ɔha nkyɛmu),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(paat ɔpepem biara),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(paat ɔpepem biara),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(pɛɛmiride),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(pɛɛmiride),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(paat ɔpepepem biara),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(paat ɔpepepem biara),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(lita kilomita biara),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(lita kilomita biara),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mile galɔn biara),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mile galɔn biara),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mpg UK),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mpg UK),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(B),
						'one' => q({0}B),
						'other' => q({0}B),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(B),
						'one' => q({0}B),
						'other' => q({0}B),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PByte),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PByte),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(da),
						'one' => q(da {0}),
						'other' => q(nna {0}),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(da),
						'one' => q(da {0}),
						'other' => q(nna {0}),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(dɔnhwere),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(dɔnhwere),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μsec),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μsec),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(bosome),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(bosome),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(anadwo),
						'one' => q(anadwo{0}),
						'other' => q(anadwo{0}),
						'per' => q({0}/anadwo),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(anadwo),
						'one' => q(anadwo{0}),
						'other' => q(anadwo{0}),
						'per' => q({0}/anadwo),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(nnawɔtwe),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(nnawɔtwe),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(mfeɛ),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(mfeɛ),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(fɔs mu pɔn),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(fɔs mu pɔn),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(asaase radiɔs),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(asaase radiɔs),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fatɔmse),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fatɔmse),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(ananmɔn),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(ananmɔn),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(fɛɛlɔɔne),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(fɛɛlɔɔne),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(inkyisi),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(inkyisi),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(kanea mfeɛ),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(kanea mfeɛ),
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
					'length-parsec' => {
						'name' => q(paasɛk),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(paasɛk),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pts),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pts),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(sola radii),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(sola radii),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yaase),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yaase),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lux),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(sola luminɔsitise),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(sola luminɔsitise),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karat),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karat),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(daatin),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(daatin),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(Asaase mass),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(Asaase mass),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(gr),
						'one' => q({0}gr),
						'other' => q({0}gr),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(gr),
						'one' => q({0}gr),
						'other' => q({0}gr),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grame),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grame),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(oz troy),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(oz troy),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(pɔns),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(pɔns),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(sola mass),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(sola mass),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(kanea),
						'one' => q(kanea {0}),
						'other' => q(kanea {0}),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(kanea),
						'one' => q(kanea {0}),
						'other' => q(kanea {0}),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(kuruwa),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(kuruwa),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(dsp),
						'one' => q({0}dsp),
						'other' => q({0}dsp),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(dsp),
						'one' => q({0}dsp),
						'other' => q({0}dsp),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(fl.dr.),
						'one' => q(drɔm fl {0}),
						'other' => q(drɔm fl {0}),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(fl.dr.),
						'one' => q(drɔm fl {0}),
						'other' => q(drɔm fl {0}),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(dr),
						'one' => q(ko {0}),
						'other' => q(ko {0}),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(dr),
						'one' => q(ko {0}),
						'other' => q(ko {0}),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(gyega),
						'one' => q(gyega {0}),
						'other' => q(gyega {0}),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(gyega),
						'one' => q(gyega {0}),
						'other' => q(gyega {0}),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(lita),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(lita),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(pn),
						'one' => q({0} pn),
						'other' => q({0} pn),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(pn),
						'one' => q({0} pn),
						'other' => q({0} pn),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(pt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(pt),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(akwankyerɛ),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(akwankyerɛ),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(aakesima),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(aakesima),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(aakesɛkɛnse),
						'one' => q({0} aakesɛkɛnse),
						'other' => q({0} aakesɛkɛnse),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(aakesɛkɛnse),
						'one' => q({0} aakesɛkɛnse),
						'other' => q({0} aakesɛkɛnse),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(digrii),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(digrii),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radian),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radian),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(Eka),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(Eka),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(adeɛ),
						'one' => q(adeɛ {0}),
						'other' => q(adeɛ {0}),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(adeɛ),
						'one' => q(adeɛ {0}),
						'other' => q(adeɛ {0}),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karat),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karat),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(milimol/lita),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimol/lita),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(mole),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(mole),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(ɔha nkyɛmu),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(ɔha nkyɛmu),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(pɛɛmile),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(pɛɛmile),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(paat ɔpepem biara),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(paat ɔpepem biara),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(pɛɛmiride),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(pɛɛmiride),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(paat ɔpepepem biara),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(paat ɔpepepem biara),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(lita kilomita biara),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(lita kilomita biara),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mile galɔn biara),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mile galɔn biara),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mile Imp. galɔn biara),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mile Imp. galɔn biara),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gbit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gbit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GByte),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GByte),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kbit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kbit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kByte),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kByte),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mbit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mbit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MByte),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MByte),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PByte),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PByte),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tbit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tbit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(TByte),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TByte),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(nna),
						'one' => q(da {0}),
						'other' => q(nna {0}),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(nna),
						'one' => q(da {0}),
						'other' => q(nna {0}),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(dɔnhwere),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(dɔnhwere),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μsecs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μsecs),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(bosome),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(bosome),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosɛkɛns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosɛkɛns),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(anadwo),
						'one' => q(anadwo{0}),
						'other' => q(anadwo{0}),
						'per' => q({0}/anadwo),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(anadwo),
						'one' => q(anadwo{0}),
						'other' => q(anadwo{0}),
						'per' => q({0}/anadwo),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(nnawɔtwe),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(nnawɔtwe),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(mfeɛ),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(mfeɛ),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(newton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(fɔs mu pɔn),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(fɔs mu pɔn),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pixels),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pixels),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(asaase radiɔs),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(asaase radiɔs),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fatɔmse),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fatɔmse),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(ananmɔn),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(ananmɔn),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(fɛɛlɔɔne),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(fɛɛlɔɔne),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(inkyisi),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(inkyisi),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(kanea mfeɛ),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(kanea mfeɛ),
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
						'name' => q(kwansini),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(kwansini),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(paasɛk),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(paasɛk),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pɔnse),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pɔnse),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(sola radii),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(sola radii),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yaase),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yaase),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kandela),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kandela),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lumen),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lumen),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lux),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(sola luminɔsitise),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(sola luminɔsitise),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karat),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karat),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(daatin),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(daatin),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(Asaase mass),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(Asaase mass),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'one' => q({0} gr),
						'other' => q({0} gr),
					},
					# Core Unit Identifier
					'grain' => {
						'one' => q({0} gr),
						'other' => q({0} gr),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grame),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grame),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(oz troy),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(oz troy),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(pɔns),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(pɔns),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(sola mass),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(sola mass),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(kanea),
						'one' => q(kanea {0}),
						'other' => q(kanea {0}),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(kanea),
						'one' => q(kanea {0}),
						'other' => q(kanea {0}),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(bare),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(bare),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(kuruwa),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(kuruwa),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(atere),
						'one' => q({0} dsp),
						'other' => q({0} dsp),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(atere),
						'one' => q({0} dsp),
						'other' => q({0} dsp),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(drɔm),
						'one' => q(drɔm {0}),
						'other' => q(drɔm {0}),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(drɔm),
						'one' => q(drɔm {0}),
						'other' => q(drɔm {0}),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(koko),
						'one' => q(ko {0}),
						'other' => q(ko {0}),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(koko),
						'one' => q(ko {0}),
						'other' => q(ko {0}),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(gyega),
						'one' => q(gyega {0}),
						'other' => q(gyega {0}),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(gyega),
						'one' => q(gyega {0}),
						'other' => q(gyega {0}),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(lita),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(lita),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'one' => q({0} pn),
						'other' => q({0} pn),
					},
					# Core Unit Identifier
					'pinch' => {
						'one' => q({0} pn),
						'other' => q({0} pn),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pints),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pints),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Yiw|Y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Daabi|D|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0}, ne {1}),
				2 => q({0} ne {1}),
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
					'one' => 'apem 0',
					'other' => 'apem 0',
				},
				'10000' => {
					'one' => 'mpem 00',
					'other' => 'mpem 00',
				},
				'100000' => {
					'one' => 'mpem 000',
					'other' => 'mpem 000',
				},
				'1000000' => {
					'one' => 'ɔpepem 0',
					'other' => 'ɔpepem 0',
				},
				'10000000' => {
					'one' => 'ɔpepem 00',
					'other' => 'ɔpepem 00',
				},
				'100000000' => {
					'one' => 'ɔpepem 000',
					'other' => 'ɔpepem 000',
				},
				'1000000000' => {
					'one' => 'ɔpepepem 0',
					'other' => 'ɔpepepem 0',
				},
				'10000000000' => {
					'one' => 'ɔpepepem 00',
					'other' => 'ɔpepepem 00',
				},
				'100000000000' => {
					'one' => 'ɔpepepem 000',
					'other' => 'ɔpepepem 000',
				},
				'1000000000000' => {
					'one' => 'ɔpepepepem 0',
					'other' => 'ɔpepepepem 0',
				},
				'10000000000000' => {
					'one' => 'ɔpepepepem 00',
					'other' => 'ɔpepepepem 00',
				},
				'100000000000000' => {
					'one' => 'ɔpepepepem 000',
					'other' => 'ɔpepepepem 000',
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
		'AED' => {
			display_name => {
				'currency' => q(Ɛmirete Arab Nkabɔmu Deram),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afghanfoɔ Afghani),
				'one' => q(Afghanfoɔ Afghani),
				'other' => q(Afghanfoɔ Afghani),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Albania Lek),
				'one' => q(Albania lek),
				'other' => q(Albania lekë),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Amɛnia dram),
				'one' => q(Amɛnia dram),
				'other' => q(Amɛnia dram),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Nɛdɛlande Antɛlia guuda),
				'one' => q(Nɛdɛlande Antɛlia guuda),
				'other' => q(Nɛdɛlande Antɛlia guuda),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Angola Kwanza),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Agɛntina peso),
				'one' => q(Agɛntina peso),
				'other' => q(Agɛntina peso),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Ɔstrelia Dɔla),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Aruba flɔrin),
				'one' => q(Aruba flɔrin),
				'other' => q(Aruba flɔrin),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Azɛbagyan manat),
				'one' => q(Azɛbagyan manat),
				'other' => q(Azɛbagyan manat),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Bɔsnia-Hɛzegɔvina nsesa maake),
				'one' => q(Bɔsnia-Hɛzegɔvina nsesa maake),
				'other' => q(Bɔsnia-Hɛzegɔvina nsesa maake),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Babadɔso dɔla),
				'one' => q(Babadɔso dɔla),
				'other' => q(Babadɔso dɔla),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Bangladehye taka),
				'one' => q(Bangladehye taka),
				'other' => q(Bangladehye taka),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Bɔɔgaria lɛv),
				'one' => q(Bɔɔgaria lɛv),
				'other' => q(Bɔɔgaria lɛva),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Baren Dina),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burundi Frank),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bɛɛmuda dɔla),
				'one' => q(Bɛɛmuda dɔla),
				'other' => q(Bɛɛmuda dɔla),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Brunei dɔla),
				'one' => q(Brunei dɔla),
				'other' => q(Brunei dɔla),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Bolivia boliviano),
				'one' => q(Bolivia boliviano),
				'other' => q(Bolivia boliviano),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Brazil reale),
				'one' => q(Brazil reale),
				'other' => q(Brazil reale),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Bahama dɔla),
				'one' => q(Bahama dɔla),
				'other' => q(Bahama dɔla),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Butanfoɔ ngutrum),
				'one' => q(Butanfoɔ ngutrum),
				'other' => q(Butanfoɔ ngutrum),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Botswana Pula),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Bɛlaruhyia ruble),
				'one' => q(Bɛlaruhyia ruble),
				'other' => q(Bɛlaruhyia ruble),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Belize Dɔla),
				'one' => q(Belize Dɔla),
				'other' => q(Belize Dɔla),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Kanada Dɔla),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Kongo Frank),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Swiss Franc),
				'one' => q(Swiss franc),
				'other' => q(Swiss francs),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Kyili Peso),
				'one' => q(Kyili Peso),
				'other' => q(Kyili Peso),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(kyaena yuan \(offshore\)),
				'one' => q(kyaena yuan \(offshore\)),
				'other' => q(kyaena yuan \(offshore\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(kyaena yuan),
				'one' => q(kyaena yuan),
				'other' => q(kyaena yuan),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Kolombia peso),
				'one' => q(Kolombia peso),
				'other' => q(Kolombia peso),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Kɔsta Rika kɔlɔn),
				'one' => q(Kɔsta Rika kɔlɔn),
				'other' => q(Kɔsta Rika kɔlɔn),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Kuba nsesa peso),
				'one' => q(Kuba nsesa peso),
				'other' => q(Kuba nsesa peso),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Kuba peso),
				'one' => q(Kuba peso),
				'other' => q(Kuba peso),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Ɛskudo),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Kyɛk koruna),
				'one' => q(Kyɛk koruna),
				'other' => q(Kyɛk koruna),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Gyebuti Frank),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Danefoɔ krone),
				'one' => q(Danefoɔ krone),
				'other' => q(Danefoɔ krone),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Dɔmenika peso),
				'one' => q(Dɔmenika peso),
				'other' => q(Dɔmenika peso),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Ɔlgyeria Dina),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Egypt Pɔn),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Ɛretereya Nakfa),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Itiopia Bir),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Iro),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Figyi Dɔla),
				'one' => q(Figyi Dɔla),
				'other' => q(Figyi Dɔla),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Fɔkland Aelande Pɔn),
				'one' => q(Fɔkland Aelande Pɔn),
				'other' => q(Fɔkland Aelande Pɔn),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Breten Pɔn),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Gyɔɔgyia lari),
				'one' => q(Gyɔɔgyia lari),
				'other' => q(Gyɔɔgyia lari),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Ghana Sidi \(1979–2007\)),
			},
		},
		'GHS' => {
			symbol => 'GH₵',
			display_name => {
				'currency' => q(Ghana Sidi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Gyebrotaa pɔn),
				'one' => q(Gyebrotaa pɔn),
				'other' => q(Gyebrotaa pɔn),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Gambia Dalasi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Gini franke),
				'one' => q(Gini franke),
				'other' => q(Gini franke),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Gini Frank),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Guatemala kwɛtsaa),
				'one' => q(Guatemala kwɛtsaa),
				'other' => q(Guatemala kwɛtsaa),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Gayana dɔla),
				'one' => q(Gayana dɔla),
				'other' => q(Gayana dɔla),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Hɔnkɔn Dɔla),
				'one' => q(Hɔnkɔn Dɔla),
				'other' => q(Hɔnkɔn Dɔla),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Hɔndura lɛmpira),
				'one' => q(Hɔndura lɛmpira),
				'other' => q(Hɔndura lɛmpira),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Krohyia kuna),
				'one' => q(Krohyia kuna),
				'other' => q(Krohyia kunas),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Haiti gɔɔde),
				'one' => q(Haiti gɔɔde),
				'other' => q(Haiti gɔɔde),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Hangari fɔrint),
				'one' => q(Hangari fɔrint),
				'other' => q(Hangari fɔrint),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Indɔnihyia rupia),
				'one' => q(Indɔnihyia rupia),
				'other' => q(Indɔnihyia rupia),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Israel hyekel foforɔ),
				'one' => q(Israel hyekel foforɔ),
				'other' => q(Israel hyekel foforɔ),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(India Rupi),
			},
		},
		'IQD' => {
			symbol => 'Irak dinaa',
			display_name => {
				'currency' => q(Irak dinaa),
				'one' => q(Irak dinaa),
				'other' => q(Irak dinaa),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Yiranfoɔ rial),
				'one' => q(Yiranfoɔ rial),
				'other' => q(Yiranfoɔ rial),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Icelandfoɔ Króna),
				'one' => q(Icelandfoɔ króna),
				'other' => q(Icelandfoɔ krónur),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Gyameka dɔla),
				'one' => q(Gyameka dɔla),
				'other' => q(Gyameka dɔla),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Gyɔɔdan dinaa),
				'one' => q(Gyɔɔdan dinaa),
				'other' => q(Gyɔɔdan dinaa),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Gyapan Yɛn),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Kenya Hyelen),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Kagyɛstan som),
				'one' => q(Kagyɛstan som),
				'other' => q(Kagyɛstan som),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Kambodia riel),
				'one' => q(Kambodia riel),
				'other' => q(Kambodia riel),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Komoro Frank),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Korea Atifi won),
				'one' => q(Korea Atifi won),
				'other' => q(Korea Atifi won),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Korea Anaafoɔ won),
				'one' => q(Korea Anaafoɔ won),
				'other' => q(Korea Anaafoɔ won),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Kuwait dinaa),
				'one' => q(Kuwait dinaa),
				'other' => q(Kuwait dinaa),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Kayemanfo Aelande dɔla),
				'one' => q(Kayemanfo Aelande dɔla),
				'other' => q(Kayemanfo Aelande dɔla),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Kagyastan tenge),
				'one' => q(Kagyastan tenge),
				'other' => q(Kagyastan tenge),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Laohyia kip),
				'one' => q(Laohyia kip),
				'other' => q(Laohyia kip),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Lɛbanon pɔn),
				'one' => q(Lɛbanon pɔn),
				'other' => q(Lɛbanon pɔn),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Sri Lankafoɔ rupee),
				'one' => q(Sri Lankafoɔ rupee),
				'other' => q(Sri Lankafoɔ rupee),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Laeberia Dɔla),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesoto Loti),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Libya Dina),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Moroko Diram),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Moldova Leu),
				'one' => q(Moldova leu),
				'other' => q(Moldova lei),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Madagasi Frank),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Masidonia denaa),
				'one' => q(Masidonia denaa),
				'other' => q(Masidonia denari),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Mayamaa kyat),
				'one' => q(Mayamaa kyat),
				'other' => q(Mayamaa kyat),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Mongoliafoɔ tugrike),
				'one' => q(Mongoliafoɔ tugrike),
				'other' => q(Mongoliafoɔ tugrike),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Makaw pataka),
				'one' => q(Makaw pataka),
				'other' => q(Makaw pataka),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Mɔretenia Ouguiya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Mɔretenia Ouguiya),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Mɔrehyeɔs Rupi),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Maldivefoɔ rufiyaa),
				'one' => q(Maldivefoɔ rufiyaa),
				'other' => q(Maldivefoɔ rufiyaa),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malawi Kwakya),
				'one' => q(Malawi Kwakya),
				'other' => q(Malawi Kwakya),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Mɛksiko pɛso),
				'one' => q(Mɛksiko pɛso),
				'other' => q(Mɛksiko pɛso),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Malaahyia ringgit),
				'one' => q(Malaahyia ringgit),
				'other' => q(Malaahyia ringgit),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Mozambik Metical),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Mozambik mɛtikaa),
				'one' => q(Mozambik mɛtikaa),
				'other' => q(Mozambik mɛtikaa),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Namibia Dɔla),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naegyeria Naira),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Nikaragua kɔɔdɔba),
				'one' => q(Nikaragua kɔɔdɔba),
				'other' => q(Nikaragua kɔɔdɔba),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Nɔɔwee Krone),
				'one' => q(Nɔɔwee krone),
				'other' => q(Nɔɔwee kroner),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Nepalfoɔ rupee),
				'one' => q(Nepalfoɔ rupee),
				'other' => q(Nepalfoɔ rupee),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(New Zealand Dɔla),
				'one' => q(New Zealand Dɔla),
				'other' => q(New Zealand Dɔla),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Oman rial),
				'one' => q(Oman rial),
				'other' => q(Oman rial),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Panama baaboa),
				'one' => q(Panama baaboa),
				'other' => q(Panama baaboa),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Pɛruvia sol),
				'one' => q(Pɛruvia sol),
				'other' => q(Pɛruvia sol),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Papua New Gini kina),
				'one' => q(Papua New Gini kina),
				'other' => q(Papua New Gini kina),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(Filipine peso),
				'one' => q(Filipine peso),
				'other' => q(Filipine peso),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Pakistanfoɔ rupee),
				'one' => q(Pakistanfoɔ rupee),
				'other' => q(Pakistanfoɔ rupee),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Pɔlihye zloty),
				'one' => q(Pɔlihye zloty),
				'other' => q(Pɔlihye zloty),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Paragayana guarani),
				'one' => q(Paragayana guarani),
				'other' => q(Paragayana guarani),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Kata riyaa),
				'one' => q(Kata riyaa),
				'other' => q(Kata riyaa),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Romania Leu),
				'one' => q(Romania leu),
				'other' => q(Romania lei),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Sɛɛbia dinaa),
				'one' => q(Sɛɛbia dinaa),
				'other' => q(Sɛɛbia dinaa),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rɔhyia rubuu),
				'one' => q(Rɔhyia rubuu),
				'other' => q(Rɔhyia rubuu),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Rewanda Frank),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Saudi Riyal),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Solomon Aeland Dɔla),
				'one' => q(Solomon Aeland Dɔla),
				'other' => q(Solomon Aeland Dɔla),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Seyhyɛls Rupi),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Sudan Dina),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Sudan Pɔn),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Sweden Krona),
				'one' => q(Sweden krona),
				'other' => q(Sweden kronor),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Singapɔɔ dɔla),
				'one' => q(Singapɔɔ dɔla),
				'other' => q(Singapɔɔ dɔla),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(St Helena Pɔn),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leone \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somailia Hyelen),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Suriname dɔla),
				'one' => q(Suriname dɔla),
				'other' => q(Suriname dɔla),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Sudan Anaafoɔ Pɔn),
				'one' => q(Sudan Anaafoɔ Pɔn),
				'other' => q(Sudan Anaafoɔ Pɔn),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Sao Tome ne Principe Dobra \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Sao Tome ne Principe Dobra),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Siria pɔn),
				'one' => q(Siria pɔn),
				'other' => q(Siria pɔn),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Tai bat),
				'one' => q(Tai bat),
				'other' => q(Tai bat),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Tagyikistan somoni),
				'one' => q(Tagyikistan somoni),
				'other' => q(Tagyikistan somoni),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Tɛkmɛstan manat),
				'one' => q(Tɛkmɛstan manat),
				'other' => q(Tɛkmɛstan manat),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tunisia Dina),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Tonga Paʻanga),
				'one' => q(Tonga paʻanga),
				'other' => q(Tonga paʻanga),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Tɛki lira),
				'one' => q(Tɛki lira),
				'other' => q(Tɛki lira),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Trinidad ne Tobago dɔla),
				'one' => q(Trinidad ne Tobago dɔla),
				'other' => q(Trinidad ne Tobago dɔla),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Taewanfoɔ dɔla foforɔ),
				'one' => q(Taelanfoɔ dɔla foforɔ),
				'other' => q(Taewanfoɔ dɔla foforɔ),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Tanzania Hyelen),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Yukren hryvnia),
				'one' => q(Yukren hryvnia),
				'other' => q(Yukren hryvnia),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Uganda Hyelen),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Amɛrika Dɔla),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Yurugueɛ peso),
				'one' => q(Yurugueɛ peso),
				'other' => q(Yurugueɛ peso),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Yusbɛkistan som),
				'one' => q(Yusbɛkistan som),
				'other' => q(Yusbɛkistan som),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Venezuelan bolívar),
				'one' => q(Venezuelan bolívar),
				'other' => q(Venezuelan bolívars),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Viɛtnamfoɔ dɔn),
				'one' => q(Viɛtnamfoɔ dɔn),
				'other' => q(Viɛtnamfoɔ dɔn),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vanuatu vatu),
				'one' => q(Vanuatu vatu),
				'other' => q(Vanuatu vatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Samoa Tala),
				'one' => q(Samoa tala),
				'other' => q(Samoa tala),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Afrika Mfinimfini Sefa),
				'one' => q(Afrika Mfinimfini Sefa),
				'other' => q(Afrika Mfinimfini Sefa),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Karibine Apueeɛ dɔla),
				'one' => q(Karibine Apueeɛ dɔla),
				'other' => q(Karibine Apueeɛ dɔla),
			},
		},
		'XOF' => {
			symbol => 'AAS',
			display_name => {
				'currency' => q(Afrika Atɔeɛ Sefa),
				'one' => q(Afrika Atɔeɛ Sefa),
				'other' => q(Afrika Atɔeɛ Sefa),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP Franc),
				'one' => q(CFP franc),
				'other' => q(CFP francs),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(sika a yɛnnim),
				'one' => q(\(sika a yɛnnim\)),
				'other' => q(\(sika a yɛnnim\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Yɛmɛn rial),
				'one' => q(Yɛmɛn rial),
				'other' => q(Yɛmɛn rial),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Afrika Anaafo Rand),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Zambia Kwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Zambia Kwakya),
				'one' => q(Zambia Kwakya),
				'other' => q(Zambia Kwakya),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Zimbabwe Dɔla),
			},
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Ɔpɛpɔn',
							'Ɔgyefoɔ',
							'Ɔbɛnem',
							'Oforisuo',
							'Kɔtɔnimma',
							'Ayɛwohomumu',
							'Kutawonsa',
							'Ɔsanaa',
							'Ɛbɔ',
							'Ahinime',
							'Obubuo',
							'Ɔpɛnimma'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'Ɔ',
							'Ɔ',
							'Ɔ',
							'O',
							'K',
							'A',
							'K',
							'Ɔ',
							'Ɛ',
							'A',
							'O',
							'Ɔ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Ɔpɛpɔn',
							'Ɔgyefoɔ',
							'Ɔbɛnem',
							'Oforisuo',
							'Kɔtɔnimma',
							'Ayɛwohomumu',
							'Kutawonsa',
							'Ɔsanaa',
							'Ɛbɔ',
							'Ahinime',
							'Obubuo',
							'Ɔpɛnimma'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Ɔpɛpɔn',
							'Ɔgyefoɔ',
							'Ɔbɛnem',
							'Oforisuo',
							'Kɔtɔnimma',
							'Ayɛwohomumu',
							'Kutawonsa',
							'Ɔsanaa',
							'Ɛbɔ',
							'Ahinime',
							'Obubuo',
							'Ɔpɛnimma'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'Ɔ',
							'Ɔ',
							'Ɔ',
							'O',
							'K',
							'A',
							'K',
							'Ɔ',
							'Ɛ',
							'A',
							'O',
							'Ɔ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Ɔpɛpɔn',
							'Ɔgyefoɔ',
							'Ɔbɛnem',
							'Oforisuo',
							'Kɔtɔnimma',
							'Ayɛwohomumu',
							'Kutawonsa',
							'Ɔsanaa',
							'Ɛbɔ',
							'Ahinime',
							'Obubuo',
							'Ɔpɛnimma'
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
						mon => 'Dwo',
						tue => 'Ben',
						wed => 'Wuk',
						thu => 'Yaw',
						fri => 'Fia',
						sat => 'Mem',
						sun => 'Kwe'
					},
					wide => {
						mon => 'Dwoada',
						tue => 'Benada',
						wed => 'Wukuada',
						thu => 'Yawoada',
						fri => 'Fiada',
						sat => 'Memeneda',
						sun => 'Kwasiada'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'D',
						tue => 'B',
						wed => 'W',
						thu => 'Y',
						fri => 'F',
						sat => 'M',
						sun => 'K'
					},
					wide => {
						mon => 'Dwoada',
						tue => 'Benada',
						wed => 'Wukuada',
						thu => 'Yawoada',
						fri => 'Fiada',
						sat => 'Memeneda',
						sun => 'Kwasiada'
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
					abbreviated => {0 => 'Kɔta1',
						1 => 'Kɔta2',
						2 => 'Kɔta3',
						3 => 'Kɔta4'
					},
					wide => {0 => 'Kɔta a ɛdi kan',
						1 => 'kɔta a ɛtɔ so mmienu',
						2 => 'Kɔta a ɛtɔ so mmiɛnsa',
						3 => 'Kɔta a ɛtɔ so nnan'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'Kɔta1',
						1 => 'Kɔta2',
						2 => 'Kɔta3',
						3 => 'Kɔta4'
					},
					wide => {0 => 'Kɔta a ɛdi kan',
						1 => 'kɔta a ɛtɔ so mmienu',
						2 => 'Kɔta a ɛtɔ so mmiɛnsa',
						3 => 'Kɔta a ɛtɔ so nnan'
					},
				},
			},
	} },
);

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'abbreviated' => {
					'am' => q{AN},
					'pm' => q{EW},
				},
			},
			'stand-alone' => {
				'wide' => {
					'am' => q{AN},
					'pm' => q{ANW},
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
			abbreviated => {
				'0' => 'AK',
				'1' => 'KE'
			},
			wide => {
				'0' => 'Ansa Kristo',
				'1' => 'Kristo Akyi'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{EEEE, G y MMMM dd},
			'long' => q{G y MMMM d},
			'medium' => q{G y MMM d},
			'short' => q{GGGGG yy/MM/dd},
		},
		'gregorian' => {
			'full' => q{EEE, MMMM d, y},
			'long' => q{MMMM d, y},
			'medium' => q{MMM d, y},
			'short' => q{M/d/yy},
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
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
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
		'generic' => {
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			MMMMEd => q{E, MMMM d},
			Md => q{M/d},
			hm => q{h:mm a},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yMd => q{y/M/d},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'gregorian' => {
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			MMMMEd => q{E, MMMM d},
			Md => q{M/d},
			hm => q{h:mm a},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yMMMd => q{MMM d, y},
			yMd => q{y/M/d},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
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
			yMMM => {
				M => q{MMM – MMM Y G},
				y => q{MMM y– MMM Y G},
			},
			yMMMd => {
				d => q{MMM d – d, y G},
			},
		},
		'gregorian' => {
			GyM => {
				G => q{M/y G – M/y G},
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			GyMEd => {
				G => q{E, M/d/y G – E, M/d/y G},
				M => q{E, M/d/y – E, M/d/y G},
				d => q{E, M/d/y – E, M/d/y G},
				y => q{E, M/d/y – E, M/d/y G},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, MMM d, y G – E, MMM d, y G},
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			GyMMMd => {
				G => q{MMM d, y G – MMM d, y G},
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			GyMd => {
				G => q{M/d/y G – M/d/y G},
				M => q{M/d/y – M/d/y G},
				d => q{M/d/y – M/d/y G},
				y => q{M/d/y – M/d/y G},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			MMMd => {
				M => q{MMM d – MMM d},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
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
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, y},
				d => q{E, MMM d – E, MMM d, y},
			},
			yMMMd => {
				M => q{MMM d – MMM d, y},
				d => q{MMM d – d, y},
				y => q{MMM d, y – MMM d, y},
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
		regionFormat => q(Berɛ {0}),
		regionFormat => q(Awia ber {0}),
		regionFormat => q(Berɛ susudua {0}),
		'Afghanistan' => {
			long => {
				'standard' => q#Afganistan Berɛ#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abigyan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Akraa#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Ɔlgyese#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Bandwuu#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bisaw#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Blantai#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Budwumbura#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairo#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Kasablanka#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Kyuta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Kɔnakri#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Dakaa#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Gyibuuti#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Dwuba#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kinhyaahya#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Legɔs#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Ngyamena#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Wagadugu#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Afrika Finimfin Berɛ#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Afrika Apueeɛ Berɛ#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Afrika Anaafoɔ Susudua Berɛ#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Afrika Atɔeɛ Awia Berɛ#,
				'generic' => q#Afrika Atɔeɛ Berɛ#,
				'standard' => q#Afrika Atɔeɛ Susudua Berɛ#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alaska Awia Berɛ#,
				'generic' => q#Alaska Berɛ#,
				'standard' => q#Alaska Susudua Berɛ#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amazon Awia Berɛ#,
				'generic' => q#Amazon Berɛ#,
				'standard' => q#Amazon Susudua Berɛ#,
			},
		},
		'America/Anchorage' => {
			exemplarCity => q#Ankɔragyi#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Anguila#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La Riogya#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Rio Gallegɔs#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#San Dwuan#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tukuman#,
		},
		'America/Barbados' => {
			exemplarCity => q#Baabados#,
		},
		'America/Belem' => {
			exemplarCity => q#Bɛlɛm#,
		},
		'America/Belize' => {
			exemplarCity => q#Bɛlisi#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blanc-Sablɔn#,
		},
		'America/Boise' => {
			exemplarCity => q#Bɔisi#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Kambrigyi Bay#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Kampo Grande#,
		},
		'America/Caracas' => {
			exemplarCity => q#Karakas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Katamaaka#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Kayiini#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kemanfo#,
		},
		'America/Chicago' => {
			exemplarCity => q#Kyikago#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Kyihuahua#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Kɔɔdɔba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kɔsta Rika#,
		},
		'America/Creston' => {
			exemplarCity => q#Krɛston#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Kuiaba#,
		},
		'America/Curacao' => {
			exemplarCity => q#Kurukaw#,
		},
		'America/Dawson' => {
			exemplarCity => q#Dɔɔson#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Dɔɔson Kreek#,
		},
		'America/Denver' => {
			exemplarCity => q#Dɛnva#,
		},
		'America/Detroit' => {
			exemplarCity => q#Detrɔit#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dɔmeneka#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Edmɔnton#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#El Salvadɔɔ#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fɔt Nɛlson#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Fɔɔtalɛsa#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Guus Bay#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Grand Tuk#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guwadelup#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guwatemala#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Gayakwuil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Gayana#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Hɛmɔsilo#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Pitɛsbɛgye, Indiana#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tell Siti, Indiana#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Winamak, Indiana#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Indianapɔlis#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Ikaluit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Gyameka#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Dwudwui#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Mɔntisɛlo, Kɛntɛki#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Kralɛngyik#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Lɔs Angyɛlis#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Lowa Prinse Kɔta#,
		},
		'America/Maceio' => {
			exemplarCity => q#Makeio#,
		},
		'America/Marigot' => {
			exemplarCity => q#Marigɔt#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinike#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Matamɔrɔso#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Masatlan#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mɛndɔsa#,
		},
		'America/Menominee' => {
			exemplarCity => q#Mɛnɔminee#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Mɛtlakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mɛksiko Siti#,
		},
		'America/Moncton' => {
			exemplarCity => q#Mɔnktin#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Mɔntirii#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Mantserat#,
		},
		'America/New_York' => {
			exemplarCity => q#New Yɔk#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beula, Nɔf Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Sɛnta, Nɔf Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salɛm, Nɔf Dakota#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ogyinaga#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#Paramaribɔ#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Finisk#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Spain Pɔɔto#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Pɔɔto Velho#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Puɛto Riko#,
		},
		'America/Recife' => {
			exemplarCity => q#Rɛsifɛ#,
		},
		'America/Regina' => {
			exemplarCity => q#Rɛgyina#,
		},
		'America/Resolute' => {
			exemplarCity => q#Rɛsɔlut#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Rio Branko#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Yitokɔtuɔmete#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#St. Baatilemi#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Swift Kɛrɛnt#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tegusigalpa#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Tidwuana#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tɔɔtola#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Winipɛg#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Mfinimfini Awia Berɛ#,
				'generic' => q#Mfinimfini Berɛ#,
				'standard' => q#Mfinimfini Susudua Berɛ#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Apueeɛ Awia Berɛ#,
				'generic' => q#Apueeɛ Berɛ#,
				'standard' => q#Apueeɛ Susudua Berɛ#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Bepɔ Awia Berɛ#,
				'generic' => q#Bepɔ Berɛ#,
				'standard' => q#Bepɔ Susudua Berɛ#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Pasifik Awia Berɛ#,
				'generic' => q#Pasifik Berɛ#,
				'standard' => q#Pasifik Susudua Berɛ#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Kasi#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Makaari#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Mɔɔson#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Paama#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Rotera#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Trɔɔ#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Vɔstɔk#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Apia Awia Berɛ#,
				'generic' => q#Apia Berɛ#,
				'standard' => q#Apia Susudua Berɛ#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arabia Awia Berɛ#,
				'generic' => q#Arabia Berɛ#,
				'standard' => q#Arabia Susudua Berɛ#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Agyɛntina Awia Berɛ#,
				'generic' => q#Agyɛntina Berɛ#,
				'standard' => q#Agyɛntina Susudua Berɛ#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Agyɛntina Atɔeeɛ Awia Berɛ#,
				'generic' => q#Agyɛntina Atɔeeɛ Berɛ#,
				'standard' => q#Agyɛntina Atɔeeɛ Susudua Berɛ#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Aamenia Awia Berɛ#,
				'generic' => q#Aamenia Berɛ#,
				'standard' => q#Aamenia Susudua Berɛ#,
			},
		},
		'Asia/Almaty' => {
			exemplarCity => q#Aamati#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Aman#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktopɛ#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Bankɔk#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Bɛɛrut#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kɔɔkata#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Kyita#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damaskɔso#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Daka#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hɛbrɔn#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Gyakaata#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Gyayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Yerusalem#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamkyatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karakyi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandu#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kukyin#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makasa#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosia#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Kata#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanay#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Kyi Min#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapɔ#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Tɛɛran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Timphu#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Yulanbata#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Yurymki#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vienhyiane#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Yɛkatɛrinbɛg#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlantik Awia Berɛ#,
				'generic' => q#Atlantik Berɛ#,
				'standard' => q#Atlantik Susudua Berɛ#,
			},
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bɛmuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanari#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kepvɛde#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Rɛɛkgyavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Gyɔɔgyia Anaafoɔ#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stanli#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Brɔken Hill#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Daawin#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Eukla#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Hɔbat#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Lɔd Howe#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Mɛɛbɔn#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Pɛɛt#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sidni#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Ɔstrelia Mfinimfini Awia Berɛ#,
				'generic' => q#Ɔstrelia Mfinimfini Berɛ#,
				'standard' => q#Ɔstrelia Mfinimfini Susudua Berɛ#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Ɔstrelia Mfinimfini Atɔeeɛ Awia Berɛ#,
				'generic' => q#Ɔstrelia Mfinimfini Atɔeeɛ Berɛ#,
				'standard' => q#Ɔstrelia Mfinimfini Atɔeeɛ Susudua Berɛ#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Ɔstrelia Apueeɛ Awia Berɛ#,
				'generic' => q#Ɔstrelia Apueeɛ Berɛ#,
				'standard' => q#Ɔstrelia Apueeɛ Susudua Berɛ#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Ɔstrelia Atɔeeɛ Awia Berɛ#,
				'generic' => q#Ɔstrelia Atɔeeɛ Berɛ#,
				'standard' => q#Ɔstrelia Atɔeeɛ Susudua Berɛ#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Asabegyan Awia Berɛ#,
				'generic' => q#Asabegyan Berɛ#,
				'standard' => q#Asabegyan Susudua Berɛ#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azores Awia Berɛ#,
				'generic' => q#Azores Berɛ#,
				'standard' => q#Azores Susudua Berɛ#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladɛhye Awia Berɛ#,
				'generic' => q#Bangladɛhye Berɛ#,
				'standard' => q#Bangladɛhye Susudua Berɛ#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Butan Berɛ#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Bolivia Berɛ#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brasilia Awia Berɛ#,
				'generic' => q#Brasilia Berɛ#,
				'standard' => q#Brasilia Susudua Berɛ#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunei Darusalam Berɛ#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Kepvɛde Awia Berɛ#,
				'generic' => q#Kepvɛde Berɛ#,
				'standard' => q#Kepvɛde Susudua Berɛ#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Kyamoro Susudua Berɛ#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Kyatam Awia Berɛ#,
				'generic' => q#Kyatam Berɛ#,
				'standard' => q#Kyatam Susudua Berɛ#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Kyili Awia Berɛ#,
				'generic' => q#Kyili Berɛ#,
				'standard' => q#Kyili Susudua Berɛ#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Kyaena Awia Berɛ#,
				'generic' => q#Kyaena Berɛ#,
				'standard' => q#Kyaena Susudua Berɛ#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Buronya Aeland Berɛ#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Kokoso Aeland Berɛ#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Kolombia Awia Berɛ#,
				'generic' => q#Kolombia Berɛ#,
				'standard' => q#Kolombia Susudua Berɛ#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Kuk Aeland Awia Fa Berɛ#,
				'generic' => q#Kuk Aeland Berɛ#,
				'standard' => q#Kuk Aeland Susudua Berɛ#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kuba Awia Berɛ#,
				'generic' => q#Kuba Berɛ#,
				'standard' => q#Kuba Susudua Berɛ#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Davis Berɛ#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dumont-d’Urville Berɛ#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Timɔɔ Apueeɛ Berɛ#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Easta Aeland Awia Berɛ#,
				'generic' => q#Easta Aeland Berɛ#,
				'standard' => q#Easta Aeland Susudua Berɛ#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Yikuwedɔ Berɛ#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Amansan Kɔdinatɛde Berɛ#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Baabi a yɛnnim#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amstadam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andɔra#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atene#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Bɛlgrade#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Bɛɛlin#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brɛsɛlse#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukyarɛst#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapɛsh#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Busingye#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Kyisinau#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kɔpɛhangɛne#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dɔblin#,
			long => {
				'daylight' => q#Irelandfoɔ Susudua Berɛ#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gyebrota#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Hɛlsinki#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jɛɛsi#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisbɔn#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ldwubdwana#,
		},
		'Europe/London' => {
			exemplarCity => q#Lɔndɔn#,
			long => {
				'daylight' => q#Ingresi Awia Berɛ#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Lɛsembɛg#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Mɔɔta#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Mɔsko#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgorika#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Saragyevo#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skɔpgye#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sɔfia#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stɔkhɔm#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Veɛna#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Wɔɔsɔɔ#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zurekye#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Yuropu Mfinimfini Awia Berɛ#,
				'generic' => q#Yuropu Mfinimfini Berɛ#,
				'standard' => q#Yuropu Mfinimfini Susudua Berɛ#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Yuropu Apueeɛ Awia Berɛ#,
				'generic' => q#Yuropu Apueeɛ Berɛ#,
				'standard' => q#Yuropu Apueeɛ Susudua Berɛ#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Yuropu Apueeɛ Nohoa Berɛ#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Yuropu Atɔeeɛ Awia Berɛ#,
				'generic' => q#Yuropu Atɔeeɛ Berɛ#,
				'standard' => q#Yuropu Atɔeeɛ Susudua Berɛ#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Fɔkman Aeland Awia Berɛ#,
				'generic' => q#Fɔkman Aeland Berɛ#,
				'standard' => q#Fɔkman Aeland Susudua Berɛ#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Figyi Awia Berɛ#,
				'generic' => q#Figyi Berɛ#,
				'standard' => q#Figyi Susudua Berɛ#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Frɛnkye Gayana Berɛ#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Frɛnkye Anaafoɔ ne Antaatik Berɛ#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwich Mean Berɛ#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagɔs Berɛ#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambier Berɛ#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Gyɔgyea Awia Berɛ#,
				'generic' => q#Gyɔgyea Berɛ#,
				'standard' => q#Gyɔgyea Susudua Berɛ#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Geebɛt Aeland Berɛ#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Greenland Apueeɛ Awia Berɛ#,
				'generic' => q#Greenland Apueeɛ Berɛ#,
				'standard' => q#Greenland Apueeɛ Susudua Berɛ#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Greenland Atɔeɛ Awia Berɛ#,
				'generic' => q#Greenland Atɔeɛ Berɛ#,
				'standard' => q#Greenland Atɔeɛ Susudua Berɛ#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Gɔɔfo Susudua Berɛ#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Gayana Berɛ#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawaii-Aleutian Awia Berɛ#,
				'generic' => q#Hawaii-Aleutian Berɛ#,
				'standard' => q#Hawaii-Aleutian Susudua Berɛ#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hɔnkɔn Awia Berɛ#,
				'generic' => q#Hɔnkɔn Berɛ#,
				'standard' => q#Hɔnkɔn Susudua Berɛ#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hovd Awia Berɛ#,
				'generic' => q#Hovd Berɛ#,
				'standard' => q#Hovd Susudua Berɛ#,
			},
		},
		'India' => {
			long => {
				'standard' => q#India Susudua Berɛ#,
			},
		},
		'Indian/Chagos' => {
			exemplarCity => q#Kyagɔs#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Buronya#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokoso#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Kɔmɔrɔ#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kɛguelɛn#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mɔrihyiɔso#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayote#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#India Po Berɛ#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Indɔkyina Berɛ#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Indɔnehyia Mfinimfini Berɛ#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Indɔnehyia Apueeɛ Berɛ#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Indɔnehyia Atɔeeɛ Berɛ#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Iran Awia Berɛ#,
				'generic' => q#Iran Berɛ#,
				'standard' => q#Iran Susudua Berɛ#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkutsk Awia Berɛ#,
				'generic' => q#Irkutsk Berɛ#,
				'standard' => q#Irkutsk Susudua Berɛ#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Israel Awia Berɛ#,
				'generic' => q#Israel Berɛ#,
				'standard' => q#Israel Susudua Berɛ#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Gyapan Awia Berɛ#,
				'generic' => q#Gyapan Berɛ#,
				'standard' => q#Gyapan Susudua Berɛ#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#Kazakstan Berɛ#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Kazakstan Apueeɛ Berɛ#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Kazakstan Atɔeɛ Berɛ#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Korean Awia Berɛ#,
				'generic' => q#Korean Berɛ#,
				'standard' => q#Korean Susudua Berɛ#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosrae Berɛ#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnoyarsk Awia Berɛ#,
				'generic' => q#Krasnoyarsk Berɛ#,
				'standard' => q#Krasnoyarsk Susudua Berɛ#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kɛɛgestan Berɛ#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Lai Aeland Berɛ#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lɔd Howe Awia Berɛ#,
				'generic' => q#Lɔd Howe Berɛ#,
				'standard' => q#Lɔd Howe Susudua Berɛ#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadan Awia Berɛ#,
				'generic' => q#Magadan Berɛ#,
				'standard' => q#Magadan Susudua Berɛ#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malehyia Berɛ#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Maldives Berɛ#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Makesase Berɛ#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Mahyaa Aeland Berɛ#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mɔrihyiɔso Awia Berɛ#,
				'generic' => q#Mɔrihyiɔso Berɛ#,
				'standard' => q#Mɔrihyiɔso Susudua Berɛ#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mɔɔson Berɛ#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Mɛksiko Pasifik Awia Berɛ#,
				'generic' => q#Mɛksiko Pasifik Berɛ#,
				'standard' => q#Mɛksiko Pasifik Susudua Berɛ#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Yulanbata Awia Berɛ#,
				'generic' => q#Yulanbata Berɛ#,
				'standard' => q#Yulanbata Susudua Berɛ#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Mɔsko Awia Berɛ#,
				'generic' => q#Mɔsko Berɛ#,
				'standard' => q#Mɔsko Susudua Berɛ#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Mayaama Berɛ#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauru Berɛ#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nɛpal Berɛ#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Kaledonia Foforɔ Awia Berɛ#,
				'generic' => q#Kaledonia Foforɔ Berɛ#,
				'standard' => q#Kaledonia Foforɔ Susudua Berɛ#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Ziland Foforɔ Awia Berɛ#,
				'generic' => q#Ziland Foforɔ Berɛ#,
				'standard' => q#Ziland Foforɔ Susudua Berɛ#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Newfoundland Awia Berɛ#,
				'generic' => q#Newfoundland Berɛ#,
				'standard' => q#Newfoundland Susudua Berɛ#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niue Berɛ#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Nɔɔfɔk Aeland Awia Berɛ#,
				'generic' => q#Nɔɔfɔk Aeland Berɛ#,
				'standard' => q#Nɔɔfɔk Aeland Susudua Berɛ#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de Noronha Awia Berɛ#,
				'generic' => q#Fernando de Noronha Berɛ#,
				'standard' => q#Fernando de Noronha Susudua Berɛ#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibirsk Awia Berɛ#,
				'generic' => q#Novosibirsk Berɛ#,
				'standard' => q#Novosibirsk Susudua Berɛ#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omsk Awia Berɛ#,
				'generic' => q#Omsk Berɛ#,
				'standard' => q#Omsk Susudua Berɛ#,
			},
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Aukland#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Kyatam#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Easta#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Figyi#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galapagɔs#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Guadaakanaa#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kwagyaleene#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Magyuro#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Maakesase#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Nɔɔfɔk#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitkairne#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Pɔnpei#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Pɔt Morɛsbi#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Kyuuk#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistan Awia Berɛ#,
				'generic' => q#Pakistan Berɛ#,
				'standard' => q#Pakistan Susudua Berɛ#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palau Berɛ#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papua Gini Foforɔ Berɛ#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paraguae Awia Berɛ#,
				'generic' => q#Paraguae Berɛ#,
				'standard' => q#Paraguae Susudua Berɛ#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peru Awia Berɛ#,
				'generic' => q#Peru Berɛ#,
				'standard' => q#Peru Susudua Berɛ#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Filipin Awia Berɛ#,
				'generic' => q#Filipin Berɛ#,
				'standard' => q#Filipin Susudua Berɛ#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Finise Aeland Berɛ#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#St. Pierre & Miquelon Awia Berɛ#,
				'generic' => q#St. Pierre & Miquelon Berɛ#,
				'standard' => q#St. Pierre & Miquelon Susudua Berɛ#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitkairn Berɛ#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponape Berɛ#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pyongyang Berɛ#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Réunion Berɛ#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rotera Berɛ#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sakhalin Awia Berɛ#,
				'generic' => q#Sakhalin Berɛ#,
				'standard' => q#Sakhalin Susudua Berɛ#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoa Awia Berɛ#,
				'generic' => q#Samoa Berɛ#,
				'standard' => q#Samoa Susudua Berɛ#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seyhyɛl Berɛ#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapɔ Susudua Berɛ#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Solomon Aeland Berɛ#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Gyɔɔgyia Anaafoɔ Berɛ#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Suriname Berɛ#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syowa Berɛ#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahiti Berɛ#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taipei Awia Berɛ#,
				'generic' => q#Taipei Berɛ#,
				'standard' => q#Taipei Susudua Berɛ#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tagyikistan Berɛ#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelau Berɛ#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tonga Awia Berɛ#,
				'generic' => q#Tonga Berɛ#,
				'standard' => q#Tonga Susudua Berɛ#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Kyuuk Berɛ#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Tɛkmɛnistan Awia Berɛ#,
				'generic' => q#Tɛkmɛnistan Berɛ#,
				'standard' => q#Tɛkmɛnistan Susudua Berɛ#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvalu Berɛ#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Yurugwae Awia Berɛ#,
				'generic' => q#Yurugwae Berɛ#,
				'standard' => q#Yurugwae Susudua Berɛ#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Usbɛkistan Awia Berɛ#,
				'generic' => q#Usbɛkistan Berɛ#,
				'standard' => q#Usbɛkistan Susudua Berɛ#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatu Awia Berɛ#,
				'generic' => q#Vanuatu Berɛ#,
				'standard' => q#Vanuatu Susudua Berɛ#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venezuela Berɛ#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Vladivostok Awia Berɛ#,
				'generic' => q#Vladivostok Berɛ#,
				'standard' => q#Vladivostok Susudua Berɛ#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Volgograd Awia Berɛ#,
				'generic' => q#Volgograd Berɛ#,
				'standard' => q#Volgograd Susudua Berɛ#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Vostok Berɛ#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Wake Aeland Berɛ#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wallis ne Futuna Berɛ#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Yakutsk Awia Berɛ#,
				'generic' => q#Yakutsk Berɛ#,
				'standard' => q#Yakutsk Susudua Berɛ#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Yɛkatɛrinbɛg Awia Berɛ#,
				'generic' => q#Yɛkatɛrinbɛg Berɛ#,
				'standard' => q#Yɛkatɛrinbɛg Susudua Berɛ#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Yukɔn Berɛ#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
