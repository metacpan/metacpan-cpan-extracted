=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Qu - Package for language Quechua

=cut

package Locale::CLDR::Locales::Qu;
# This file auto generated from Data\common\main\qu.xml
#	on Sun  7 Jan  2:30:41 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.40.1');

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
					rule => q(minusu →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(chusaq),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← comma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(huk),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(iskay),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kinsa),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(tawa),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(phisqa),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(suqta),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(qanchis),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(pusaq),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(isqun),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(chunka[ →%%spellout-cardinal-with→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←← chunka[ →%%spellout-cardinal-with→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←← pachak[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←← waranqa[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← hunu[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← lluna[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← trilionu[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← kvadrilionu[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0.#=),
				},
				'Inf' => {
					divisor => q(1),
					rule => q(mana usay),
				},
				'NaN' => {
					divisor => q(1),
					rule => q(mana yupay),
				},
				'max' => {
					divisor => q(1),
					rule => q(mana yupay),
				},
			},
		},
		'spellout-cardinal-with' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=-ni-yuq),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-cardinal=-yuq),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(=%spellout-cardinal=-ni-yuq),
				},
				'max' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(=%spellout-cardinal=-ni-yuq),
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
					rule => q(minusu →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=-ñiqin),
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
    } },
);

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'af' => 'Afrikaans Simi',
 				'agq' => 'Aghem Simi',
 				'ak' => 'Akan Simi',
 				'am' => 'Amarico Simi',
 				'ar' => 'Arabe Simi',
 				'arn' => 'Mapuche Simi',
 				'as' => 'Asames Simi',
 				'asa' => 'Asu Simi',
 				'ast' => 'Asturiano Simi',
 				'ay' => 'Aymara Simi',
 				'az' => 'Azerbaiyano Simi',
 				'az@alt=short' => 'Azerí Simi',
 				'ba' => 'Baskir Simi',
 				'bas' => 'Basaa Simi',
 				'be' => 'Bielorruso Simi',
 				'bem' => 'Bemba Simi',
 				'bez' => 'Bena Simi',
 				'bg' => 'Bulgaro Simi',
 				'bm' => 'Bambara Simi',
 				'bn' => 'Bangla Simi',
 				'bo' => 'Tibetano Simi',
 				'br' => 'Breton Simi',
 				'brx' => 'Bodo Simi',
 				'bs' => 'Bosnio Simi',
 				'ca' => 'Catalan Simi',
 				'ccp' => 'Chakma Simi',
 				'ce' => 'Checheno Simi',
 				'ceb' => 'Cebuano Simi',
 				'cgg' => 'Kiga Simi',
 				'chr' => 'Cheroqui Simi',
 				'ckb' => 'Chawpi Kurdo Simi',
 				'ckb@alt=menu' => 'Kurdo Simi, Chawpi',
 				'ckb@alt=variant' => 'Kurdo Simi, Sorani',
 				'co' => 'Corso Simi',
 				'cs' => 'Checo Simi',
 				'cu' => 'Eslavo Eclesiástico Simi',
 				'cy' => 'Gales Simi',
 				'da' => 'Danes Simi',
 				'dav' => 'Taita Simi',
 				'de' => 'Aleman Simi',
 				'dje' => 'Zarma Simi',
 				'doi' => 'Dogri Simi',
 				'dsb' => 'Bajo Sorbio Simi',
 				'dua' => 'Duala Simi',
 				'dv' => 'Divehi Simi',
 				'dyo' => 'Jola-Fonyi Simi',
 				'dz' => 'Butanés Simi',
 				'ebu' => 'Embu Simi',
 				'ee' => 'Ewé Simi',
 				'el' => 'Griego Simi',
 				'en' => 'Ingles Simi',
 				'en_GB@alt=short' => 'Ingles Simi (GB)',
 				'en_US@alt=short' => 'Ingles Simi (US)',
 				'eo' => 'Esperanto Simi',
 				'es' => 'Español Simi',
 				'es_419' => 'Español Simi (Latino América)',
 				'et' => 'Estonio Simi',
 				'eu' => 'Euskera Simi',
 				'ewo' => 'Ewondo Simi',
 				'fa' => 'Persa Simi',
 				'fa_AF' => 'Dari Simi',
 				'ff' => 'Fulah Simi',
 				'fi' => 'Fines Simi',
 				'fil' => 'Filipino Simi',
 				'fo' => 'Feroes Simi',
 				'fr' => 'Frances Simi',
 				'fur' => 'Friulano Simi',
 				'fy' => 'Frison Simi',
 				'ga' => 'Irlandes Simi',
 				'gd' => 'Gaelico Escoces Simi',
 				'gl' => 'Gallego Simi',
 				'gsw' => 'Alsaciano Simi',
 				'gu' => 'Gujarati Simi',
 				'guz' => 'Guzí Simi',
 				'gv' => 'Manés Simi',
 				'ha' => 'Hausa Simi',
 				'haw' => 'Hawaiano Simi',
 				'he' => 'Hebreo Simi',
 				'hi' => 'Hindi Simi',
 				'hmn' => 'Hmong Daw Simi',
 				'hr' => 'Croata Simi',
 				'hsb' => 'Alto Sorbio Simi',
 				'ht' => 'Haitiano Criollo Simi',
 				'hu' => 'Hungaro Simi',
 				'hy' => 'Armenio Simi',
 				'ia' => 'Interlingua Simi',
 				'id' => 'Indonesio Simi',
 				'ig' => 'Igbo Simi',
 				'ii' => 'Yi Simi',
 				'is' => 'Islandes Simi',
 				'it' => 'Italiano Simi',
 				'iu' => 'Inuktitut Simi',
 				'ja' => 'Japones Simi',
 				'jgo' => 'Ngomba Simi',
 				'jmc' => 'Machame Simi',
 				'jv' => 'Javanés Simi',
 				'ka' => 'Georgiano Simi',
 				'kab' => 'Cabilio Simi',
 				'kam' => 'Kamba Simi',
 				'kde' => 'Makonde Simi',
 				'kea' => 'Caboverdiano Simi',
 				'khq' => 'Koyra Chiini Simi',
 				'ki' => 'Kikuyu Simi',
 				'kk' => 'Kazajo Simi',
 				'kkj' => 'Kako Simi',
 				'kl' => 'Groenlandes Simi',
 				'kln' => 'Kalenjin Simi',
 				'km' => 'Khmer Simi',
 				'kn' => 'Kannada Simi',
 				'ko' => 'Coreano Simi',
 				'kok' => 'Konkani Simi',
 				'ks' => 'Cachemir Simi',
 				'ksb' => 'Shambala Simi',
 				'ksf' => 'Bafia Simi',
 				'ksh' => 'Kölsch Simi',
 				'ku' => 'Kurdo Simi',
 				'kw' => 'Córnico Simi',
 				'ky' => 'Kirghiz Simi',
 				'la' => 'Latín Simi',
 				'lag' => 'Langi Simi',
 				'lb' => 'Luxemburgues Simi',
 				'lg' => 'Luganda Simi',
 				'lkt' => 'Lakota Simi',
 				'ln' => 'Lingala Simi',
 				'lo' => 'Lao Simi',
 				'lrc' => 'Luri septentrional Simi',
 				'lt' => 'Lituano Simi',
 				'lu' => 'Luba-Katanga Simi',
 				'luo' => 'Luo Simi',
 				'luy' => 'Luyia Simi',
 				'lv' => 'Leton Simi',
 				'mai' => 'Maithili Simi',
 				'mas' => 'Masai Simi',
 				'mer' => 'Meru Simi',
 				'mfe' => 'Mauriciano Simi',
 				'mg' => 'Malgache Simi',
 				'mgh' => 'Makhuwa-Meetto Simi',
 				'mgo' => 'Metaʼ Simi',
 				'mi' => 'Maori Simi',
 				'mk' => 'Macedonio Simi',
 				'ml' => 'Malayalam Simi',
 				'mn' => 'Mongol Simi',
 				'mni' => 'Manipuri Simi',
 				'moh' => 'Mohawk Simi',
 				'mr' => 'Marathi Simi',
 				'ms' => 'Malayo Simi',
 				'mt' => 'Maltes Simi',
 				'mua' => 'Mundang Simi',
 				'mul' => 'Idiomas M´últiples Simi',
 				'my' => 'Birmano Simi',
 				'mzn' => 'Mazandaraní Simi',
 				'naq' => 'Nama Simi',
 				'nb' => 'Noruego Bokmål Simi',
 				'nd' => 'Ndebele septentrional Simi',
 				'nds' => 'Bajo Alemán Simi',
 				'ne' => 'Nepali Simi',
 				'nl' => 'Neerlandes Simi',
 				'nl_BE' => 'Flamenco Simi',
 				'nmg' => 'Kwasio Ngumba Simi',
 				'nn' => 'Noruego Nynorsk Simi',
 				'nnh' => 'Ngiemboon Simi',
 				'no' => 'Noruego Simi',
 				'nso' => 'Sesotho Sa Leboa Simi',
 				'nus' => 'Nuer Simi',
 				'ny' => 'Nyanja Simi',
 				'nyn' => 'Nyankole Simi',
 				'oc' => 'Occitano Simi',
 				'om' => 'Oromo Simi',
 				'or' => 'Odia Simi',
 				'os' => 'Osetio Simi',
 				'pa' => 'Punyabi Simi',
 				'pap' => 'Papiamento Simi',
 				'pcm' => 'Pidgin Nigeriano Simi',
 				'pl' => 'Polaco Simi',
 				'prg' => 'Prusiano Simi',
 				'ps' => 'Pashto Simi',
 				'pt' => 'Portugues Simi',
 				'qu' => 'Runasimi',
 				'quc' => 'Kʼicheʼ Simi',
 				'rhg' => 'Rohingya Simi',
 				'rm' => 'Romanche Simi',
 				'rn' => 'Rundi Simi',
 				'ro' => 'Rumano Simi',
 				'rof' => 'Rombo Simi',
 				'ru' => 'Ruso Simi',
 				'rw' => 'Kinyarwanda Simi',
 				'rwk' => 'Rwa Simi',
 				'sa' => 'Sanscrito Simi',
 				'sah' => 'Sakha Simi',
 				'saq' => 'Samburu Simi',
 				'sat' => 'Santali Simi',
 				'sbp' => 'Sangu Simi',
 				'sd' => 'Sindhi Simi',
 				'se' => 'Chincha Sami Simi',
 				'seh' => 'Sena Simi',
 				'ses' => 'Koyraboro Senni Simi',
 				'sg' => 'Sango Simi',
 				'shi' => 'Tashelhit Simi',
 				'si' => 'Cingales Simi',
 				'sk' => 'Eslovaco Simi',
 				'sl' => 'Esloveno Simi',
 				'sm' => 'Samoano Simi',
 				'sma' => 'Qulla Sami Simi',
 				'smj' => 'Sami Lule Simi',
 				'smn' => 'Sami Inari Simi',
 				'sms' => 'Sami Skolt Simi',
 				'sn' => 'Shona Simi',
 				'so' => 'Somali Simi',
 				'sq' => 'Albanes Simi',
 				'sr' => 'Serbio Simi',
 				'st' => 'Soto Meridional Simi',
 				'su' => 'Sundanés Simi',
 				'sv' => 'Sueco Simi',
 				'sw' => 'Suajili Simi',
 				'sw_CD' => 'Suajili Simi (Congo (RDC))',
 				'syr' => 'Siriaco Simi',
 				'ta' => 'Tamil Simi',
 				'te' => 'Telugu Simi',
 				'teo' => 'Teso Simi',
 				'tg' => 'Tayiko Simi',
 				'th' => 'Tailandes Simi',
 				'ti' => 'Tigriña Simi',
 				'tk' => 'Turcomano Simi',
 				'tn' => 'Setsuana Simi',
 				'to' => 'Tongano Simi',
 				'tr' => 'Turco Simi',
 				'tt' => 'Tartaro Simi',
 				'twq' => 'Tasawaq Simi',
 				'tzm' => 'Tamazight Simi',
 				'ug' => 'Uigur Simi',
 				'uk' => 'Ucraniano Simi',
 				'und' => 'Mana Riqsisqa Simi',
 				'ur' => 'Urdu Simi',
 				'uz' => 'Uzbeko Simi',
 				'vai' => 'Vai Simi',
 				'vi' => 'Vietnamita Simi',
 				'vo' => 'Volapük Simi',
 				'vun' => 'Vunjo Simi',
 				'wae' => 'Walser Simi',
 				'wo' => 'Wolof Simi',
 				'xh' => 'Isixhosa Simi',
 				'xog' => 'Soga Simi',
 				'yav' => 'Yangben Simi',
 				'yi' => 'Yiddish Simi',
 				'yo' => 'Yoruba Simi',
 				'yue' => 'Cantonés Simi',
 				'yue@alt=menu' => 'Chino Cantonés Simi',
 				'zgh' => 'Bereber Marroquí Estándar Simi',
 				'zh' => 'Chino Simi',
 				'zh@alt=menu' => 'Chino Mandarín Simi',
 				'zh_Hans' => 'Chino Simplificado Simi',
 				'zh_Hans@alt=long' => 'Chino Mandarín Simplificado Simi',
 				'zh_Hant' => 'Chino Tradicional Simi',
 				'zh_Hant@alt=long' => 'Chino Mandarín Tradicional Simi',
 				'zu' => 'Isizulu Simi',
 				'zxx' => 'Manaraq simi yachana',

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
			'Arab' => 'Arabe Simi',
 			'Armn' => 'Armenio Simi',
 			'Beng' => 'Bangla Simi',
 			'Bopo' => 'Bopomofo Simi',
 			'Brai' => 'Braile',
 			'Cyrl' => 'Cirilico',
 			'Deva' => 'Devanagari',
 			'Ethi' => 'Etiope',
 			'Geor' => 'Georgiano',
 			'Grek' => 'Griego Simi',
 			'Gujr' => 'Gujarati Simi',
 			'Guru' => 'Gurmukhi Simi',
 			'Hanb' => 'Han with Bopomofo',
 			'Hang' => 'Hangul',
 			'Hani' => 'Han',
 			'Hans' => 'Simplificado',
 			'Hans@alt=stand-alone' => 'Simplificado Han',
 			'Hant' => 'Tradicional',
 			'Hant@alt=stand-alone' => 'Tradicional Han',
 			'Hebr' => 'Hebreo Simi',
 			'Hira' => 'Hiragana',
 			'Hrkt' => 'Japones silabico sananpakuna',
 			'Jamo' => 'Jamo',
 			'Jpan' => 'Japones Simi',
 			'Kana' => 'Katakana',
 			'Khmr' => 'Khmer',
 			'Knda' => 'Kannada Simi',
 			'Kore' => 'Coreano Simi',
 			'Laoo' => 'Lao Simi',
 			'Latn' => 'Latin Simi',
 			'Mlym' => 'Malayalam Simi',
 			'Mong' => 'Mongol Simi',
 			'Mymr' => 'Myanmar',
 			'Orya' => 'Odia Simi',
 			'Sinh' => 'Cingales Simi',
 			'Taml' => 'Tamil Simi',
 			'Telu' => 'Tegulu Simi',
 			'Thaa' => 'Thaana Simi',
 			'Thai' => 'Tailandes Simi',
 			'Tibt' => 'Tibetano Simi',
 			'Zmth' => 'Matimatica Willay',
 			'Zsye' => 'Emoji',
 			'Zsym' => 'Unanchakuna',
 			'Zxxx' => 'Mana qillqasqa',
 			'Zyyy' => 'Common Simi',
 			'Zzzz' => 'Mana yachasqa Qillqa',

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
			'001' => 'Pacha',
 			'002' => 'Africa',
 			'003' => 'Norte America',
 			'005' => 'Sud America',
 			'009' => 'Oceania',
 			'011' => 'Africa Occidental',
 			'013' => 'America Central',
 			'014' => 'Africa Oriental',
 			'015' => 'Africa del Norte',
 			'017' => 'Africa Media',
 			'018' => 'Sud Africa',
 			'019' => 'America',
 			'021' => 'America del Norte',
 			'029' => 'Caribe',
 			'030' => 'Asia Oriental',
 			'034' => 'Asia del Sur',
 			'035' => 'Sureste de Asia',
 			'039' => 'Europa del Sur',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Región Micronesia',
 			'061' => 'Polinesia',
 			'142' => 'Asia',
 			'143' => 'Asia Central',
 			'145' => 'Asia Occidental',
 			'150' => 'Europa',
 			'151' => 'Europa Oriental',
 			'154' => 'Europa del Norte',
 			'155' => 'Europa Occidental',
 			'202' => 'Africa Sub-Sahariana',
 			'419' => 'AmericaLatina',
 			'AC' => 'Islas Ascensión',
 			'AD' => 'Andorra',
 			'AE' => 'Emiratos Árabes Unidos',
 			'AF' => 'Afganistán',
 			'AG' => 'Antigua y Barbuda',
 			'AI' => 'Anguila',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antártida',
 			'AR' => 'Argentina',
 			'AS' => 'Samoa Americana',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Islas Åland',
 			'AZ' => 'Azerbaiyán',
 			'BA' => 'Bosnia y Herzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Bélgica',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Baréin',
 			'BI' => 'Burundi',
 			'BJ' => 'Benín',
 			'BL' => 'San Bartolomé',
 			'BM' => 'Bermudas',
 			'BN' => 'Brunéi',
 			'BO' => 'Bolivia',
 			'BQ' => 'Bonaire',
 			'BR' => 'Brasil',
 			'BS' => 'Bahamas',
 			'BT' => 'Bután',
 			'BV' => 'Isla Bouvet',
 			'BW' => 'Botsuana',
 			'BY' => 'Belarús',
 			'BZ' => 'Belice',
 			'CA' => 'Canadá',
 			'CC' => 'Islas Cocos',
 			'CD' => 'Congo (RDC)',
 			'CF' => 'República Centroafricana',
 			'CG' => 'Congo',
 			'CH' => 'Suiza',
 			'CI' => 'Côte d’Ivoire',
 			'CK' => 'Islas Cook',
 			'CL' => 'Chile',
 			'CM' => 'Camerún',
 			'CN' => 'China',
 			'CO' => 'Colombia',
 			'CP' => 'Isla Clipperton',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Cabo Verde',
 			'CW' => 'Curazao',
 			'CX' => 'Isla Christmas',
 			'CY' => 'Chipre',
 			'CZ' => 'Chequia',
 			'CZ@alt=variant' => 'República Checa',
 			'DE' => 'Alemania',
 			'DG' => 'Diego García',
 			'DJ' => 'Yibuti',
 			'DK' => 'Dinamarca',
 			'DM' => 'Dominica',
 			'DO' => 'República Dominicana',
 			'DZ' => 'Argelia',
 			'EA' => 'Ceuta y Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Egipto',
 			'EH' => 'Sahara Occidental',
 			'ER' => 'Eritrea',
 			'ES' => 'España',
 			'ET' => 'Etiopía',
 			'EU' => 'Union Europea',
 			'EZ' => 'Eurozona',
 			'FI' => 'Finlandia',
 			'FJ' => 'Fiyi',
 			'FK' => 'Islas Malvinas',
 			'FM' => 'Micronesia',
 			'FO' => 'Islas Feroe',
 			'FR' => 'Francia',
 			'GA' => 'Gabón',
 			'GB' => 'Reino Unido',
 			'GD' => 'Granada',
 			'GE' => 'Georgia',
 			'GF' => 'Guayana Francesa',
 			'GG' => 'Guernesey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Groenlandia',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadalupe',
 			'GQ' => 'Guinea Ecuatorial',
 			'GR' => 'Grecia',
 			'GS' => 'Georgia del Sur e Islas Sandwich del Sur',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bisáu',
 			'GY' => 'Guyana',
 			'HK' => 'Hong Kong RAE China',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Islas Heard y McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Croacia',
 			'HT' => 'Haití',
 			'HU' => 'Hungría',
 			'IC' => 'Islas Canarias',
 			'ID' => 'Indonesia',
 			'IE' => 'Irlanda',
 			'IL' => 'Israel',
 			'IM' => 'Isla de Man',
 			'IN' => 'India',
 			'IO' => 'Territorio Británico del Océano Índico',
 			'IQ' => 'Irak',
 			'IR' => 'Irán',
 			'IS' => 'Islandia',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaica',
 			'JO' => 'Jordania',
 			'JP' => 'Japón',
 			'KE' => 'Kenia',
 			'KG' => 'Kirguistán',
 			'KH' => 'Camboya',
 			'KI' => 'Kiribati',
 			'KM' => 'Comoras',
 			'KN' => 'San Cristóbal y Nieves',
 			'KP' => 'Corea del Norte',
 			'KR' => 'Corea del Sur',
 			'KW' => 'Kuwait',
 			'KY' => 'Islas Caimán',
 			'KZ' => 'Kazajistán',
 			'LA' => 'Laos',
 			'LB' => 'Líbano',
 			'LC' => 'Santa Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesoto',
 			'LT' => 'Lituania',
 			'LU' => 'Luxemburgo',
 			'LV' => 'Letonia',
 			'LY' => 'Libia',
 			'MA' => 'Marruecos',
 			'MC' => 'Mónaco',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'San Martín',
 			'MG' => 'Madagascar',
 			'MH' => 'Islas Marshall',
 			'MK' => 'Macedonia del Norte',
 			'ML' => 'Malí',
 			'MM' => 'Myanmar',
 			'MN' => 'Mongolia',
 			'MO' => 'Macao RAE China',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Islas Marianas del Norte',
 			'MQ' => 'Martinica',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauricio',
 			'MV' => 'Maldivas',
 			'MW' => 'Malawi',
 			'MX' => 'México',
 			'MY' => 'Malasia',
 			'MZ' => 'Mozambique',
 			'NA' => 'Namibia',
 			'NC' => 'Nueva Caledonia',
 			'NE' => 'Níger',
 			'NF' => 'Isla Norfolk',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Países Bajos',
 			'NO' => 'Noruega',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nueva Zelanda',
 			'OM' => 'Omán',
 			'PA' => 'Panamá',
 			'PE' => 'Perú',
 			'PF' => 'Polinesia Francesa',
 			'PG' => 'Papúa Nueva Guinea',
 			'PH' => 'Filipinas',
 			'PK' => 'Pakistán',
 			'PL' => 'Polonia',
 			'PM' => 'San Pedro y Miquelón',
 			'PN' => 'Islas Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Palestina Kamachikuq',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Palaos',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'Oceanía Periférica',
 			'RE' => 'Reunión',
 			'RO' => 'Rumania',
 			'RS' => 'Serbia',
 			'RU' => 'Rusia',
 			'RW' => 'Ruanda',
 			'SA' => 'Arabia Saudí',
 			'SB' => 'Islas Salomón',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudán',
 			'SE' => 'Suecia',
 			'SG' => 'Singapur',
 			'SH' => 'Santa Elena',
 			'SI' => 'Eslovenia',
 			'SJ' => 'Svalbard y Jan Mayen',
 			'SK' => 'Eslovaquia',
 			'SL' => 'Sierra Leona',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Surinam',
 			'SS' => 'Sudán del Sur',
 			'ST' => 'Santo Tomé y Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Siria',
 			'SZ' => 'Suazilandia',
 			'TA' => 'Tristán de Acuña',
 			'TC' => 'Islas Turcas y Caicos',
 			'TD' => 'Chad',
 			'TF' => 'Territorios Australes Franceses',
 			'TG' => 'Togo',
 			'TH' => 'Tailandia',
 			'TJ' => 'Tayikistán',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TM' => 'Turkmenistán',
 			'TN' => 'Túnez',
 			'TO' => 'Tonga',
 			'TR' => 'Turquía',
 			'TT' => 'Trinidad y Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwán',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ucrania',
 			'UG' => 'Uganda',
 			'UM' => 'Islas menores alejadas de los EE.UU.',
 			'UN' => 'Naciones Unidas',
 			'US' => 'Estados Unidos',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistán',
 			'VA' => 'Santa Sede (Ciudad del Vaticano)',
 			'VC' => 'San Vicente y las Granadinas',
 			'VE' => 'Venezuela',
 			'VG' => 'Islas Vírgenes Británicas',
 			'VI' => 'EE.UU. Islas Vírgenes',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis y Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Seudo-Acentos',
 			'XB' => 'Seudo-Bidi',
 			'XK' => 'Kosovo',
 			'YE' => 'Yemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Sudáfrica',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabue',
 			'ZZ' => 'Mana yachasqa Suyu',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Intiwatana',
 			'cf' => 'Imayna Qullqi kaynin',
 			'collation' => 'Ñiqinchana',
 			'currency' => 'qullqi',
 			'hc' => 'Ciclo de Horas (12 vs 24)',
 			'lb' => 'Siqi paway kaynin',
 			'ms' => 'Tupuy Kamay',
 			'numbers' => 'Yupaykuna',

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
 				'buddhist' => q{Budista Intiwatana},
 				'chinese' => q{Chino Intiwatana},
 				'dangi' => q{Dangi Intiwatana},
 				'ethiopic' => q{Etiope Intiwatana},
 				'gregorian' => q{Gregoriano Intiwatana},
 				'hebrew' => q{Hebreo Intiwatana},
 				'islamic' => q{Islamico Intiwatana},
 				'iso8601' => q{ISO-8601 Intiwatana},
 				'japanese' => q{Japones Intiwatana},
 				'persian' => q{Persa Intiwatana},
 				'roc' => q{Minguo Intiwatana},
 			},
 			'cf' => {
 				'account' => q{Yupana Qullqi imayna kaynin},
 				'standard' => q{Estandar nisqa qullqi imayna kaynin},
 			},
 			'collation' => {
 				'ducet' => q{Ñawpaqchasqa Unicode Nisqa Ñiqinchana},
 				'search' => q{Llapanpaq maskana},
 				'standard' => q{Estandar nisqa Ñiqinchana},
 			},
 			'hc' => {
 				'h11' => q{12 hora kaynin (0–11)},
 				'h12' => q{12 hora kaynin (1–12)},
 				'h23' => q{24 hora kaynin (0–23)},
 				'h24' => q{24 hora kaynin (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Siqi paway chinkachiy kaynin},
 				'normal' => q{Siqi paway Normal kaynin},
 				'strict' => q{Siqi paway Chiqa kaynin},
 			},
 			'ms' => {
 				'metric' => q{Metrico Kamay},
 				'uksystem' => q{Metrico Ingles Kamay},
 				'ussystem' => q{Metrico Americano Kamay},
 			},
 			'numbers' => {
 				'arab' => q{Arabe Sananpakuna},
 				'arabext' => q{Arabe Mirachisqa Sananpakuna},
 				'armn' => q{Armenio Sananpakuna},
 				'armnlow' => q{Armenio Uchuy Sananpakuna},
 				'beng' => q{Bangla Sananpakuna},
 				'deva' => q{Devanagari Sananpakuna},
 				'ethi' => q{Etiope Sananpakuna},
 				'fullwide' => q{Llapan kinray Sananpakuna},
 				'geor' => q{Gregoriano Yupaykuna},
 				'grek' => q{Griego Yupaykuna},
 				'greklow' => q{Griego Uchuy Yupaykuna},
 				'gujr' => q{Gujarati Sananpakuna},
 				'guru' => q{Gurmukhi Sananpakuna},
 				'hanidec' => q{Chunkachasqa Chino Yupaykuna},
 				'hans' => q{Uchuyachusqa Chino Yupaypakuna},
 				'hansfin' => q{Uchuyachisqa Qullqi Chino Yupaypakuna},
 				'hant' => q{Kikin Chino Yupaypakuna},
 				'hantfin' => q{Kikin Qullqi Chino Yupaypakuna},
 				'hebr' => q{Hebreo Yupaykuna},
 				'jpan' => q{Japones Yupaykuna},
 				'jpanfin' => q{Japones Qullqi Yupaykuna},
 				'khmr' => q{Khmer Sananpakuna},
 				'knda' => q{Kannada Sananpakuna},
 				'laoo' => q{Lao Sananpakuna},
 				'latn' => q{Occidental Sananpakuna},
 				'mlym' => q{Malayalam Sananpakuna},
 				'mymr' => q{Myanmar Sananpakuna},
 				'orya' => q{Odia Sananpakuna},
 				'roman' => q{Romano Sananpakuna},
 				'romanlow' => q{Roman Uchuy Yupaykuna},
 				'taml' => q{Kikin Tamil Yupaykuna},
 				'tamldec' => q{Tamil Sananpakuna},
 				'telu' => q{Telegu Sananpakuna},
 				'thai' => q{Thai Sananpakuna},
 				'tibt' => q{Tibetano Sananpakuna},
 			},

		}
	},
);

has 'text_orientation' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { return {
			lines => 'top-to-bottom',
			characters => 'left-to-right',
		}}
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
			auxiliary => qr{[á à ă â å ä ã ā æ b c ç d e é è ĕ ê ë ē f g í ì ĭ î ï ī j o ó ò ŏ ô ö ø ō œ r ú ù ŭ û ü ū v x ÿ z]},
			index => ['A', '{Ch}', 'H', 'I', 'K', 'L', '{Ll}', 'M', 'N', 'Ñ', 'P', 'Q', 'S', 'T', 'U', 'W', 'Y'],
			main => qr{[a {ch} {chʼ} h i k {kʼ} l {ll} m n ñ p {pʼ} q {qʼ} s t {tʼ} u w y]},
			numbers => qr{[\- ‑ , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ ‑ – — , ; \: ! ? . … ' ‘ ’ " “ ” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', '{Ch}', 'H', 'I', 'K', 'L', '{Ll}', 'M', 'N', 'Ñ', 'P', 'Q', 'S', 'T', 'U', 'W', 'Y'], };
},
);


has 'duration_units' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { {
				hm => 'h:mm',
				hms => 'h:mm:ss',
				ms => 'm:ss',
			} }
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(kibi{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(kibi{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(mebi{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(mebi{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(gibi{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(gibi{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(tebi{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(tebi{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(pebi{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(pebi{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(exbi{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(exbi{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(zebi{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(zebi{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(yobe{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(yobe{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(deci{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(deci{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(pico{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(pico{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(femto{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(femto{0}),
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
						'1' => q(centi{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(centi{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(zepto{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(zepto{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(yocto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(yocto{0}),
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
						'1' => q(micro{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(micro{0}),
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
						'1' => q(deka{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(deka{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(tera{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(tera{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(peta{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(peta{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(exa{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(exa{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(hecto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hecto{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(zetta{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(zetta{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(yotta{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(yotta{0}),
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
						'1' => q(mega{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(mega{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(giga{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(giga{0}),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metros por segundo cuadrado),
						'other' => q({0} metros por segundo cuadrado),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metros por segundo cuadrado),
						'other' => q({0} metros por segundo cuadrado),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(acre),
						'other' => q({0} acre),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(acre),
						'other' => q({0} acre),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunam),
						'other' => q({0} dunam),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunam),
						'other' => q({0} dunam),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hectárea),
						'other' => q({0} hectárea),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hectárea),
						'other' => q({0} hectárea),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(centímetro cuadrado),
						'other' => q({0} centímetro cuadrado),
						'per' => q({0}/centímetro cuadrado),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(centímetro cuadrado),
						'other' => q({0} centímetro cuadrado),
						'per' => q({0}/centímetro cuadrado),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(pie cuadrado),
						'other' => q({0} pie cuadrado),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(pie cuadrado),
						'other' => q({0} pie cuadrado),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(pulgada cuadrada),
						'other' => q({0} pulgada cuadrada),
						'per' => q({0}/pulgada cuadrada),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(pulgada cuadrada),
						'other' => q({0} pulgada cuadrada),
						'per' => q({0}/pulgada cuadrada),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kilómetro cuadrado),
						'other' => q({0} kilómetro cuadrado),
						'per' => q({0}/kilómetro cuadrado),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kilómetro cuadrado),
						'other' => q({0} kilómetro cuadrado),
						'per' => q({0}/kilómetro cuadrado),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(metro cuadrado),
						'other' => q({0} metro cuadrado),
						'per' => q({0}/metro cuadrado),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(metro cuadrado),
						'other' => q({0} metro cuadrado),
						'per' => q({0}/metro cuadrado),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(milla cuadrada),
						'other' => q({0} milla cuadrada),
						'per' => q({0}/milla cuadrada),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(milla cuadrada),
						'other' => q({0} milla cuadrada),
						'per' => q({0}/milla cuadrada),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yarda cuadrada),
						'other' => q({0} yarda cuadrada),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yarda cuadrada),
						'other' => q({0} yarda cuadrada),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(imakuna),
						'other' => q({0} imakuna),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(imakuna),
						'other' => q({0} imakuna),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(partes por millon),
						'other' => q({0} partes por millon),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(partes por millon),
						'other' => q({0} partes por millon),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(litros por 100 kilometros),
						'other' => q({0} litros por 100 kilometros),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(litros por 100 kilometros),
						'other' => q({0} litros por 100 kilometros),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(siglos),
						'other' => q({0} siglos),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(siglos),
						'other' => q({0} siglos),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(punchaw),
						'other' => q({0} punchaw),
						'per' => q({0}/p),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(punchaw),
						'other' => q({0} punchaw),
						'per' => q({0}/p),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(décadas),
						'other' => q({0} décadas),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(décadas),
						'other' => q({0} décadas),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(hora),
						'other' => q({0} hora),
						'per' => q({0}/h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(hora),
						'other' => q({0} hora),
						'per' => q({0}/h),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(microsegundo),
						'other' => q({0} microsegundo),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(microsegundo),
						'other' => q({0} microsegundo),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisegundo),
						'other' => q({0} milisegundo),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisegundo),
						'other' => q({0} milisegundo),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minuto),
						'other' => q({0} minuto),
						'per' => q({0} por minuto),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minuto),
						'other' => q({0} minuto),
						'per' => q({0} por minuto),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(killa),
						'other' => q({0} killa),
						'per' => q({0}/k),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(killa),
						'other' => q({0} killa),
						'per' => q({0}/k),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosegundo),
						'other' => q({0} nanosegundo),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosegundo),
						'other' => q({0} nanosegundo),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(segundo),
						'other' => q({0} segundo),
						'per' => q({0} por segundo),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(segundo),
						'other' => q({0} segundo),
						'per' => q({0} por segundo),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(semana),
						'other' => q({0} semana),
						'per' => q({0} por semana),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(semana),
						'other' => q({0} semana),
						'per' => q({0} por semana),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(wata),
						'other' => q({0} wata),
						'per' => q({0} sapa wata),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(wata),
						'other' => q({0} wata),
						'per' => q({0} sapa wata),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowatt-ura sapa 100 kilometrokuna),
						'other' => q({0} kilowatt-ura sapa 100 kilometrokuna),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowatt-ura sapa 100 kilometrokuna),
						'other' => q({0} kilowatt-ura sapa 100 kilometrokuna),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(chiku),
						'other' => q({0} chiku),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(chiku),
						'other' => q({0} chiku),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(puntos por centímetro),
						'other' => q({0} puntos por centímetro),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(puntos por centímetro),
						'other' => q({0} puntos por centímetro),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(puntos por pulgada),
						'other' => q({0} puntos por pulgada),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(puntos por pulgada),
						'other' => q({0} puntos por pulgada),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(tipográfico em),
						'other' => q({0} tipográfico em),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(tipográfico em),
						'other' => q({0} tipográfico em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapixels),
						'other' => q({0} megapixels),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapixels),
						'other' => q({0} megapixels),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pixels),
						'other' => q({0} pixels),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pixels),
						'other' => q({0} pixels),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(pixels por centímetro),
						'other' => q({0} pixels por centímetro),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(pixels por centímetro),
						'other' => q({0} pixels por centímetro),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pixels por pulgada),
						'other' => q({0} pixels por pulgada),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pixels por pulgada),
						'other' => q({0} pixels por pulgada),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(unidades astronómicas),
						'other' => q({0} unidades astronómicas),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(unidades astronómicas),
						'other' => q({0} unidades astronómicas),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(centímetro),
						'other' => q({0} centímetro),
						'per' => q({0}/centímetro),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(centímetro),
						'other' => q({0} centímetro),
						'per' => q({0}/centímetro),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(decímetro),
						'other' => q({0} decímetro),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(decímetro),
						'other' => q({0} decímetro),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(radio de la tierra),
						'other' => q({0} radio de la tierra),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(radio de la tierra),
						'other' => q({0} radio de la tierra),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fathoms),
						'other' => q({0} fathoms),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fathoms),
						'other' => q({0} fathoms),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(pie),
						'other' => q({0} pie),
						'per' => q({0}/pie),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(pie),
						'other' => q({0} pie),
						'per' => q({0}/pie),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlongs),
						'other' => q({0} furlongs),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlongs),
						'other' => q({0} furlongs),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(pulgada),
						'other' => q({0} pulgada),
						'per' => q({0}/pulgada),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(pulgada),
						'other' => q({0} pulgada),
						'per' => q({0}/pulgada),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilómetro),
						'other' => q({0} kilómetro),
						'per' => q({0}/km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilómetro),
						'other' => q({0} kilómetro),
						'per' => q({0}/km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(años luz),
						'other' => q({0} años luz),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(años luz),
						'other' => q({0} años luz),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metro),
						'other' => q({0} metro),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metro),
						'other' => q({0} metro),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(micrómetro),
						'other' => q({0} micrómetro),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(micrómetro),
						'other' => q({0} micrómetro),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(milla),
						'other' => q({0} milla),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(milla),
						'other' => q({0} milla),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(milla escandinava),
						'other' => q({0} milla escandinava),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(milla escandinava),
						'other' => q({0} milla escandinava),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(milímetro),
						'other' => q({0} milímetro),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(milímetro),
						'other' => q({0} milímetro),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanómetro),
						'other' => q({0} nanómetro),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanómetro),
						'other' => q({0} nanómetro),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(millas naúticas),
						'other' => q({0} millas naúticas),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(millas naúticas),
						'other' => q({0} millas naúticas),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsecs),
						'other' => q({0} parsecs),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsecs),
						'other' => q({0} parsecs),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(picómetro),
						'other' => q({0} picómetro),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(picómetro),
						'other' => q({0} picómetro),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(puntos),
						'other' => q({0} puntos),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(puntos),
						'other' => q({0} puntos),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(radiación solar),
						'other' => q({0} radiación solar),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(radiación solar),
						'other' => q({0} radiación solar),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yarda),
						'other' => q({0} yarda),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yarda),
						'other' => q({0} yarda),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(candela),
						'other' => q({0} candela),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(candela),
						'other' => q({0} candela),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lumen),
						'other' => q({0} lumen),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lumen),
						'other' => q({0} lumen),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(grano),
						'other' => q({0} grano),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(grano),
						'other' => q({0} grano),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(catorce libras),
						'other' => q({0} catorce libras),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(catorce libras),
						'other' => q({0} catorce libras),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} sapa {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} sapa {1}),
					},
					# Long Unit Identifier
					'power2' => {
						'other' => q(metro cuadrado {0}),
					},
					# Core Unit Identifier
					'power2' => {
						'other' => q(metro cuadrado {0}),
					},
					# Long Unit Identifier
					'power3' => {
						'other' => q(metro cubico {0}),
					},
					# Core Unit Identifier
					'power3' => {
						'other' => q(metro cubico {0}),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(pulgadas por mercurio),
						'other' => q({0} pulgadas por mercurio),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(pulgadas por mercurio),
						'other' => q({0} pulgadas por mercurio),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(milimetros de mercurio),
						'other' => q({0} milimetros de mercurio),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(milimetros de mercurio),
						'other' => q({0} milimetros de mercurio),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(libras por pulgada cuadrada),
						'other' => q({0} libras por pulgada cuadrada),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(libras por pulgada cuadrada),
						'other' => q({0} libras por pulgada cuadrada),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(libras-pies),
						'other' => q({0} libras-pies),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(libras-pies),
						'other' => q({0} libras-pies),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acre-pie),
						'other' => q({0} acre-pie),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acre-pie),
						'other' => q({0} acre-pie),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barril),
						'other' => q({0} barril),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barril),
						'other' => q({0} barril),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(bushels),
						'other' => q({0} bushels),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bushels),
						'other' => q({0} bushels),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(centilitro),
						'other' => q({0} centilitro),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(centilitro),
						'other' => q({0} centilitro),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(centímetro cúbico),
						'other' => q({0} centímetro cúbico),
						'per' => q({0}/centímetro cúbico),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(centímetro cúbico),
						'other' => q({0} centímetro cúbico),
						'per' => q({0}/centímetro cúbico),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(pie cúbico),
						'other' => q({0} pie cúbico),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(pie cúbico),
						'other' => q({0} pie cúbico),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(pulgada cúbica),
						'other' => q({0} pulgada cúbica),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(pulgada cúbica),
						'other' => q({0} pulgada cúbica),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kilómetro cúbico),
						'other' => q({0} kilómetro cúbico),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kilómetro cúbico),
						'other' => q({0} kilómetro cúbico),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(metro cúbico),
						'other' => q({0} metro cúbico),
						'per' => q({0}/metro cúbico),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(metro cúbico),
						'other' => q({0} metro cúbico),
						'per' => q({0}/metro cúbico),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(milla cúbica),
						'other' => q({0} milla cúbica),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(milla cúbica),
						'other' => q({0} milla cúbica),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yarda cúbica),
						'other' => q({0} yarda cúbica),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yarda cúbica),
						'other' => q({0} yarda cúbica),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(taza),
						'other' => q({0} taza),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(taza),
						'other' => q({0} taza),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(taza métrica),
						'other' => q({0} taza métrica),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(taza métrica),
						'other' => q({0} taza métrica),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(decilitro),
						'other' => q({0} decilitro),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(decilitro),
						'other' => q({0} decilitro),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(cuchara para postes),
						'other' => q({0} cuchara para postres),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(cuchara para postes),
						'other' => q({0} cuchara para postres),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(Imp. cuchara para postres),
						'other' => q({0} Imp. cuchara para postres),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(Imp. cuchara para postres),
						'other' => q({0} Imp. cuchara para postres),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(trago),
						'other' => q({0} trago),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(trago),
						'other' => q({0} trago),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(gota),
						'other' => q({0} gota),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(gota),
						'other' => q({0} gota),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(Onza líquida),
						'other' => q({0} US Onza líquida),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(Onza líquida),
						'other' => q({0} US Onza líquida),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(UK Onza líquida),
						'other' => q({0} UK Onza líquida),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(UK Onza líquida),
						'other' => q({0} UK Onza líquida),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(galón),
						'other' => q({0} US galón),
						'per' => q({0}/US galón),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(galón),
						'other' => q({0} US galón),
						'per' => q({0}/US galón),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(UK galón),
						'other' => q({0} UK galón),
						'per' => q({0}/UK galón),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(UK galón),
						'other' => q({0} UK galón),
						'per' => q({0}/UK galón),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hectolitro),
						'other' => q({0} hectolitro),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hectolitro),
						'other' => q({0} hectolitro),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(medida),
						'other' => q({0} medida),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(medida),
						'other' => q({0} medida),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litro),
						'other' => q({0} litro),
						'per' => q({0}/litro),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litro),
						'other' => q({0} litro),
						'per' => q({0}/litro),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megalitro),
						'other' => q({0} megalitro),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megalitro),
						'other' => q({0} megalitro),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mililitro),
						'other' => q({0} mililitro),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mililitro),
						'other' => q({0} mililitro),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(pizca),
						'other' => q({0} pizca),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(pizca),
						'other' => q({0} pizca),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pinta),
						'other' => q({0} pinta),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pinta),
						'other' => q({0} pinta),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(pinta métrica),
						'other' => q({0} pinta métrica),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(pinta métrica),
						'other' => q({0} pinta métrica),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(cuarto),
						'other' => q({0} cuarto),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(cuarto),
						'other' => q({0} cuarto),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(Imp. cuarta),
						'other' => q({0} Imp. cuarta),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(Imp. cuarta),
						'other' => q({0} Imp. cuarta),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(cucharada),
						'other' => q({0} cucharada),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(cucharada),
						'other' => q({0} cucharada),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(cucharadita),
						'other' => q({0} cucharadita),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(cucharadita),
						'other' => q({0} cucharadita),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(punchaw),
						'other' => q({0} p),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(punchaw),
						'other' => q({0} p),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(hora),
						'other' => q({0} h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(hora),
						'other' => q({0} h),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisegundo),
						'other' => q({0} ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisegundo),
						'other' => q({0} ms),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(killa),
						'other' => q({0} k),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(killa),
						'other' => q({0} k),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(segundo),
						'other' => q({0} s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(segundo),
						'other' => q({0} s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(semana),
						'other' => q({0} s),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(semana),
						'other' => q({0} s),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(wata),
						'other' => q({0} w),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(wata),
						'other' => q({0} w),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(cm),
						'other' => q({0} cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(cm),
						'other' => q({0} cm),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(km),
						'other' => q({0}km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(km),
						'other' => q({0}km),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metro),
						'other' => q({0} m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metro),
						'other' => q({0} m),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(mm),
						'other' => q({0} mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(mm),
						'other' => q({0} mm),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litro),
						'other' => q({0} litro),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litro),
						'other' => q({0} litro),
					},
				},
				'short' => {
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metros/sec²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metros/sec²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(ima),
						'other' => q({0} ima),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(ima),
						'other' => q({0} ima),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(partes/millon),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(partes/millon),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100 km),
						'other' => q({0} L/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100 km),
						'other' => q({0} L/100 km),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(punto),
						'other' => q({0} punto),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(punto),
						'other' => q({0} punto),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fathom),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fathom),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlong),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(grano),
						'other' => q({0} grano),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(grano),
						'other' => q({0} grano),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(catorce libras),
						'other' => q({0} catorce libras),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(catorce libras),
						'other' => q({0} catorce libras),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(bushel),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bushel),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(cucharilla),
						'other' => q({0} cucharilla),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(cucharilla),
						'other' => q({0} cucharilla),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(Imp cucharilla),
						'other' => q({0} Imp cucharilla),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(Imp cucharilla),
						'other' => q({0} Imp cucharilla),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(trago fluido),
						'other' => q({0} trago fluido),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(trago fluido),
						'other' => q({0} trago fluido),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(gota),
						'other' => q({0} gota),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(gota),
						'other' => q({0} gota),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(medida),
						'other' => q({0} medida),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(medida),
						'other' => q({0} medida),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(pizca),
						'other' => q({0} pizca),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(pizca),
						'other' => q({0} pizca),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(Imp cuarta),
						'other' => q({0} Imp. cuarta),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(Imp cuarta),
						'other' => q({0} Imp. cuarta),
					},
				},
			} }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				end => q({0}, utaq {1}),
				2 => q({0} utaq {1}),
		} }
);

has 'minimum_grouping_digits' => (
	is			=>'ro',
	isa			=> Int,
	init_arg	=> undef,
	default		=> 1,
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(.),
			'exponential' => q(E),
			'group' => q(,),
			'infinity' => q(∞),
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(×),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'default' => {
				'1000' => {
					'other' => '0K',
				},
				'10000' => {
					'other' => '00K',
				},
				'100000' => {
					'other' => '000K',
				},
				'1000000' => {
					'other' => '0M',
				},
				'10000000' => {
					'other' => '00M',
				},
				'100000000' => {
					'other' => '000M',
				},
				'1000000000' => {
					'other' => '0G',
				},
				'10000000000' => {
					'other' => '00G',
				},
				'100000000000' => {
					'other' => '000G',
				},
				'1000000000000' => {
					'other' => '0T',
				},
				'10000000000000' => {
					'other' => '00T',
				},
				'100000000000000' => {
					'other' => '000T',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'other' => '0K',
				},
				'10000' => {
					'other' => '00K',
				},
				'100000' => {
					'other' => '000K',
				},
				'1000000' => {
					'other' => '0M',
				},
				'10000000' => {
					'other' => '00M',
				},
				'100000000' => {
					'other' => '000M',
				},
				'1000000000' => {
					'other' => '0G',
				},
				'10000000000' => {
					'other' => '00G',
				},
				'100000000000' => {
					'other' => '000G',
				},
				'1000000000000' => {
					'other' => '0T',
				},
				'10000000000000' => {
					'other' => '00T',
				},
				'100000000000000' => {
					'other' => '000T',
				},
			},
			'short' => {
				'1000' => {
					'other' => '0K',
				},
				'10000' => {
					'other' => '00K',
				},
				'100000' => {
					'other' => '000K',
				},
				'1000000' => {
					'other' => '0M',
				},
				'10000000' => {
					'other' => '00M',
				},
				'100000000' => {
					'other' => '000M',
				},
				'1000000000' => {
					'other' => '0G',
				},
				'10000000000' => {
					'other' => '00G',
				},
				'100000000000' => {
					'other' => '000G',
				},
				'1000000000000' => {
					'other' => '0T',
				},
				'10000000000000' => {
					'other' => '00T',
				},
				'100000000000000' => {
					'other' => '000T',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0 %',
				},
			},
		},
		scientificFormat => {
			'default' => {
				'standard' => {
					'default' => '#E0',
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
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
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
			symbol => 'AED',
			display_name => {
				'currency' => q(Dirham de Emiratos Árabes Unidos),
				'other' => q(UAE dirhams),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(Afgani Afgano),
				'other' => q(Afgani afgano),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(Lek albanés),
				'other' => q(Lek albanés),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(Dram Armenio),
				'other' => q(drams Armenios),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(Florín Antillano Neerlandés),
				'other' => q(Florín antillano neerlandés),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(Kwanza Angoleño),
				'other' => q(Kwanza angoleño),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(Peso Argentino),
				'other' => q(Peso argentino),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dólar Australiano),
				'other' => q(Dólar Australiano),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(Florín Arubeño),
				'other' => q(Florín arubeño),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(Manat Azerbaiyano),
				'other' => q(manats Azerbaiyanos),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(Marco Bosnioherzegovino),
				'other' => q(Marco bosnioherzegovino),
			},
		},
		'BBD' => {
			symbol => 'BBG',
			display_name => {
				'currency' => q(Dólar de Barbados),
				'other' => q(Dólar de Barbados),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(Taka Bangladesí),
				'other' => q(Taka bangladesí),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(Lev),
				'other' => q(Lev),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(Dinar Bareiní),
				'other' => q(Dinar bareiní),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(Franco Burundés),
				'other' => q(Franco burundés),
			},
		},
		'BMD' => {
			symbol => 'DBM',
			display_name => {
				'currency' => q(Dólar Bermudeño),
				'other' => q(Dólar bermudeño),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(Dólar de Brunéi),
				'other' => q(Dólar de Brunéi),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(Boliviano),
				'other' => q(Boliviano),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Real Brasileño),
				'other' => q(Real brasileño),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(Dólar Bahameño),
				'other' => q(Dólar bahameño),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(Ngultrum Butanés),
				'other' => q(Ngultrum butanés),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(Pula Botswano),
				'other' => q(Pula Botswano),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(Nuevo Rublo Bielorruso),
				'other' => q(Nuevo rublo bielorruso),
			},
		},
		'BZD' => {
			symbol => 'DBZ',
			display_name => {
				'currency' => q(Dólar Beliceño),
				'other' => q(Dólar beliceño),
			},
		},
		'CAD' => {
			symbol => '$CA',
			display_name => {
				'currency' => q(Dólar Canadiense),
				'other' => q(Dólar canadiense),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(Franco Congoleño),
				'other' => q(Franco congoleño),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(Franco Suizo),
				'other' => q(Franco suizo),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(Peso Chileno),
				'other' => q(Peso chileno),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(Yuan Chino \(offshore\)),
				'other' => q(Yuan chino \(offshore\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan Chino),
				'other' => q(Yuan chino),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(Peso Colombiano),
				'other' => q(Peso colombiano),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(Colón Costarricense),
				'other' => q(Colón costarricense),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(Peso Cubano Convertible),
				'other' => q(Peso cubano convertible),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(Peso Cubano),
				'other' => q(Peso cubano),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(Escudo Caboverdiano),
				'other' => q(Escudo caboverdiano),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(Corona Checa),
				'other' => q(Corona checa),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(Franco Yibutiano),
				'other' => q(Franco yibutiano),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(Corona Danesa),
				'other' => q(Corona danesa),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(Peso Dominicano),
				'other' => q(Peso dominicano),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(Dinar Argelino),
				'other' => q(Dinar argelino),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(Libra Egipcia),
				'other' => q(Libra egipcia),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(Nakfa Eritreano),
				'other' => q(Nakfa Eritreano),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(Birr Etíope),
				'other' => q(Birr etíope),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
				'other' => q(euro),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(Dólar Fiyiano),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(Libra Malvinense),
				'other' => q(Libra malvinense),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Libra Esterlina),
				'other' => q(Libra esterlina),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(Lari Georgiano),
				'other' => q(Lari georgiano),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(Cedi Ganés),
				'other' => q(Cedi ganés),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Libra Gibraltareña),
				'other' => q(Libra gibraltareña),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(Dalasi),
				'other' => q(Dalasi),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(Franco Guineano),
				'other' => q(Franco guineano),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(Quetzal Guatemalteco),
				'other' => q(Quetzal guatemalteco),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(Dólar Guyanés),
				'other' => q(Dólar guyanés),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Dólar de Hong Kong),
				'other' => q(Dólar de Hong Kong),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(Lempira Hondureño),
				'other' => q(Lempira hondureño),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(Kuna Croata),
				'other' => q(Kuna croata),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(Gourde Haitiano),
				'other' => q(Gourde haitiano),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(Florín Húngaro),
				'other' => q(Florín húngaro),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(Rupia Indonesia),
				'other' => q(Rupia indonesia),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Nuevo Séquel),
				'other' => q(Nuevo séquel),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupia India),
				'other' => q(Rupia india),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(Dinar Iraquí),
				'other' => q(Dinar iraquí),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(Rial Iraní),
				'other' => q(Rial iraní),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(Corona Islandesa),
				'other' => q(Corona islandesa),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(Dólar Jamaiquino),
				'other' => q(Dólar jamaiquino),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(Dinar Jordano),
				'other' => q(Dinar jordano),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yen Japonés),
				'other' => q(Yen japonés),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(Chelín Keniano),
				'other' => q(Chelín keniano),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(Som Kirguís),
				'other' => q(Som kirguís),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Riel Camboyano),
				'other' => q(Riel camboyano),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Franco Comorense),
				'other' => q(Franco comorense),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(Won Norcoreano),
				'other' => q(Won norcoreano),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Won Surcoreano),
				'other' => q(Won surcoreano),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(Dinar Kuwaití),
				'other' => q(Dinar kuwaití),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(Dólar de las Islas Caimán),
				'other' => q(Dólar de las islas caimán),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(Tenge Kazajo),
				'other' => q(Tenge kazajo),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(Kip Laosiano),
				'other' => q(Kip laosiano),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(Libra Libanesa),
				'other' => q(Libra libanesa),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Rupia de Sri Lanka),
				'other' => q(Rupia de Sri Lanka),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(Dólar Liberiano),
				'other' => q(Dólar liberiano),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesoto Loti Qullqi),
				'other' => q(Lesoto lotis qullqi),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(Dinar Libio),
				'other' => q(Dinar libio),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(Dírham Marroquí),
				'other' => q(Dírham marroquí),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(Leu Moldavo),
				'other' => q(Leu moldavo),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(Ariary Malgache),
				'other' => q(Ariary malgache),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(Dinar Macedonio),
				'other' => q(Dinar macedonio),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(Kyat Birmano),
				'other' => q(Kyat birmano),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Tugrik Mongol),
				'other' => q(Tugrik mongol),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(Pataca Macaense),
				'other' => q(Pataca macaense),
			},
		},
		'MRU' => {
			symbol => 'MRU',
			display_name => {
				'currency' => q(Uguiya Mauritano),
				'other' => q(Uguiya Mauritano),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(Rupia de Mauricio),
				'other' => q(Rupia de mauricio),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(Rupia de Maldivas),
				'other' => q(Rupia de Maldivas),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(Kwacha Malauí),
				'other' => q(Kwacha malauí),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Peso Mexicano),
				'other' => q(Peso mexicano),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(Ringgit Malayo),
				'other' => q(Ringgit malayo),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(Metical Mozambiqueño),
				'other' => q(Metical mozambiqueño),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(Dólar Namibio),
				'other' => q(Dólar namibio),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(Naira Nigeriano),
				'other' => q(Naira nigeriano),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(Córdova Nicaragüense),
				'other' => q(Córdova nicaragüense),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(Corona Noruega),
				'other' => q(Corona noruega),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(Rupia Nepalí),
				'other' => q(Rupia Nepalí),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Dólar Neozelandés),
				'other' => q(Dólar neozelandés),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(Rial Omaní),
				'other' => q(Rial omaní),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(Balboa Panameño),
				'other' => q(Balboa panameño),
			},
		},
		'PEN' => {
			symbol => 'S/',
			display_name => {
				'currency' => q(Sol Peruano),
				'other' => q(Sol peruano),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(Kina Papuano),
				'other' => q(Kina papuano),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Peso Filipino),
				'other' => q(Peso filipino),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(Rupia Pakistaní),
				'other' => q(Rupia pakistaní),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Zloty),
				'other' => q(Zloty),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(Guaraní Paraguayo),
				'other' => q(Guaraní paraguayo),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(Riyal Catarí),
				'other' => q(Riyal catarí),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(Leu Rumano),
				'other' => q(Leu rumano),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(Dinar Serbio),
				'other' => q(Dinar serbio),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Rublo Ruso),
				'other' => q(Rublo ruso),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(Franco Ruandés),
				'other' => q(Franco ruandés),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Riyal Saudí),
				'other' => q(Riyal saudí),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(Dólar de las Islas Salomón),
				'other' => q(Dólar de las Islas Salomón),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(Rupia de Seychelles),
				'other' => q(Rupia de seychelles),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(Libra Sudanesa),
				'other' => q(Libra sudanesa),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(Corona Sueca),
				'other' => q(Corona sueca),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(Dólar de Singapur),
				'other' => q(Dólar de Singapur),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(Libra de Santa Helena),
				'other' => q(Libra de santa helena),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(Leone de Sierra Leona),
				'other' => q(Leone de sierra leona),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(Chelín Somalí),
				'other' => q(Chelín somalí),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(Dólar Surinamés),
				'other' => q(Dólar Surinamés),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(Libra Sursudanesa),
				'other' => q(Libra sursudanesa),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(Dobra Santotomense),
				'other' => q(Dobra santotomense),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(Libra Siria),
				'other' => q(Libra siria),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(Lilangeni Swazi),
				'other' => q(Lilangeni swazi),
			},
		},
		'THB' => {
			symbol => 'THB',
			display_name => {
				'currency' => q(Baht Tailandés),
				'other' => q(Baht tailandés),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(Somoni Tayiko),
				'other' => q(Somoni tayiko),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(Manat Turcomano),
				'other' => q(Manat turcomano),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(Dinar Tunecino),
				'other' => q(Dinar tunecino),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(Paʻanga Tongano),
				'other' => q(Paʻanga tongano),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(Lira Turca),
				'other' => q(Lira turca),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(Dólar de Trinidad y Tobago),
				'other' => q(Dólar de trinidad y tobago),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Nuevo Dólar Taiwanés),
				'other' => q(Nuevo dólar taiwanés),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(Chelín Tanzano),
				'other' => q(Chelín tanzano),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(Grivna),
				'other' => q(Grivna),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(Chelín Ugandés),
				'other' => q(Chelín ugandés),
			},
		},
		'USD' => {
			symbol => '$US',
			display_name => {
				'currency' => q(Dólar Americano),
				'other' => q(Dólar americano),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(Peso Uruguayo),
				'other' => q(Peso uruguayo),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(Som Ubzeko),
				'other' => q(Som Ubzeko),
			},
		},
		'VES' => {
			symbol => 'VES',
			display_name => {
				'currency' => q(Bolívar Venezolano),
				'other' => q(Bolívar venezolano),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Dong Vietnamita),
				'other' => q(Dong vietnamita),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(Vatu Vanuatu),
				'other' => q(Vatu vanuatu),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(Tala Samoano),
				'other' => q(Tala samoano),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Franco CFA de África Central),
				'other' => q(Franco CFA de áfrica central),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Dólar del Caribe Oriental),
				'other' => q(Dólar del caribe oriental),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Franco CFA de África Occidental),
				'other' => q(Franco CFA de áfrica occidental),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(Franco CFP),
				'other' => q(Franco CFP),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Mana riqsisqa Qullqi),
				'other' => q(Mana riqsisqa qullqi),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(Rial Yemení),
				'other' => q(Rial yemení),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(Rand Sudafricano),
				'other' => q(Rand sudafricano),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(Kwacha Zambiano),
				'other' => q(Kwacha zambiano),
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
							'Ene',
							'Feb',
							'Mar',
							'Abr',
							'May',
							'Jun',
							'Jul',
							'Ago',
							'Set',
							'Oct',
							'Nov',
							'Dic'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Enero',
							'Febrero',
							'Marzo',
							'Abril',
							'Mayo',
							'Junio',
							'Julio',
							'Agosto',
							'Setiembre',
							'Octubre',
							'Noviembre',
							'Diciembre'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Ene',
							'Feb',
							'Mar',
							'Abr',
							'May',
							'Jun',
							'Jul',
							'Ago',
							'Set',
							'Oct',
							'Nov',
							'Dic'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Enero',
							'Febrero',
							'Marzo',
							'Abril',
							'Mayo',
							'Junio',
							'Julio',
							'Agosto',
							'Setiembre',
							'Octubre',
							'Noviembre',
							'Diciembre'
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
						mon => 'Lun',
						tue => 'Mar',
						wed => 'Mié',
						thu => 'Jue',
						fri => 'Vie',
						sat => 'Sab',
						sun => 'Dom'
					},
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'X',
						thu => 'J',
						fri => 'V',
						sat => 'S',
						sun => 'D'
					},
					short => {
						mon => 'Lun',
						tue => 'Mar',
						wed => 'Mié',
						thu => 'Jue',
						fri => 'Vie',
						sat => 'Sab',
						sun => 'Dom'
					},
					wide => {
						mon => 'Lunes',
						tue => 'Martes',
						wed => 'Miércoles',
						thu => 'Jueves',
						fri => 'Viernes',
						sat => 'Sábado',
						sun => 'Domingo'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Lun',
						tue => 'Mar',
						wed => 'Mié',
						thu => 'Jue',
						fri => 'Vie',
						sat => 'Sab',
						sun => 'Dom'
					},
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'X',
						thu => 'J',
						fri => 'V',
						sat => 'S',
						sun => 'D'
					},
					short => {
						mon => 'Lun',
						tue => 'Mar',
						wed => 'Mié',
						thu => 'Jue',
						fri => 'Vie',
						sat => 'Sab',
						sun => 'Dom'
					},
					wide => {
						mon => 'Lunes',
						tue => 'Martes',
						wed => 'Miércoles',
						thu => 'Jueves',
						fri => 'Viernes',
						sat => 'Sábado',
						sun => 'Domingo'
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
					abbreviated => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
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
					'am' => q{a.m.},
					'pm' => q{p.m.},
				},
				'narrow' => {
					'am' => q{a.m.},
					'pm' => q{p.m.},
				},
				'wide' => {
					'am' => q{a.m.},
					'pm' => q{p.m.},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{a.m.},
					'pm' => q{p.m.},
				},
				'narrow' => {
					'am' => q{a.m.},
					'pm' => q{p.m.},
				},
				'wide' => {
					'am' => q{a.m.},
					'pm' => q{p.m.},
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
				'0' => 'a.d.',
				'1' => 'd.C.'
			},
			narrow => {
				'1' => 'dC'
			},
			wide => {
				'0' => 'ñawpa cristu',
				'1' => 'chanta cristu'
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
			'full' => q{EEEE, d MMMM y, G},
			'long' => q{d MMMM y, G},
			'medium' => q{d MMM y, G},
			'short' => q{d/M/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM, y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd/MM/y},
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
			'full' => q{HH:mm:ss zzzz},
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
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1} {0}},
			'long' => q{{0} {1}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E, d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{M/d/y GGGGG},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, dd-MM},
			MMM => q{LLL},
			MMMEd => q{E, d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd-MM},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{MM-y GGGGG},
			yyyyMEd => q{E, dd-MM-y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{dd-MM-y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d, E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{G y},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM, y G},
			GyMMMd => q{d MMM, y G},
			GyMd => q{d/M/y GGGGG},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{MM-dd, E},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMW => q{W 'semana' MMMM 'killapa'},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{MM-dd},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{y-MM},
			yMEd => q{E, dd-MM-y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM, y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd-MM-y},
			yQQQ => q{y QQQ},
			yQQQQ => q{y QQQQ},
			yw => q{w 'semana' Y 'watapa'},
		},
	} },
);

has 'datetime_formats_append_item' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'Timezone' => '{0} {1}',
		},
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{MM-y GGGGG – MM-y GGGGG},
				M => q{MM-y GGGGG – MM-y GGGGG},
				y => q{MM-y – MM-y GGGGG},
			},
			GyMEd => {
				G => q{E, d-MM-y GGGG – E, d-MM-y GGGGG},
				M => q{E, d-MM-y – E, d-MM-y GGGGG},
				d => q{E, d-MM-y – E, d-MM-y GGGGG},
				y => q{E, d-MM-y – E, d-MM-y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM y G – E, d MMM y G},
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d-MM-y GGGG – d-MM-y GGGGG},
				M => q{d-MM-y – d-MM-y GGGGG},
				d => q{d-MM-y – d–MM-y GGGGG},
				y => q{d-MM-y – d-MM-y GGGGG},
			},
			M => {
				M => q{MM–MM},
			},
			MEd => {
				M => q{E, dd-MM – E, dd-MM},
				d => q{E, dd-MM – E, dd-MM},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd-MM – dd-MM},
				d => q{dd-MM – dd-MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{MM-y – MM-y GGGGG},
				y => q{MM-y – MM-y GGGGG},
			},
			yMEd => {
				M => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				d => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				y => q{E, dd-MM-y – E, dd-MM-y GGGGG},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM y – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{dd-MM-y – dd-MM-y GGGGG},
				d => q{dd-MM-y – dd-MM-y GGGGG},
				y => q{dd-MM-y – dd-MM-y GGGGG},
			},
		},
		'gregorian' => {
			Gy => {
				y => q{y–y G},
			},
			GyM => {
				G => q{MM-y GGGGG – MM-y GGGGG},
			},
			GyMMM => {
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM y G – E, d MMM y G},
				M => q{E, d MMM d – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			GyMMMd => {
				G => q{d, MMM y G – d, MMM y G},
				M => q{d, MMM – d, MMM y G},
				d => q{d – d, MMM y G},
				y => q{d, MMM y – d, MMM y G},
			},
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{MM–MM},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM, y},
				d => q{E, d MMM – E, d MMM, y},
				y => q{E, d MMM, y – E, d MMM, y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM, y},
				d => q{d – d MMM, y},
				y => q{d MMM, y – d MMM, y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		hourFormat => q(+HH:mm;-HH:mm),
		gmtFormat => q(GMT{0}),
		gmtZeroFormat => q(GMT),
		regionFormat => q({0}),
		regionFormat => q({0} (+1)),
		regionFormat => q({0} (+0)),
		fallbackFormat => q({1} ({0})),
		'Afghanistan' => {
			long => {
				'standard' => q#Hora de Afganistán#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abiyán#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Acra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Adís Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Argel#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmara#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Bamako#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Bangui#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Banjul#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bissau#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Blantyre#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Brazzaville#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Bujumbura#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#El Cairo#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Casablanca#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Ceuta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Conakry#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Dakar#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar es Salaam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Yibuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Duala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Aaiun#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Freetown#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Gaborone#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Harare#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Johannesburgo#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Juba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Jartum#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#Kigali#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kinshasa#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Lagos#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Libreville#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lome#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Luanda#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbashi#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#Lusaka#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#Malabo#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#Maputo#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#Maseru#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#Mbabane#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadiscio#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrovia#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nairobi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Ndjamena#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niamey#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nouakchott#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Ouagadougou#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto-Novo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Sao Tome#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripoli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunez#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhoek#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Hora de Africa Central#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Hora de Africa Oriental#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Hora de Sudafrica#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Hora Estandar de Verano de Africa Occidental#,
				'generic' => q#Hora de Africa Occidental#,
				'standard' => q#Hora Estandar de Africa Occidental#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Hora de Verano de Alaska#,
				'generic' => q#Hora de Alaska#,
				'standard' => q#Hora Estandar de Alaska#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Hora de Verano de Amazonas#,
				'generic' => q#Hora de Amazonas#,
				'standard' => q#Hora Estandar de Amazonas#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#Adak#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Anchorage#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Anguila#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antigua#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaina#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La Rioja#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Rio Gallegos#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#Salta#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#San Juan#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#San Luis#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucuman#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ushuaia#,
		},
		'America/Aruba' => {
			exemplarCity => q#Aruba#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asuncion#,
		},
		'America/Bahia' => {
			exemplarCity => q#Bahia#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbados#,
		},
		'America/Belem' => {
			exemplarCity => q#Belem#,
		},
		'America/Belize' => {
			exemplarCity => q#Belice#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blanc-Sablon#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Boa Vista#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogota#,
		},
		'America/Boise' => {
			exemplarCity => q#Boise#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Buenos Aires#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Cambridge Bay#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Campo Grande#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Caracas' => {
			exemplarCity => q#Caracas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Catamarca#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Cayenne#,
		},
		'America/Cayman' => {
			exemplarCity => q#Cayman#,
		},
		'America/Chicago' => {
			exemplarCity => q#Chicago#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Chihuahua#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Atikokan#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Cordoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Costa Rica#,
		},
		'America/Creston' => {
			exemplarCity => q#Creston#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiaba#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curazao#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Danmarkshavn#,
		},
		'America/Dawson' => {
			exemplarCity => q#Dawson#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Dawson Creek#,
		},
		'America/Denver' => {
			exemplarCity => q#Denver#,
		},
		'America/Detroit' => {
			exemplarCity => q#Detroit#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominica#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Edmonton#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepe#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#El Salvador#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fort Nelson#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Fortaleza#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Glace Bay#,
		},
		'America/Godthab' => {
			exemplarCity => q#Nuuk#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Goose Bay#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Grand Turk#,
		},
		'America/Grenada' => {
			exemplarCity => q#Granada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadalupe#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guatemala#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Guayaquil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Guyana#,
		},
		'America/Halifax' => {
			exemplarCity => q#Halifax#,
		},
		'America/Havana' => {
			exemplarCity => q#La Habana#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Hermosillo#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Knox, Indiana#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marengo, Indiana#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Petersburg, Indiana#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tell City, Indiana#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vevay, Indiana#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vincennes, Indiana#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Winamac, Indiana#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Indianapolis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inuvik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Iqaluit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaica#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Jujuy#,
		},
		'America/Juneau' => {
			exemplarCity => q#Juneau#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Monticello, Kentucky#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Kralendijk#,
		},
		'America/La_Paz' => {
			exemplarCity => q#La Paz#,
		},
		'America/Lima' => {
			exemplarCity => q#Lima#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Los Angeles#,
		},
		'America/Louisville' => {
			exemplarCity => q#Louisville#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Lower Prince’s Quarter#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceio#,
		},
		'America/Managua' => {
			exemplarCity => q#Managua#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manaus#,
		},
		'America/Marigot' => {
			exemplarCity => q#Marigot#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinica#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Matamoros#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlan#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mendoza#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menominee#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metlakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Ciudad de Mexico#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Miquelon#,
		},
		'America/Moncton' => {
			exemplarCity => q#Moncton#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Monterrey#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Montevideo#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Montserrat#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nassau#,
		},
		'America/New_York' => {
			exemplarCity => q#New York#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Nipigon#,
		},
		'America/Nome' => {
			exemplarCity => q#Nome#,
		},
		'America/Noronha' => {
			exemplarCity => q#Noronha#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, North Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, North Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, North Dakota#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ojinaga#,
		},
		'America/Panama' => {
			exemplarCity => q#Panama#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Pangnirtung#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#Paramaribo#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Phoenix#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Puerto Príncipe#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Puerto España#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Porto Velho#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Puerto Rico#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#Punta Arenas#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Rainy River#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Rankin Inlet#,
		},
		'America/Recife' => {
			exemplarCity => q#Recife#,
		},
		'America/Regina' => {
			exemplarCity => q#Regina#,
		},
		'America/Resolute' => {
			exemplarCity => q#Resolute#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Rio Branco#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarem#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiago#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santo Domingo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Sao Paulo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ittoqqortoormiit#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#San Bartolomé#,
		},
		'America/St_Johns' => {
			exemplarCity => q#San Juan de Terranova#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#San Cristobal#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Santa Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Santo Tomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#San Vicente#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Swift Current#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tegucigalpa#,
		},
		'America/Thule' => {
			exemplarCity => q#Thule#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Thunder Bay#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Tijuana#,
		},
		'America/Toronto' => {
			exemplarCity => q#Toronto#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tortola#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Vancouver#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Whitehorse#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Winnipeg#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Yakutat#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Yellowknife#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Hora Central de Verano#,
				'generic' => q#Hora Central#,
				'standard' => q#Estandard Hora Central#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Hora de Verano del Este#,
				'generic' => q#Hora del Este#,
				'standard' => q#Hora Estandar del Este#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Hora de Verano de la Montaña#,
				'generic' => q#Hora de la Montaña#,
				'standard' => q#Hora Estandar de la Montaña#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Hora de Verano del Pacífico#,
				'generic' => q#Hora del Pacífico#,
				'standard' => q#Hora Estandar del Pacífico#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Casey#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Davis#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont d’Urville#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Macquarie#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Mawson#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#McMurdo#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Palmer#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Rothera#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Syowa#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Troll#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Vostok#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Hora de Verano de Apia#,
				'generic' => q#Hora de Apia#,
				'standard' => q#Hora Estandar de Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Hora de Verano de Arabia#,
				'generic' => q#Hora de Arabia#,
				'standard' => q#Hora Estandar de Arabia#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Hora de Verano de Argentina#,
				'generic' => q#Hora de Argentina#,
				'standard' => q#Hora Estandar de Argentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Hora de Verano del Oeste de Argentina#,
				'generic' => q#Hora del Oeste de Argentina#,
				'standard' => q#Hora Estandar del Oeste de Argentina#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Hora de Verano de Armenia#,
				'generic' => q#Hora de Armenia#,
				'standard' => q#Hora Estandar de Armenia#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Aden#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almaty#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Amán#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadyr#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Asjabad#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atyrau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Baréin#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Baku#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Bangkok#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnaul#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beirut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bishkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunei#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kolkata#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Chita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Choibalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Colombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damasco#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dhaka#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Dili#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubai#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dusambé#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Famagusta#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gaza#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebron#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hong Kong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Hovd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Yakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jerusalem#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamchatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karachi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandú#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Khandyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnoyarsk#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala Lumpur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kuching#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuwait#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macao#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Magadan#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Macasar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manila#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Mascate#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nicosia#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Novokuznetsk#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Novosibirsk#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Omsk#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Oral#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Phnom Penh#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Pontianak#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pionyang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Catar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanái#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kyzylorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangún#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sakhalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarcanda#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seúl#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Shangái#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolymsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taipei#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taskent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tiflis#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teherán#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Thimphu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan Bator#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumqi#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ust-Nera#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vientiane#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Vladivostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Yakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Ekaterinburgo#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Ereván#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Hora De Verano del Atlántico#,
				'generic' => q#Hora del Atlántico#,
				'standard' => q#Hora Estandar del Atlántico#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azores#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Canarias#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Cabo Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Faroe#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Georgia del Sur#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Santa Elena#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stanley#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelaida#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Brisbane#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Broken Hill#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Darwin#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Eucla#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Hobart#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#Lindeman#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Lord Howe#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Melbourne#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Perth#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sidney#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Hora de Verano de Australia Central#,
				'generic' => q#Hora de Australia Central#,
				'standard' => q#Hora Estandar de Australia Central#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Hora de Verano de Australia Central Occidental#,
				'generic' => q#Hora de Australia Central Occidental#,
				'standard' => q#Hora Estandar de Australia Central Occidental#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Hora de Verano de Australia Oriental#,
				'generic' => q#Hora de Australia Oriental#,
				'standard' => q#Hora Estandar de Australia Oriental#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Hora de Verano de Australia Occidental#,
				'generic' => q#Hora de Australia Occidental#,
				'standard' => q#Hora Estandar de Australia Occidental#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Hora de Verano de Azerbaiyán#,
				'generic' => q#Hora de Azerbaiyán#,
				'standard' => q#Hora Estandar de Azerbaiyán#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Hora de Verano de las Azores#,
				'generic' => q#Hora de las Azores#,
				'standard' => q#Hora Estandar de las Azores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Hora de Verano de Bangladesh#,
				'generic' => q#Hora de Bangladesh#,
				'standard' => q#Hora Estandar de Bangladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Hora de Bután#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Bolivia Time#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Hora de Verano de Brasilia#,
				'generic' => q#Hora de Brasilia#,
				'standard' => q#Hora Estandar de Brasilia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Hora de Brunei Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Hora de Verano de Cabo Verde#,
				'generic' => q#Hora de Cabo Verde#,
				'standard' => q#Hora Estandar de Cabo Verde#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Hora Estandar de Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Hora de Verano de Chatham#,
				'generic' => q#Hora de Chatham#,
				'standard' => q#Hora Estandar de Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Hora de Verano de Chile#,
				'generic' => q#Hora de Chile#,
				'standard' => q#Hora Estandar de Chile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Hora de Verano de China#,
				'generic' => q#Hora de China#,
				'standard' => q#Hora Estandar de China#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Hora de Verano de Choybalsan#,
				'generic' => q#Hora de Choybalsan#,
				'standard' => q#Hora Estandar de Choybalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Hora de Isla Christmas#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Hora de Islas Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Hora de Verano de Colombia#,
				'generic' => q#Hora de Colombia#,
				'standard' => q#Hora Estandar de Colombia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Hora de Verano de Isla Cocos#,
				'generic' => q#Hora de Islas Cook#,
				'standard' => q#Hora Estandar de Isla Cocos#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Hora de Verano de Cuba#,
				'generic' => q#Hora de Cuba#,
				'standard' => q#Hora Estandar de Cuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Hora de Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Hora de Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Hora de Timor Oriental#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Hora de Verano de Isla de Pascua#,
				'generic' => q#Hora de Isla de Pascua#,
				'standard' => q#Hora Estandar de Isla de Pascua#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Hora de Ecuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Tiqsimuyuntin Tupachisqa Hora#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Mana risisqa llaqta#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorra#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrakhan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athens#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrade#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruselas#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bucarest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Busingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Chisinau#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Copenhague#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q#Hora Estandar de Irlanda#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernsey#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Isla de Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Estambul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jersey#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaliningrado#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirov#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisboa#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Liubliana#,
		},
		'Europe/London' => {
			exemplarCity => q#Londres#,
			long => {
				'daylight' => q#Hora de Verano Británico#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburgo#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madrid#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Malta#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Mariehamn#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Minsk#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monaco#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moscú#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Paris#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgorica#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praga#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Samara#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Marino#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarajevo#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratov#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Simferopol#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skopje#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofia#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Estocolmo#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallinn#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ulyanovsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uzhgorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#El Vaticano#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Viena#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgogrado#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsovia#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporozhye#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zurich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Hora de Verano de Europa Central#,
				'generic' => q#Hora de Europa Central#,
				'standard' => q#Hora Estandar de Europa Central#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Hora de Verano de Europa Oriental#,
				'generic' => q#Hora de Europa Oriental#,
				'standard' => q#Hora Estandar de Europa Oriental#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Hora de Verano más Oriental de Europa#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Hora de Verano de Europa Occidental#,
				'generic' => q#Hora de Europa Occidental#,
				'standard' => q#Hora Estandar de Europa Occidental#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Hora de Verano de Islas Malvinas#,
				'generic' => q#Hora de Islas Malvinas#,
				'standard' => q#Hora Estandar de Islas Malvinas#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Hora de Verano de Fiji#,
				'generic' => q#Hora de Fiji#,
				'standard' => q#Hora Estandar de Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Hora de Guayana Francesa#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Hora Francés meridional y antártico#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Hora del Meridiano de Greenwich#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Hora de Islas Galápagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Hora de Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Hora de Verano de Georgia#,
				'generic' => q#Hora de Georgia#,
				'standard' => q#Hora Estandar de Georgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Hora de Islas Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Hora de Verano de Groenlandia#,
				'generic' => q#Hora de Groenlandia#,
				'standard' => q#Hora Estandar de Groenlandia#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Hora de Verano de Groenlandia Occidental#,
				'generic' => q#Hora de Groenlandia Occidental#,
				'standard' => q#Hora Estandar de Groenlandia Occidental#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Hora Estandar del Golfo#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Hora de Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hora de Verano de Hawai-Aleutiano#,
				'generic' => q#Hora de Hawai-Aleutiano#,
				'standard' => q#Hora Estandar de Hawai-Aleutiano#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hora de Verano de Hong Kong#,
				'generic' => q#Hora de Hong Kong#,
				'standard' => q#Hora Estandar de Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hora de Verano de Hovd#,
				'generic' => q#Hora de Hovd#,
				'standard' => q#Hora Estandar de Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Hora Estandar de India#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Christmas#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Cocos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Comoro#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahe#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivas#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mauritius#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Hora del Oceano Índico#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Hora de Indochina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Hora de Indonesia Central#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Hora de Indonesia Oriental#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Hora de Indonesia Occidental#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Hora de Verano de Irán#,
				'generic' => q#Hora de Irán#,
				'standard' => q#Hora Estandar de Irán#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Hora de Verano de Irkutsk#,
				'generic' => q#Hora de Irkutsk#,
				'standard' => q#Hora Estandar de Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Hora de Verano de Israel#,
				'generic' => q#Hora de Israel#,
				'standard' => q#Hora Estandar de Israel#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Hora de Verano de Japón#,
				'generic' => q#Hora de Japón#,
				'standard' => q#Hora Estandar de Japón#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Hora de Kazajistán Oriental#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Hora de Kazajistán del Oeste#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Hora de Verano de Corea#,
				'generic' => q#Hora de Corea#,
				'standard' => q#Hora Estandar de Corea#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Hora de Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Hora de Verano de Krasnoyarsk#,
				'generic' => q#Hora de Krasnoyarsk#,
				'standard' => q#Hora Estandar de Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Hora de Kirguistán#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Hora de Espóradas Ecuatoriales#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Hora de Verano de Lord Howe#,
				'generic' => q#Hora de Lord Howe#,
				'standard' => q#Hora Estandar de Lord Howe#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Hora de Isla Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Hora de Verano de Magadan#,
				'generic' => q#Hora de Magadan#,
				'standard' => q#Hora Estandar de Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Hora de Malasia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Hora de Maldivas#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Hora de Marquesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Hora de Islas Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Hora de Verano de Mauricio#,
				'generic' => q#Hora de Mauricio#,
				'standard' => q#Hora Estandar de Mauricio#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Hora de Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Hora de Verano del Noroeste de México#,
				'generic' => q#Hora Estandar de Verano de México#,
				'standard' => q#Hora Estandar del Noroeste de México#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Hora de Verano del Pacífico Mexicano#,
				'generic' => q#Hora del Pacífico Mexicano#,
				'standard' => q#Hora Estandar del Pacífico Mexicano#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Hora de Verano de Ulán Bator#,
				'generic' => q#Hora de Ulán Bator#,
				'standard' => q#Hora Estandar de Ulán Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Hora de Verano de Moscú#,
				'generic' => q#Hora de Moscú#,
				'standard' => q#Hora Estandar de Moscú#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Hora de Myanmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Hora de Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Hora de Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Hora de Verano de Nueva Caledonia#,
				'generic' => q#Hora de Nueva Caledonia#,
				'standard' => q#Hora Estandar de Nueva Caledonia#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Hora de Verano de Nueva Zelanda#,
				'generic' => q#Hora de Nueva Zelanda#,
				'standard' => q#Hora Estandar de Nueva Zelanda#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Hora de Verano de Terranova#,
				'generic' => q#Hora de Terranova#,
				'standard' => q#Hora Estandar de Terranova#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Hora de Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Hora de Verano de la Isla Norfolk#,
				'generic' => q#Hora de la Isla Norfolk#,
				'standard' => q#Hora Estandar de la Isla Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Hora de Verano de Fernando de Noronha#,
				'generic' => q#Hora de Fernando de Noronha#,
				'standard' => q#Hora Estandar de Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Hora de Verano de Novosibirsk#,
				'generic' => q#Hora de Novosibirsk#,
				'standard' => q#Hora Estandar de Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Hora de Verano de Omsk#,
				'generic' => q#Hora de Omsk#,
				'standard' => q#Hora Estandar de Omsk#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Apia#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Auckland#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Bougainville#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Chatham#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Easter#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Efate#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Fakaofo#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fiji#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Funafuti#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galapagos#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambier#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Guadalcanal#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Guam#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Johnston#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Kiritimati#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kosrae#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kwajalein#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Majuro#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Marquesas#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midway#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Nauru#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#Niue#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Norfolk#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Noumea#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pago Pago#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Palau#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitcairn#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Pohnpei#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Port Moresby#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Rarotonga#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Saipan#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Tahiti#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Tarawa#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Tongatapu#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Chuuk#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Wake#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Wallis#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Hora de Verano de Pakistán#,
				'generic' => q#Hora de Pakistán#,
				'standard' => q#Hora Estandar de Pakistán#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Hora de Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Hora de Papua Nueva Guinea#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Hora de Verano de Paraguay#,
				'generic' => q#Hora de Paraguay#,
				'standard' => q#Hora Estandar de Paraguay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Hora de Verano de Perú#,
				'generic' => q#Hora de Perú#,
				'standard' => q#Hora Estandar de Perú#,
			},
			short => {
				'daylight' => q#PEST#,
				'generic' => q#PET#,
				'standard' => q#PET#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Hora de Verano de Filipinas#,
				'generic' => q#Hora de Filipinas#,
				'standard' => q#Hora Estandar de Filipinas#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Hora de Islas Phoenix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Hora de Verano de San Pedro y Miquelón#,
				'generic' => q#Hora de San Pedro y Miquelón#,
				'standard' => q#Hora Estandar de San Pedro y Miquelón#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Hora de Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Hora de Pohnpei#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Hora de Pionyang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Hora de Réunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Hora de Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Hora de Verano de Sakhalin#,
				'generic' => q#Hora de Sakhalin#,
				'standard' => q#Hora Estandar de Sakhalin#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Hora de Verano de Samoa#,
				'generic' => q#Hora de Samoa#,
				'standard' => q#Hora Estandar de Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Hora de Seychelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Hora Estandar de Singapur#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Hora de Islas Salomón#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Hora de Georgia del Sur#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Hora de Surinam#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Hora de Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Hora de Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Hora de Verano de Taipéi#,
				'generic' => q#Hora de Taipéi#,
				'standard' => q#Hora Estandar de Taipéi#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Hora de Tayikistán#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Hora de Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Hora de Verano de Tonga#,
				'generic' => q#Hora de Tonga#,
				'standard' => q#Hora Estandar de Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Hora de Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Hora de Verano de Turkmenistán#,
				'generic' => q#Hora de Turkmenistán#,
				'standard' => q#Hora Estandar de Turkmenistán#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Hora de Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Hora de Verano de Uruguay#,
				'generic' => q#Hora de Uruguay#,
				'standard' => q#Hora Estandar de Uruguay#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Hora de Verano de Uzbekistán#,
				'generic' => q#Hora de Uzbekistán#,
				'standard' => q#Hora Estandar de Uzbekistán#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Hora de Verano de Vanuatu#,
				'generic' => q#Hora de Vanuatu#,
				'standard' => q#Hora Estandar de Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Hora de Venezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Hora de Verano de Vladivostok#,
				'generic' => q#Hora de Vladivostok#,
				'standard' => q#Hora Estandar de Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Hora de Verano de Volgogrado#,
				'generic' => q#Hora de Volgogrado#,
				'standard' => q#Hora Estandar de Volgogrado#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Hora de Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Hora de Isla Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Hora de Wallis y Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Hora de Verano de Yakutsk#,
				'generic' => q#Hora de Yakutsk#,
				'standard' => q#Hora Estandar de Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Hora de Verano de Ekaterinburgo#,
				'generic' => q#Hora de Ekaterinburgo#,
				'standard' => q#Hora Estandar de Ekaterinburgo#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Yukon Ura#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
